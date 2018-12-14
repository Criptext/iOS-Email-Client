//
//  PasswordUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class PasswordUIPopover: BaseUIPopover {
    
    var answerShouldDismiss = true
    var onOkPress: ((String) -> (Void))?
    var onLogoutPress: (() -> (Void))?
    var myAccount: Account?
    var remotelyCheckPassword = false
    var initialTitle: String?
    var initialAttrMessage: NSAttributedString?
    var initialMessage: String?
    @IBOutlet weak var titleHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var passwordTitleLabel: UILabel!
    @IBOutlet weak var passwordMessageLabel: UILabel!
    
    init(){
        super.init("PasswordUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isVisibilityIconButtonEnabled = true
        passwordTextField.becomeFirstResponder()
        passwordTextField.detailColor = .alert
        shouldDismiss = !remotelyCheckPassword
        passwordTitleLabel.text = remotelyCheckPassword ? "Your password has changed. Confirm your new password, if you Cancel, all local data will be erased." : "Enter your password to continue"
        if let title = initialTitle {
            passwordTitleLabel.text = title
        }
        if let attrMessage = initialAttrMessage {
            passwordMessageLabel.attributedText = attrMessage
            let height = Utils.getLabelHeight(attrMessage.string, width: passwordMessageLabel.frame.width, fontSize: 14)
            messageHeightConstraint.constant = height
            if let title = initialTitle {
                titleHeightConstraint.constant = Utils.getLabelHeight(title, width: passwordMessageLabel.frame.width, fontSize: 16) + 30
            }
        } else if let message = initialMessage {
            passwordMessageLabel.text = message
        } else {
            messageHeightConstraint.constant = 0
        }
        
        showLoader(false)
    }
    
    @IBAction func okPress(_ sender: Any) {
        guard let password = passwordTextField.text else {
            return
        }
        self.showLoader(true)
        passwordTextField.resignFirstResponder()
        guard !remotelyCheckPassword else {
            validatePassword(password)
            return
        }
        guard answerShouldDismiss else {
            self.onOkPress?(password)
            return
        }
        self.dismiss(animated: true, completion: { [weak self] in
            self?.onOkPress?(password)
        })
    }
    
    func validatePassword(_ password: String){
        passwordTextField.detail = ""
        guard let account = myAccount else {
            return
        }
        APIManager.unlockDevice(password: password.sha256()!, account: account) { (responseData) in
            self.showLoader(false)
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.passwordTextField.detail = error.description
                return
            }
            if case .BadRequest = responseData {
                self.passwordTextField.detail = "Wrong Password!"
                return
            }
            if case let .TooManyRequests(waitingTime) = responseData {
                if waitingTime < 0 {
                    self.passwordTextField.detail = String.localize("You have tried to validate too many times, please try again later")
                } else {
                    self.passwordTextField.detail = String.localize("Too many consecutive attempts. Please try again in \(Time.remaining(seconds: waitingTime))")
                }
                return
            }
            guard case .Success = responseData else {
                self.passwordTextField.detail = "Unable to validate user. Please try again"
                return
            }
            self.dismiss(animated: true, completion: { [weak self] in
                self?.onOkPress?(password)
            })
        }
    }
    
    func showLoader(_ show: Bool){
        self.shouldDismiss = !show
        self.okButton.isEnabled = !show
        self.cancelButton.isEnabled = !show
        self.passwordTextField.isEnabled = !show
        self.loader.isHidden = !show
        guard show else {
            loader.stopAnimating()
            return
        }
        loader.startAnimating()
    }
    
    @IBAction func cancelPress(_ sender: Any) {
        passwordTextField.detail = ""
        guard self.remotelyCheckPassword,
            let account = myAccount else {
            dismiss(animated: true)
            return
        }
        self.showLoader(true)
        APIManager.logout(account: account) { (responseData) in
            self.showLoader(false)
            guard case .Success = responseData else {
                self.passwordTextField.detail = "Unable to logout. Try again."
                return
            }
            self.dismiss(animated: true, completion: { [weak self] in
                self?.onLogoutPress?()
            })
        }
    }
}
