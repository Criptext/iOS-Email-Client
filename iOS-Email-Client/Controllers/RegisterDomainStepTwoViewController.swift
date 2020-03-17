//
//  AliasViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/6/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Material
import Foundation

class RegisterDomainStepTwoViewController: UIViewController {
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var pageOption1: UIButton!
    @IBOutlet weak var pageOption2: UIButton!
    @IBOutlet weak var pageOption3: UIButton!
    @IBOutlet weak var pageOption4: UIButton!
    @IBOutlet weak var pageOption5: UIButton!
    @IBOutlet weak var pagesContainerView: UIView!
    //View One
    @IBOutlet weak var oneView: UIView!
    @IBOutlet weak var typeOne: UILabel!
    @IBOutlet weak var priorityOne: UILabel!
    @IBOutlet weak var nameOne: UILabel!
    @IBOutlet weak var valueOne: UILabel!
    @IBOutlet weak var copyButtonOne: UIButton!
    
    //View Two
    @IBOutlet weak var twoView: UIView!
    @IBOutlet weak var typeTwo: UILabel!
    @IBOutlet weak var priorityTwo: UILabel!
    @IBOutlet weak var nameTwo: UILabel!
    @IBOutlet weak var valueTwo: UILabel!
    @IBOutlet weak var copyButtonTwo: UIButton!
    
    //View Three
    @IBOutlet weak var threeView: UIView!
    @IBOutlet weak var typeThree: UILabel!
    @IBOutlet weak var priorityThree: UILabel!
    @IBOutlet weak var nameThree: UILabel!
    @IBOutlet weak var valueThree: UILabel!
    @IBOutlet weak var copyButtonThree: UIButton!
    
    //View Four
    @IBOutlet weak var fourthView: UIView!
    @IBOutlet weak var typeFour: UILabel!
    @IBOutlet weak var priorityFour: UILabel!
    @IBOutlet weak var nameFour: UILabel!
    @IBOutlet weak var valueFour: UILabel!
    @IBOutlet weak var copyButtonFour: UIButton!
    
    //View Five
    @IBOutlet weak var fifthView: UIView!
    @IBOutlet weak var typeFive: UILabel!
    @IBOutlet weak var priorityFive: UILabel!
    @IBOutlet weak var nameFive: UILabel!
    @IBOutlet weak var valueFive: UILabel!
    @IBOutlet weak var copyButtonFive: UIButton!
    
