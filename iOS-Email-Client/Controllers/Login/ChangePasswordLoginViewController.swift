//
//  ChangePasswordLoginViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 6/12/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class ChangePasswordLoginViewController: UIViewController{
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var errorMark: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var confirmErrorMark: UIImageView!
    @IBOutlet weak var confirmErrorLabel: UILabel!
    @IBOutlet weak var confirmPasswordTextField: TextField!
    @IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var resetLoaderView: UIActivityIndicatorView!
    var loginData: LoginData!
    var multipleAccount = false
    var buttonTitle: String {
        return String.localize("CHANGE_PASS")
    }
    
    override func viewDidLoad() {
        emailLabel.text = loginData.email
        resetLoaderView.isHidden = true
        showFeedback(false)
        checkToEnableDisableResetButton()
        let tap: UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        passwordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        let _ = passwordTextField.becomeFirstResponder()
        
        let placeholderAttrs = [.foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)] as [NSAttributedString.Key: Any]
        passwordTextField.placeholderAnimation = .hidden
        passwordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("ENTER_NEW_PASS"), attributes: placeholderAttrs)
        
        confirmPasswordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        
        let confirmPlaceholderAttrs = [.foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)] as [NSAttributedString.Key: Any]
        confirmPasswordTextField.placeholderAnimation = .hidden
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("CONFIRM_NEW_PASS"), attributes: confirmPlaceholderAttrs)
        
    }
    
    func validateForm() -> Bool {
        return passwordTextField.text!.count > 7 && passwordTextField.text! == confirmPasswordTextField.text!
    }
    
    func setValidField(_ field: TextField, valid: Bool, error: String = "") {
        field.detail = error
        field.dividerActiveColor = valid ? .mainUI : .alert
    }
    
    @objc func onDonePress(_ sender: Any){
        switch(sender as? TextField){
        case passwordTextField:
            let _ = confirmPasswordTextField.becomeFirstResponder()
            break
        default:
            if(resetButton.isEnabled){
                onResetPress(sender)
            }
        }
    }
    
    @objc func hideKeyboard(){
        self.passwordTextField.endEditing(true)
        self.confirmPasswordTextField.endEditing(true)
    }
    
    @IBAction func onPasswordChange(_ sender: TextField!) {
        switch(sender){
        case passwordTextField, confirmPasswordTextField:
            guard passwordTextField.text!.count > 7 else {
                setValidField(passwordTextField, valid: false, error: String.localize("8_CHARS"))
                break
            }
            setValidField(passwordTextField, valid: true)
            guard confirmPasswordTextField.text == passwordTextField.text else {
                setValidField(confirmPasswordTextField, valid: false, error: String.localize("PASS_MATCH"))
                break
            }
            setValidField(confirmPasswordTextField, valid: true)
        default:
            break
        }
        
        resetButton.isEnabled = validateForm()
        resetButton.alpha = resetButton.isEnabled ? 1.0 : 0.6
        showFeedback(false)
    }
    
    @IBAction func onResetPress(_ sender: Any) {
        loginRequest()
    }
    
    func loginRequest(){
        guard let password = loginData.password else {
            return
        }
        guard let newPassword = confirmPasswordTextField.text else {
            return
        }
        showLoader(true)
        let email = loginData.email
        let username = String(email.split(separator: "@")[0])
        let domain = String(email.split(separator: "@")[1])
        APIManager.loginChangePasswordRequest(username: username, domain: domain, password: password.sha256()!, newPassword: newPassword.sha256()!) { (responseData) in
            self.showLoader(false)
            if case let .TooManyRequests(waitingTime) = responseData {
                if waitingTime < 0 {
                    self.showFeedback(true, String.localize("TOO_MANY_SIGNIN"))
                } else {
                    self.showFeedback(true, String.localize("ATTEMPTS_TIME_LEFT", arguments: Time.remaining(seconds: waitingTime)))
                }
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.showFeedback(true, error.description)
                return
            }
            guard case let .SuccessString(dataString) = responseData,
                let data = Utils.convertToDictionary(text: dataString) else {
                    self.showFeedback(true, String.localize("WRONG_PASS_RETRY"))
                    return
            }
            let name = data["name"] as! String
            let deviceId = data["deviceId"] as! Int
            let token = data["token"] as! String
            let signupData = SignUpData(username: username, password: newPassword, domain: domain, fullname: name, optionalEmail: nil)
            signupData.deviceId = deviceId
            signupData.token = token
            signupData.comingFromLogin = true
            self.jumpToCreatingAccount(signupData: signupData)
        }
    }
    
    @IBAction func textfieldDidEndOnExit(_ sender: Any) {
        onDonePress(sender)
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func checkToEnableDisableResetButton(){
        let textCount = passwordTextField.text?.count ?? 0
        resetButton.isEnabled = !(passwordTextField.isEmpty || textCount < Constants.MinCharactersPassword) && resetLoaderView.isHidden
        resetButton.setTitle(resetLoaderView.isHidden ? buttonTitle : "", for: .normal)
        if(resetButton.isEnabled){
            resetButton.alpha = 1.0
        }else{
            resetButton.alpha = 0.5
        }
    }
    
    func showFeedback(_ show: Bool, _ message: String? = nil){
        errorMark.isHidden = !show
        errorLabel.isHidden = !show
        confirmErrorMark.isHidden = !show
        confirmErrorLabel.isHidden = !show
        if let errorMessage = message {
            labelHeightConstraint.constant = UIUtils.getLabelHeight(errorMessage, width: errorLabel.frame.width, fontSize: errorLabel.fontSize)
        }
        errorLabel.text = message ?? ""
    }
    
    func jumpToCreatingAccount(signupData: SignUpData){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "creatingaccountview") as! CreatingAccountViewController
        controller.signupData = signupData
        controller.multipleAccount = self.multipleAccount
        self.present(controller, animated: true, completion: nil)
    }
    
    func showLoader(_ show: Bool){
        resetLoaderView.isHidden = !show
        checkToEnableDisableResetButton()
        guard show else {
            resetLoaderView.stopAnimating()
            return
        }
        resetLoaderView.startAnimating()
    }
}
