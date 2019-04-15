//
//  SignUpViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material
import Alamofire

class SignUpViewController: UIViewController{
    let MIN_USERNAME_LENGTH = 3
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var termsConditionsLabel: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!

    @IBOutlet weak var usernameTextField: StatusTextField!
    @IBOutlet weak var fullnameTextField: StatusTextField!
    @IBOutlet weak var emailTextField: StatusTextField!
    @IBOutlet weak var confirmPasswordTextField: StatusTextField!
    @IBOutlet weak var passwordTextField: StatusTextField!
    
    @IBOutlet weak var usernameMark: UIImageView!
    @IBOutlet weak var fullnameMark: UIImageView!
    @IBOutlet weak var passwordMark: UIImageView!
    @IBOutlet weak var confirmPasswordMark: UIImageView!
    @IBOutlet weak var emailMark: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    var loadingAccount = false
    var apiRequest : DataRequest?
    var multipleAccount = false
    
    override func viewDidLoad(){
        super.viewDidLoad()
        labelInit()
        fieldsInit()
        
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        setupFields()
    }
    
    func setupFields(){
        let placeholderAttrs = [.foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)] as [NSAttributedStringKey: Any]
        
        usernameTextField.autocorrectionType = .no
        usernameTextField.autocapitalizationType = .none
        usernameTextField.markView = usernameMark
        usernameTextField.font = Font.regular.size(17.0)
        usernameTextField.placeholderAnimation = .hidden
        usernameTextField.attributedPlaceholder = NSAttributedString(string: String.localize("USERNAME"), attributes: placeholderAttrs)
        fullnameTextField.markView = fullnameMark
        fullnameTextField.font = Font.regular.size(17.0)
        fullnameTextField.placeholderAnimation = .hidden
        fullnameTextField.attributedPlaceholder = NSAttributedString(string: String.localize("FULLNAME"), attributes: placeholderAttrs)
        passwordTextField.markView = passwordMark
        passwordTextField.font = Font.regular.size(17.0)
        passwordTextField.rightViewMode = .always
        passwordTextField.placeholderAnimation = .hidden
        passwordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("PASSWORD"), attributes: placeholderAttrs)
        confirmPasswordTextField.markView = confirmPasswordMark
        confirmPasswordTextField.font = Font.regular.size(17.0)
        confirmPasswordTextField.rightViewMode = .always
        confirmPasswordTextField.placeholderAnimation = .hidden
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("CONFIRM_PASSWORD"), attributes: placeholderAttrs)
        emailTextField.markView = emailMark
        emailTextField.font = Font.regular.size(17.0)
        emailTextField.placeholderAnimation = .hidden
        emailTextField.attributedPlaceholder = NSAttributedString(string: String.localize("RECOVERY_OPT"), attributes: placeholderAttrs)
        checkToEnableDisableCreateButton()
        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: 647.0)
        usernameTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        fullnameTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        passwordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        confirmPasswordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        emailTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
    }
    
    @objc func onDonePress(_ sender: Any){
        switch(sender as? StatusTextField){
        case usernameTextField:
            fullnameTextField.becomeFirstResponder()
            break
        case fullnameTextField:
            passwordTextField.becomeFirstResponder()
            break
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
            break
        case confirmPasswordTextField:
            emailTextField.becomeFirstResponder()
            break
        default:
            if(createAccountButton.isEnabled){
                createAccountPress(sender)
            }
        }
    }
    
    @IBAction func onDidEndOnExit(_ sender: Any) {
        onDonePress(sender)
    }
    
    @IBAction func inputEditEnd(_ sender: TextField){
        switch(sender){
        case usernameTextField:
            checkUsername()
            break
        case fullnameTextField:
            checkFullname()
            break
        case passwordTextField, confirmPasswordTextField:
            checkPassword()
            break
        case emailTextField:
            checkOptionalEmail()
            break
        default: return
        }
        checkToEnableDisableCreateButton()
    }
    
    func checkUsername(){
        usernameTextField.text = usernameTextField.text?.lowercased()
        guard let username = usernameTextField.text,
            Utils.isValidUsername(username) else {
            let inputError = String.localize("VALID_EMAIL_CONDITION")
            usernameTextField.setStatus(.invalid, inputError)
            return
        }
        
        usernameTextField.setStatus(.none)
        apiRequest?.cancel()
        apiRequest = APIManager.checkAvailableUsername(username) { (responseData) in
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.usernameTextField.setStatus(.invalid, error.description)
                self.checkToEnableDisableCreateButton()
                return
            }
            guard case .Success = responseData else {
                self.usernameTextField.setStatus(.invalid, String.localize("USERNAME_EXISTS"))
                self.checkToEnableDisableCreateButton()
                return
            }
            self.usernameTextField.setStatus(.valid)
            self.checkToEnableDisableCreateButton()
        }
    }
    
    func checkFullname(){
        guard !fullnameTextField.isEmpty else {
            let inputError = String.localize("ENTER_NAME")
            fullnameTextField.setStatus(.invalid, inputError)
            return
        }
        fullnameTextField.setStatus(.valid)
    }
    
    func checkPassword(){
        passwordTextField.setStatus(.none)
        confirmPasswordTextField.setStatus(.none)
        guard let password = passwordTextField.text,
            password.count >= Constants.MinCharactersPassword else {
            let inputError = String.localize("PASSWORD_LENGTH")
            passwordTextField.setStatus(.invalid, inputError)
            return
        }
        passwordTextField.setStatus(.valid)
        
        guard let confirmPassword = confirmPasswordTextField.text, confirmPassword == password else {
            let inputError = String.localize("PASSWORD_NOT_MATCH")
            confirmPasswordTextField.setStatus(.invalid, inputError)
            return
        }
        confirmPasswordTextField.setStatus(.valid)
        
    }
    
    func checkOptionalEmail(){
        guard !emailTextField.isEmpty else {
            emailTextField.setStatus(.none)
            return
        }
        guard Utils.validateEmail(emailTextField.text!) else {
            let inputError = String.localize("NOT_VALID_EMAIL")
            emailTextField.setStatus(.invalid, inputError)
            return
        }
        emailTextField.setStatus(.valid)
    }
    
    @objc func hideKeyboard(){
        self.fullnameTextField.endEditing(true)
        self.passwordTextField.endEditing(true)
        self.confirmPasswordTextField.endEditing(true)
        self.emailTextField.endEditing(true)
        self.usernameTextField.endEditing(true)
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func createAccountPress(_ sender: Any) {
        if(emailTextField.status == .valid){
            return self.jumpToCreatingAccount()
        }
        
        let warningPopover = GenericDualAnswerUIPopover()
        warningPopover.initialTitle = String.localize("WARNING")
        warningPopover.attributedMessage = self.buildWarningString()
        warningPopover.leftOption = String.localize("CANCEL")
        warningPopover.rightOption = String.localize("CONTINUE")
        warningPopover.onResponse = { [weak self] confirm in
            guard confirm else {
                return
            }
            self?.jumpToCreatingAccount()
        }
        self.presentPopover(popover: warningPopover, height: 215)
    }
    
    func jumpToCreatingAccount(){
        let username = usernameTextField.text!.lowercased()
        let fullname = fullnameTextField.text!
        let password = passwordTextField.text!
        let email = emailTextField.text
        let signupData = SignUpData(username: username, password: password, fullname: fullname, optionalEmail: email)
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "creatingaccountview") as! CreatingAccountViewController
        controller.signupData = signupData
        controller.fromSignup = true
        controller.multipleAccount = self.multipleAccount
        self.present(controller, animated: true, completion: nil)
    }
    
    func labelInit(){
        let boldText  = String.localize("TERMS_CONDITIONS")
        let attrs = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.white]
        let attributedString = NSMutableAttributedString(string:boldText, attributes:attrs)
        
        let normalText = String.localize("ACCEPT_TERMS")
        let normalAttrs = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.white]
        let normalString = NSMutableAttributedString(string:normalText, attributes: normalAttrs)
        
        normalString.append(attributedString)
        
        termsConditionsLabel.setAttributedTitle(normalString, for: .normal)
    }
    
    func buildWarningString() -> NSMutableAttributedString{
        let normalAttrs = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.black]
        let boldAttrs = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.black]
        
        let boldText  = String.localize("WARNING_RECOVERY_2")
        let boldString = NSMutableAttributedString(string:boldText, attributes:boldAttrs)
        
        let textPart1 = String.localize("WARNING_RECOVERY_1")
        let stringPart1 = NSMutableAttributedString(string:textPart1, attributes: normalAttrs)
        
        let textPart2 = String.localize("WARNING_RECOVERY_3")
        let stringPart2 = NSMutableAttributedString(string:textPart2, attributes: normalAttrs)
        
        boldString.append(stringPart2)
        stringPart1.append(boldString)
        
        return stringPart1
    }
    
    func fieldsInit(){
        usernameMark.isHidden = true
        fullnameMark.isHidden = true
        passwordMark.isHidden = true
        confirmPasswordMark.isHidden = true
        emailMark.isHidden = true
        
        usernameTextField.placeholderAnimation = .hidden
        fullnameTextField.placeholderAnimation = .hidden
        passwordTextField.placeholderAnimation = .hidden
        confirmPasswordTextField.placeholderAnimation = .hidden
        emailTextField.placeholderAnimation = .hidden
    }
    
    func checkToEnableDisableCreateButton(){
        createAccountButton.isEnabled = (usernameTextField.isValid && fullnameTextField.isValid && passwordTextField.isValid && confirmPasswordTextField.isValid && emailTextField.isNotInvalid)
        if(createAccountButton.isEnabled){
            createAccountButton.alpha = 1.0
        }else{
            createAccountButton.alpha = 0.5
        }
    }
}
