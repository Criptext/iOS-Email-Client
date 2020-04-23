//
//  AliasViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/6/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Material
import Foundation

class RegisterDomainStepOneViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var stepOneLabel: UILabel!
    @IBOutlet weak var stepTwoLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    var myAccount: Account!
    var customDomain: CustomDomain!
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("CUSTOM_DOMAIN").capitalized
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icHelp").tint(with: .white), style: .plain, target: self, action: #selector(showInfo))
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        self.loader.isHidden = true
        self.applyTheme()
        self.applyLocalization()
    }
    
    func applyLocalization() {
        titleLabel.text = String.localize("ADD_DOMAIN_STEPS")
        stepOneLabel.text = String.localize("ADD_DOMAIN_STEPS_ONE")
        stepTwoLabel.text = String.localize("ADD_DOMAIN_STEPS_TWO")
        nextButton.setTitle(String.localize("NEXT"), for: .normal)
    }
    
    func applyTheme() {
        let attributedTitle = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        self.view.backgroundColor = theme.overallBackground
        
        titleLabel.textColor = theme.mainText
        stepOneLabel.textColor = theme.secondText
        stepTwoLabel.textColor = theme.secondText
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    @objc func showInfo(){
        let popover = GenericAlertUIPopover()
        popover.myTitle = String.localize("CUSTOM_DOMAIN")
        popover.myMessage = String.localize("CUSTOM_DOMAIN_INFO_MESSAGE_1")
        self.presentPopover(popover: popover, height: 220)
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        showLoader(true)
        self.getMXRecordsAndStepTwo()
    }
    
    func getMXRecordsAndStepTwo(){
        showLoader(true)
        APIManager.getMXCustomDomain(customDomainName: customDomain.name, token: myAccount.jwt) { (responseData) in
            guard case let .SuccessDictionary(data) = responseData,
                let mx = data["mx"] as? [[String: Any]] else {
                self.showLoader(false)
                    return
            }
            let myMXRecords = mx.map({MXRecord.fromDictionary(data: $0)})
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let step2VC = storyboard.instantiateViewController(withIdentifier: "registerDomainStepTwoViewController") as! RegisterDomainStepTwoViewController
            step2VC.myAccount = self.myAccount
            step2VC.customDomain = self.customDomain
            step2VC.mxRecords = myMXRecords
            self.navigationController?.pushViewController(step2VC, animated: true)
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

extension RegisterDomainStepOneViewController {
    func reloadView() {
        self.applyTheme()
    }
}

extension RegisterDomainStepOneViewController: UIGestureRecognizerDelegate {
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
