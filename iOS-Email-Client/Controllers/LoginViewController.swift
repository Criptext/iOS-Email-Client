//
//  TourAppViewController.swift
//  Criptext
//
//  Created by Criptext Mac on 8/18/15.
//  Copyright (c) 2015 Criptext INC. All rights reserved.
//

import Foundation
import FLAnimatedImage
import GoogleAPIClientForREST
import Material

class LoginViewController: UIViewController{
    
    @IBOutlet weak var guideAppScrollView: UIScrollView!
    @IBOutlet weak var guideAppPageControl: UIPageControl!
    @IBOutlet weak var startButton: UIButton!
    
    var pageControlUsed: Bool = true
    var detailGuideArray = [DetailGuideView]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.guideAppScrollView.delegate = self
        
        UserDefaults.standard.set(true, forKey: "showEncryptionAlert")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        self.detailGuideArray = [DetailGuideView]()
        
        let detailGuideView1 = DetailGuideView.instanceFromNib()
        detailGuideView1.frame = self.guideAppScrollView.frame
        
        let detailGuideView2 = DetailGuideView.instanceFromNib()
        detailGuideView2.frame = self.guideAppScrollView.frame
        
        let language = Bundle.main.preferredLocalizations.first!
        
        print("simon"+language)
        
        var welcomeD = "welcomeDescription"
        var secureD = "secureDescription"
        var privacyD = "privacyDescription"
        var unsendD = "unsendDescription"
        var shareD = "shareDescription"
        var efimeroD = "efimeroDescription"
        
        if language == "es" {
            welcomeD = "es_" + welcomeD
            secureD = "es_" + secureD
            privacyD = "es_" + privacyD
            unsendD = "es_" + unsendD
            shareD = "es_" + shareD
            efimeroD = "es_" + efimeroD
        }
        
        detailGuideView1.headerImageView.image = UIImage(named: "logo_criptextHD")
        
        detailGuideView1.detailTitleLabel.text = "Secure\nEmail Experience\nin your pocket"
        detailGuideView1.detailDescriptionLabel.text = "This is your safe zone.\nEverything you say here is private\nand secure so you can have peace of mind in every word"
        detailGuideView1.index = 0
        
        let url:URL = Bundle.main.url(forResource: "attachments", withExtension: "gif")!
        let data:Data = try! Data(contentsOf: url)
        
        detailGuideView2.headerGifView.animatedImage = FLAnimatedImage(animatedGIFData: data)
        detailGuideView2.headerGifView.stopAnimating()
        detailGuideView2.headerGifView.contentMode = UIViewContentMode.scaleAspectFit
        detailGuideView2.headerGifView.clipsToBounds = true
        detailGuideView2.headerTopConstraint.constant = 60
        
        detailGuideView2.detailTitleLabel.text = "Share Files Securely"
        detailGuideView2.detailDescriptionLabel.text = "Easily send files to colleagues and\nfriends in the safest and most convenient way possible."
        detailGuideView2.index = 1
    
        self.detailGuideArray.append(detailGuideView1)
        self.detailGuideArray.append(detailGuideView2)
        
        self.guideAppScrollView.contentSize = CGSize(width: CGFloat(Float(self.guideAppScrollView.frame.size.width)*Float(self.detailGuideArray.count)), height: self.guideAppScrollView.frame.size.height)
        
        self.loadScrollViewWithPage()
    }
    
    func changePage(){
        let page = self.guideAppPageControl.currentPage
        var frame:CGRect = self.guideAppScrollView.frame
        frame.origin.x = CGFloat(Float(frame.size.width) * Float(page))
        frame.origin.y = 0
        self.guideAppScrollView.scrollRectToVisible(frame, animated: true)
        self.pageControlUsed = true
    }
    
    func loadScrollViewWithPage(){
        
        for i in 0 ..< self.detailGuideArray.count {
            let view:DetailGuideView = self.detailGuideArray[i]
            
            var frame = self.guideAppScrollView.frame
            frame.origin.x = CGFloat(Float(frame.size.width) * Float(i))
            frame.origin.y = 0
            view.frame = frame
            self.guideAppScrollView.addSubview(view)
        }
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    
    @IBAction func actionPageControl(_ sender: UIPageControl) {
        self.changePage()
    }
    
    @IBAction func didPressSignIn(_ sender: UIButton) {
        CriptextSpinner.show(in: self.view, title: nil, image: UIImage(named: "icon_sent_chat.png"))
        GIDSignIn.sharedInstance().signIn()
    }
    
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    override var shouldAutorotate : Bool {
        return false
    }
    
}

extension LoginViewController: GIDSignInUIDelegate {
    // Dismiss the "Sign in with Google" view
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        self.dismiss(animated: true)
    }
}

extension LoginViewController: GIDSignInDelegate{
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        // Perform any operations when the user disconnects from app here.
        // ...
        print(error)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        guard error == nil else{
            CriptextSpinner.hide(from: self.view)
            print(error.localizedDescription)
            return
        }
        
        APIManager.connect(
            user.profile.email!,
            firstName: user.profile.givenName,
            lastName: user.profile.familyName,
            serverToken: user.serverAuthCode
        ) { (error, userResponse) in
            CriptextSpinner.hide(from: self.view)
            if let _ = error {
                GIDSignIn.sharedInstance().signOut()
                self.showAlert("Network Error", message: "Please try again later", style: .alert)
                return
            }
            
            //do something with user
            userResponse!.email = user.profile.email!
            userResponse!.firstName = user.profile.givenName
            userResponse!.lastName = user.profile.familyName
            userResponse!.serverAuthCode = user.serverAuthCode
            
            DBManager.store(userResponse!)
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let rootVC = storyboard.instantiateViewController(withIdentifier: "InboxNavigationController") as! UINavigationController
            let sidemenuVC = storyboard.instantiateViewController(withIdentifier: "ListLabelViewController") as! ListLabelViewController
            let inboxVC = rootVC.childViewControllers.first as! InboxViewController
            sidemenuVC.detailViewController = inboxVC
            
            inboxVC.currentUser = userResponse
            GIDSignIn.sharedInstance().delegate = inboxVC
            
            let vc = NavigationDrawerController(rootViewController: rootVC, leftViewController: sidemenuVC, rightViewController: nil)
            vc.delegate = inboxVC
            self.present(vc, animated: true){
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.replaceRootViewController(vc)
            }
        }
    }
}

extension LoginViewController: UIScrollViewDelegate{
    //pragma mark - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth:CGFloat = self.guideAppScrollView.frame.size.width
        let page = floor((self.guideAppScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1
        self.guideAppPageControl.currentPage = Int(page)
        self.pageControlUsed = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.pageControlUsed = false
        
        let viewD:DetailGuideView? = self.detailGuideArray[Int(self.guideAppPageControl.currentPage)]
        if let _ = viewD{
            if self.guideAppPageControl.currentPage > 0{
                //                viewd.animationImageView.startAnimating()
                if self.guideAppPageControl.currentPage == 1{
                    delay(3.2){
                        //                        viewd.animationImageView.stopAnimating()
                    }
                }
            }
        }
    }
}
