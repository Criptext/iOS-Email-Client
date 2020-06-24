//
//  AliasViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/6/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Material
import Foundation

class CustomDomainEntryViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var customDomainTextInput: TextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    var myAccount: Account!
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("CUSTOM_DOMAIN").capitalized
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "icHelp").tint(with: .white), style: .plain, target: self, action: #selector(showInfo))
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        self.applyTheme()
        self.applyLocalization()
        self.showLoader(false)
    }
    
    func applyLocalization() {
        titleLabel.text = String.localize("ADD_DOMAIN_TITLE")
        subtitleLabel.text = String.localize("ADD_DOMAIN_SUBTITLE")
        nextButton.setTitle(String.localize("NEXT"), for: .normal)
    }
    
    func applyTheme() {
        customDomainTextInput.textColor = theme.mainText
        customDomainTextInput.tintColor = theme.mainText
        let attributedTitle = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        self.view.backgroundColor = theme.overallBackground
        titleLabel.textColor = theme.mainText
        subtitleLabel.textColor = theme.secondText

        customDomainTextInput.attributedPlaceholder = NSAttributedString(string: String.localize("CUSTOM_DOMAIN_EXAMPLE"), attributes: [.foregroundColor: theme.secondText])
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
    
    @IBAction func onInputChange(_ sender: Any) {
        self.clearInput()
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        clearInput()
        guard let domainName = customDomainTextInput.text?.lowercased(),
            !domainName.isEmpty,
            Utils.verifyDomain(domainString: domainName) else {
            self.setError(message: String.localize("CUSTOM_DOMAIN_ENTRY_EMPTY"))
            return
        }
        guard Utils.defaultDomains[domainName] == nil else {
            self.setError(message: String.localize("CUSTOM_DOMAIN_ENTRY_OWNED"))
            return
        }
        showLoader(true)
        APIManager.checkCustomDomainAvailability(customDomainName: domainName, token: myAccount.jwt) { (responseData) in
            if case .BadRequest = responseData {
                self.showLoader(false)
                self.setError(message: String.localize("CUSTOM_DOMAIN_ENTRY_ERROR"))
                return
            }
            guard case .Success = responseData else {
                self.showLoader(false)
                self.setError(message: String.localize("CUSTOM_DOMAIN_ERROR_UNKNOWN"))
                return
            }
            self.resgisterDomain(customDomain: domainName)
        }
    }
    
    func setError(message: String) {
        self.customDomainTextInput.detail = message
        self.customDomainTextInput.detailColor = theme.alert
        self.customDomainTextInput.dividerActiveColor = theme.alert
        self.customDomainTextInput.dividerNormalColor = theme.alert
    }
    
    func clearInput() {
        self.customDomainTextInput.detail = nil
        self.customDomainTextInput.dividerActiveColor = theme.criptextBlue
        self.customDomainTextInput.dividerNormalColor = theme.secondText
    }
    
    func resgisterDomain(customDomain: String){
        APIManager.registerCustomDomainAvailability(customDomainName: customDomain, token: myAccount.jwt) { (responseData) in
            if case .BadRequest = responseData {
                self.showLoader(false)
                self.setError(message: String.localize("DOMAIN_ALREADY_REGISTERED"))
                return
            }
            if case .ServerError = responseData {
                self.showLoader(false)
                self.setError(message: String.localize("SERVER_ERROR_RETRY"))
                return
            }
            if case .TooManyDevices = responseData {
                self.showLoader(false)
                self.setError(message: String.localize("DOMAIN_LIMIT_REACHED"))
                return
            }
            guard case .SuccessDictionary = responseData else {
                self.showLoader(false)
                self.setError(message: String.localize("CUSTOM_DOMAIN_ENTRY_ERROR"))
                return
            }
            let newDomain = CustomDomain()
            newDomain.account = self.myAccount
            newDomain.name = customDomain
            newDomain.validated = false
            DBManager.store(newDomain)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let step1VC = storyboard.instantiateViewController(withIdentifier: "registerDomainStepOneViewController") as! RegisterDomainStepOneViewController
            step1VC.myAccount = self.myAccount
            step1VC.customDomain = newDomain
            self.navigationController?.pushViewController(step1VC, animated: true)
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
    
    func askUpgradePlus() {
        let popover = GetPlusUIPopover()
        popover.plusType = .domains
        popover.onResponse = { upgrade in
            if (upgrade) {
                self.goToUpgradePlus()
            }
        }
        self.presentPopover(popover: popover, height: 435)
    }
    
    func goToUpgradePlus() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let webviewVC = storyboard.instantiateViewController(withIdentifier: "plusviewcontroller") as! PlusViewController
        self.navigationController?.pushViewController(webviewVC, animated: true)
    }
}

extension CustomDomainEntryViewController: MembershipWebViewControllerDelegate {
    func close() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension CustomDomainEntryViewController: UIGestureRecognizerDelegate {
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
