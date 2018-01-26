//
//  LoginPageViewController.swift
//  Criptext Secure Email
//
//  Created by Erika Perugachi on 4/10/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import UIKit
import GoogleAPIClientForREST
import Material

class LoginPageViewController: UIPageViewController, UIPageViewControllerDataSource {
  
    var tourViewController:TourViewController!
    var pageTitles:NSArray = []
    var pageImages:NSArray = []
    var pageDescription:NSArray = []
    var googleButton:GoogleButton!
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserDefaults.standard.set(true, forKey: "showEncryptionAlert")
        
        // background curve
        let shape = CAShapeLayer()
        self.view.layer.addSublayer(shape)
        shape.fillColor = UIColor(red: 52.0/255, green: 148.0/255, blue: 232.0/255, alpha: 1.0).cgColor
        shape.zPosition = -1;
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: CGFloat(0), y: CGFloat(self.view.bounds.height/1.8))) // first point
        path.addQuadCurve(to: CGPoint(x: self.view.bounds.width, y: self.view.bounds.height/1.8), controlPoint: CGPoint(x: self.view.bounds.width/2, y: self.view.bounds.height/1.5)) // curve
        path.addLine(to: CGPoint(x: self.view.bounds.width, y: self.view.bounds.height))
        path.addLine(to: CGPoint(x: 0, y: self.view.bounds.height))
        path.close()
        shape.path = path.cgPath
        
        self.view.backgroundColor = UIColor.white
        self.pageTitles = ["Your inbox: secured", "Send Secure Attachments", "Track Email & Attachment opens", "Set Expiration Timers", "Unsend at anytime"]
        self.pageImages = ["apptour-secure", "apptour-attachments", "apptour-track", "apptour-expiration", "apptour-unsend"]
        self.pageDescription = ["Send encrypted emails to anyone (they don't need to have Criptext)", "Share private documents securely", "Know when and where your emails and files have been opened", "Set Emails an Attachments to Self-destruct after they're opened", "Take back emails even after they're read"]
        
        self.googleButton = GoogleButton.instanceFromNib()
        self.googleButton.addTarget(self, action: #selector(didPressSignIn), for: .touchUpInside)
        self.googleButton.frame.origin = CGPoint(x:self.view.bounds.size.width/2 - self.googleButton.bounds.size.width/2, y:self.view.bounds.size.height - 110)
        self.view.addSubview(self.googleButton)
        
        self.dataSource = self
        self.setViewControllers([getViewControllerAtIndex(index: 0)] as [TourViewController], direction: UIPageViewControllerNavigationDirection.forward, animated: true, completion: nil)
        
        GIDSignIn.sharedInstance().uiDelegate = self
        GIDSignIn.sharedInstance().delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    func didPressSignIn(_ sender: UIButton) {
        CriptextSpinner.show(in: self.view, title: nil, image: UIImage(named: "icon_sent_chat.png"))
        GIDSignIn.sharedInstance().signIn()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?{
      let pageContent: TourViewController = viewController as! TourViewController
      var index = pageContent.index
      if ((index == 0) || (index == NSNotFound))
      {
        return nil
      }
      index = index! - 1
      return getViewControllerAtIndex(index: index!)
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?{
      let pageContent: TourViewController = viewController as! TourViewController
      var index = pageContent.index
      if (index == NSNotFound)
      {
        return nil;
      }
      index = index! + 1
      if (index == self.pageTitles.count)
      {
        return nil;
      }
      return getViewControllerAtIndex(index: index!)
    }
  
  
    func getViewControllerAtIndex(index: NSInteger) -> TourViewController{
        // Create a new view controller and pass suitable data.
        let tourViewController = self.storyboard?.instantiateViewController(withIdentifier: "TourViewController") as! TourViewController
        tourViewController.titleText = "\(self.pageTitles[index])"
        tourViewController.photoFile = "\(self.pageImages[index])"
        tourViewController.descriptionText = "\(self.pageDescription[index])"
        tourViewController.index = index
        return tourViewController
    }

  
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
      return self.pageTitles.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return 0;
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension LoginPageViewController: GIDSignInUIDelegate {
    // Dismiss the "Sign in with Google" view
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        self.dismiss(animated: true)
    }
}

extension LoginPageViewController: GIDSignInDelegate{
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
            if let error = error {
                print(error)
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
            
            let drawerVC = NavigationDrawerController(rootViewController: rootVC, leftViewController: sidemenuVC, rightViewController: nil)
            drawerVC.delegate = inboxVC
            let vc = SnackbarController(rootViewController: drawerVC)
            
            self.present(vc, animated: true)
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.replaceRootViewController(vc)
        }
    }
}
