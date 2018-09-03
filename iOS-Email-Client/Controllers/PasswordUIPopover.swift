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
    
    var onOkPress: ((String) -> (Void))?
    var onLogoutPress: (() -> (Void))?
    var myAccount: Account?
    var remotelyCheckPassword = false
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var passwordTitleLabel: UILabel!
    
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
        self.dismiss(animated: true, completion: { [weak self] in
            self?.onOkPress?(password)
        })
    }
    
    func validatePassword(_ password: String){
        passwordTextField.detail = ""
        guard let jwt = myAccount?.jwt else {
            return
        }
        APIManager.unlockDevice(password: password.sha256()!, token: jwt) { (responseData) in
            self.showLoader(false)
            guard case .Success = responseData else {
                self.passwordTextField.detail = "Wrong Password!"
                return
            }
            self.dismiss(animated: true, completion: { [weak self] in
                self?.onOkPress?(password)
            })
        }
    }
    
    func showLoader(_ show: Bool){
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
            let jwt = myAccount?.jwt else {
            dismiss(animated: true)
            return
        }
        self.showLoader(true)
        APIManager.logout(token: jwt) { (responseData) in
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
