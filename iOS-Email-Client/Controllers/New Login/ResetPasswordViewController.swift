//
//  ResetPasswordViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/8/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class ResetPasswordViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var emailTextField: StatusTextField!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyTheme()
        applyLocalization()
        
        emailTextField.becomeFirstResponder()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.mainText
        emailTextField.applyMyTheme()
        
        self.view.backgroundColor = theme.overallBackground
        
        emailTextField.attributedPlaceholder = NSAttributedString(string: String.localize("RESET_PLACEHOLDER"), attributes: [.foregroundColor: theme.secondText, .font: Font.regular.size(emailTextField.minimumFontSize) as Any])
    }
    
    func applyLocalization() {
        resetButton.setTitle(String.localize("RESET_PASSWORD"), for: .normal)
        titleLabel.text = String.localize("RESET_TITLE")
        messageLabel.text = String.localize("RESET_MESSAGE")
    }
    
    @IBAction func onEmailChange(_ sender: Any) {
        guard let email = emailTextField.text else {
            enableButton(false)
            return
        }
        
        emailTextField.setStatus(.none)
        enableButton(Utils.validateEmail(email))
    }
    
    @IBAction func onResetPress(_ sender: Any) {
        emailTextField.resignFirstResponder()
        sendResetLink()
    }
    
    @IBAction func onBackPress(_ sender: Any) {
        goBack()
    }
    
    func goBack() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func enableButton(_ enable: Bool) {
        if enable {
            resetButton.isEnabled = true
            resetButton.alpha = 1
        } else {
            resetButton.isEnabled = false
            resetButton.alpha = 0.5
        }
    }
    
    func sendResetLink(){
        guard let email = emailTextField.text else {
            enableButton(false)
            return
        }
        let emailSplit = email.split(separator: "@")
        let username = emailSplit[0].description
        let domain = emailSplit.count > 1 ? emailSplit[1].description : Env.plainDomain
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
            guard case let .SuccessDictionary(data) = responseData,
                let email = data["address"] as? String else {
                    self.presentResetAlert(title: String.localize("REQUEST_ERROR"), message: String.localize("RECOVERY_NOT_SET_RESET"))
                    return
            }
            self.showSuccessResetViewController(username: username, domain: domain, recoveryEmail: Utils.maskEmailAddress(email: email))
        }
    }
    
    func presentResetAlert(title: String, message: String) {
        emailTextField.setStatus(.invalid, message)
    }
    
    func showSuccessResetViewController(username: String, domain: String, recoveryEmail: String) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "successresetviewcontroller")  as! SuccessResetViewController
        controller.username = username
        controller.domain = domain
        controller.recoveryEmail = recoveryEmail
        navigationController?.pushViewController(controller, animated: true)
    }
}