    let spacing: CGFloat = 300
    let pageOptionColor = UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 0.58)
    let activeOptionColor = UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)
    var initialX: CGFloat = 0
    var myAccount: Account!
    var customDomain: CustomDomain!
    var mxRecords: [MXRecord]!
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("CUSTOM_DOMAIN").capitalized
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icHelp").tint(with: .white), style: .plain, target: self, action: #selector(showInfo))
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        self.applyTheme()
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.draggedView(_:)))
        pagesContainerView.isUserInteractionEnabled = true
        pagesContainerView.addGestureRecognizer(gesture)
        
        initialX = oneView.center.x
        nextButton.isEnabled = false
        setupMXRecords()
        
        jumpToPage(1)
    }
    
    func setupMXRecords(){
        //1
        typeOne.text = mxRecords[0].type
        priorityOne.text = "\(mxRecords[0].priority)"
        nameOne.text = mxRecords[0].host
        valueOne.text = mxRecords[0].destination
        
        //2
        typeTwo.text = mxRecords[1].type
        priorityTwo.text = "\(mxRecords[1].priority)"
        nameTwo.text = mxRecords[1].host
        valueTwo.text = mxRecords[1].destination
        
        //1
        typeThree.text = mxRecords[2].type
        priorityThree.text = "\(mxRecords[2].priority)"
        nameThree.text = mxRecords[2].host
        valueThree.text = mxRecords[2].destination
        
        //1
        typeFour.text = mxRecords[3].type
        priorityFour.text = "\(mxRecords[3].priority)"
        nameFour.text = mxRecords[3].host
        valueFour.text = mxRecords[3].destination
        
        //1
        typeFive.text = mxRecords[4].type
        priorityFive.text = "\(mxRecords[4].priority)"
        nameFive.text = mxRecords[4].host
        valueFive.text = mxRecords[4].destination
    }
    
    @objc func draggedView(_ sender: UIPanGestureRecognizer) {
        
        switch(sender.state) {
        case .changed:
            let translation = sender.translation(in: self.view)
            let newPositionX = oneView.center.x + translation.x * 1.5
            oneView.center = CGPoint(x: newPositionX, y: oneView.center.y)
            twoView.center = CGPoint(x: newPositionX + self.spacing, y: twoView.center.y)
            threeView.center = CGPoint(x: newPositionX + 2 * self.spacing, y: threeView.center.y)
            fourthView.center = CGPoint(x: newPositionX + 3 * self.spacing, y: fourthView.center.y)
            fifthView.center = CGPoint(x: newPositionX + 4 * self.spacing, y: fifthView.center.y)
            sender.setTranslation(CGPoint.zero, in: self.view)
        case .ended:
            repositionItems()
        default:
            break
        }
    }
    
    func repositionItems() {
        nextButton.isEnabled = false
        let oneDistance = abs(Int32(initialX - oneView.center.x))
        let twoDistance = abs(Int32(initialX - twoView.center.x))
        let threeDistance = abs(Int32(initialX - threeView.center.x))
        let fourthDistance = abs(Int32(initialX - fourthView.center.x))
        let fifthDistance = abs(Int32(initialX - fifthView.center.x))
        if (twoDistance < oneDistance && twoDistance  < threeDistance
            && twoDistance < fourthDistance && twoDistance < fifthDistance){
            jumpToPage(2)
            return
        } else if (threeDistance < oneDistance && threeDistance < twoDistance
            && threeDistance < fourthDistance && threeDistance < fifthDistance){
            jumpToPage(3)
            return
        } else if (fourthDistance < oneDistance && fourthDistance < twoDistance
            && fourthDistance < threeDistance && fourthDistance < fifthDistance){
            jumpToPage(4)
            return
        } else if (fifthDistance < oneDistance && fifthDistance < twoDistance
            && fifthDistance < threeDistance && fifthDistance < fourthDistance){
            nextButton.isEnabled = true
            jumpToPage(5)
            return
        }
        jumpToPage(1)
    }
    
    @IBAction func onPagePress(_ sender: Any) {
        switch(sender as? UIButton){
        case pageOption1:
            jumpToPage(1)
        case pageOption2:
            jumpToPage(2)
        case pageOption3:
            jumpToPage(3)
        case pageOption4:
            jumpToPage(4)
        case pageOption5:
            jumpToPage(5)
        default:
            break
        }
    }
    
    func jumpToPage(_ page: Int){
        let newPositionX = self.initialX - CGFloat(page - 1) * self.spacing
        UIView.animate(withDuration: 0.3, animations: {
            self.pageOption1.backgroundColor = page == 1 ? self.activeOptionColor : self.pageOptionColor
            self.pageOption2.backgroundColor = page == 2 ? self.activeOptionColor : self.pageOptionColor
            self.pageOption3.backgroundColor = page == 3 ? self.activeOptionColor : self.pageOptionColor
            self.pageOption4.backgroundColor = page == 4 ? self.activeOptionColor : self.pageOptionColor
            self.pageOption5.backgroundColor = page == 5 ? self.activeOptionColor : self.pageOptionColor
            self.oneView.center = CGPoint(x: newPositionX, y: self.oneView.center.y)
            self.twoView.center = CGPoint(x: newPositionX + self.spacing, y: self.twoView.center.y)
            self.threeView.center = CGPoint(x: newPositionX + 2 * self.spacing, y: self.threeView.center.y)
            self.fourthView.center = CGPoint(x: newPositionX + 3 * self.spacing, y: self.fourthView.center.y)
            self.fifthView.center = CGPoint(x: newPositionX + 4 * self.spacing, y: self.fifthView.center.y)
        }) { (success) in
            switch(page){
            default:
                break
            }
        }
    }
    
    func applyTheme() {
        let attributedTitle = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        self.view.backgroundColor = theme.overallBackground
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    @objc func showInfo(){
        let popover = GenericAlertUIPopover()
        popover.myTitle = String.localize("STEP_2_INFO_TITLE")
        popover.myMessage = String.localize("STEP_2_INFO_MESSAGE")
        self.presentPopover(popover: popover, height: 220)
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        showLoader(true)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let step3VC = storyboard.instantiateViewController(withIdentifier: "registerDomainStepThreeViewController") as! RegisterDomainStepThreeViewController
        step3VC.myAccount = self.myAccount
        self.navigationController?.pushViewController(step3VC, animated: true)
    }
    
    @IBAction func onCopyPressed(_ sender: Any) {
        switch(sender as? UIButton){
        case copyButtonOne:
            UIPasteboard.general.string = valueOne.text
        case copyButtonTwo:
            UIPasteboard.general.string = valueTwo.text
        case copyButtonThree:
            UIPasteboard.general.string = valueThree.text
        case copyButtonFour:
            UIPasteboard.general.string = valueFour.text
        case copyButtonFive:
            UIPasteboard.general.string = valueFive.text
        default:
            break
        }
    }
    
    func showLoader(_ show: Bool){
        guard show else {
            loader.isHidden = true
            loader.stopAnimating()
            nextButton.isEnabled = true
            nextButton.setTitle(String.localize("NEXT"), for: .normal)
            return
        }
        
        loader.isHidden = false
        loader.startAnimating()
        nextButton.isEnabled = false
        nextButton.setTitle("", for: .normal)
    }
}

extension RegisterDomainStepTwoViewController: CustomTabsChildController {
    func reloadView() {
        self.applyTheme()
    }
}

extension RegisterDomainStepTwoViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}
