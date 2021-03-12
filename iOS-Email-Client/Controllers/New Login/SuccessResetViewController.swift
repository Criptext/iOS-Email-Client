//
//  SuccessResetViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/8/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class SuccessResetViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    var username: String = ""
    var domain: String = ""
    var recoveryEmail: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyTheme()
        applyLocalization()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.secondText
        emailLabel.textColor = theme.markedText
        
        self.view.backgroundColor = theme.overallBackground
    }
    
    func applyLocalization() {
        resendButton.setTitle(String.localize("RESEND_LINK"), for: .normal)
        titleLabel.text = String.localize("SUCCESS_RESET_TITLE")
        messageLabel.text = String.localize("SUCCESS_RESET_MESSAGE")
        emailLabel.text = recoveryEmail
    }
    
    @IBAction func onResetPress(_ sender: Any) {
        sendResetLink()
    }
    
    @IBAction func onBackPress(_ sender: Any) {
        goBack()
    }
    
    func goBack() {
        let returnVC = self.navigationController?.viewControllers.first(where: { (vc) -> Bool in
            return vc.isKind(of: LoginViewController.self)
        })
        
        if let returnToVC = returnVC {
            self.navigationController?.popToViewController(returnToVC, animated: true)
        } else {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func enableButton(_ enable: Bool) {
        if enable {
            resendButton.isEnabled = true
            resendButton.alpha = 1
        } else {
            resendButton.isEnabled = false
            resendButton.alpha = 0.5
        }
    }
    
    func sendResetLink(){
        enableButton(false)
        loadingView.startAnimating()
        APIManager.resetPassword(username: username, domain: domain) { (responseData) in
            self.enableButton(true)
            self.loadingView.stopAnimating()
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.presentResetAlert(title: String.localize("REQUEST_ERROR"), message: error.description)
                return
            }
            guard case .SuccessDictionary = responseData else {
                    self.presentResetAlert(title: String.localize("REQUEST_ERROR"), message: String.localize("RECOVERY_NOT_SET_RESET"))
                    return
            }
            self.showSuccess()
        }
    }
    
    func presentResetAlert(title: String, message: String) {
        let alertVC = GenericAlertUIPopover()
        alertVC.myTitle = title
        alertVC.myMessage = message
        self.presentPopover(popover: alertVC, height: 220)
    }
    
    func showSuccess() {
        let alertVC = GenericAlertUIPopover()
        alertVC.myTitle = String.localize("PASSWORD_RESET")
        alertVC.myMessage = String.localize("RESET_LINK_SENT_1") + recoveryEmail
        self.presentPopover(popover: alertVC, height: 240)
    }
}
