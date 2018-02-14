//
//  SignUpViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class SignUpViewController: UIViewController{
    
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
    
    override func viewDidLoad(){
        super.viewDidLoad()
        backButtonInit()
        labelInit()
        createButtonInit()
        fieldsInit()
        
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        
        usernameTextField.markView = usernameMark
        fullnameTextField.markView = fullnameMark
        passwordTextField.markView = passwordMark
        confirmPasswordTextField.markView = confirmPasswordMark
        emailTextField.markView = emailMark
        enableCreateAccountButton()
    }
    
    @IBAction func inputEditEnd(_ sender: TextField){
        switch(sender){
        case usernameTextField:
            checkUsername()
            break
        case fullnameTextField:
            checkFullname()
            break
        case passwordTextField:
            checkPassword()
            break
        case confirmPasswordTextField:
            checkConfirmPassword()
            break
        case emailTextField:
            checkOptionalEmail()
            break
        default: return
        }
        enableCreateAccountButton()
    }
    
    func mapInputToMark(_ textfield: TextField) -> UIImageView?{
        switch (textfield){
        case usernameTextField: return usernameMark
        case fullnameTextField: return fullnameMark
        case passwordTextField: return passwordMark
        case confirmPasswordTextField: return confirmPasswordMark
        case emailTextField: return emailMark
        default: return nil
        }
    }
    
    func checkUsername(){
        if(usernameTextField.isEmpty){
            let inputError = "please enter your username"
            usernameTextField.setStatus(StatusTextField.Status.invalid, inputError)
            return
        }
        usernameTextField.setStatus(StatusTextField.Status.valid)
    }
    
    func checkFullname(){
        if(fullnameTextField.isEmpty){
            let inputError = "please enter your name"
            fullnameTextField.setStatus(StatusTextField.Status.invalid, inputError)
            return
        }
        fullnameTextField.setStatus(StatusTextField.Status.valid)
    }
    
    func checkPassword(){
        if(passwordTextField.text!.count < 6){
            let inputError = "password must be at least 6 characters"
            passwordTextField.setStatus(StatusTextField.Status.invalid, inputError)
            return
        }
        passwordTextField.setStatus(StatusTextField.Status.valid)
        if(confirmPasswordTextField.text != "" && confirmPasswordTextField.text != passwordTextField.text){
            let inputError = "Passwords don't match"
            confirmPasswordTextField.setStatus(StatusTextField.Status.invalid, inputError)
        }else if(confirmPasswordTextField.text != "" && confirmPasswordTextField.text == passwordTextField.text){
            confirmPasswordTextField.setStatus(StatusTextField.Status.valid)
        }
        
    }
    
    func checkConfirmPassword(){
        if(passwordTextField.text != "" && confirmPasswordTextField.text != passwordTextField.text){
            let inputError = "Passwords don't match"
            confirmPasswordTextField.setStatus(StatusTextField.Status.invalid, inputError)
            return
        }else if(passwordTextField.text != "" && confirmPasswordTextField.text == passwordTextField.text){
            confirmPasswordTextField.setStatus(StatusTextField.Status.valid)
            return
        }
        confirmPasswordTextField.setStatus(StatusTextField.Status.none)
    }
    
    func checkOptionalEmail(){
        if(emailTextField.text != "" && !isValidEmail(emailTextField.text!)){
            let inputError = "this is not a valid email"
            emailTextField.setStatus(StatusTextField.Status.invalid, inputError)
            return
        }else if(emailTextField.text != ""){
            emailTextField.setStatus(StatusTextField.Status.valid)
            return
        }
        emailTextField.setStatus(StatusTextField.Status.none)
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
    
    @IBAction func termsConditionsPress(_ sender: Any) {
        /*if let url = URL(string: "https://criptext.com") {
            UIApplication.shared.open(url, options: [:])
        }*/
    }
    
    @IBAction func createAccountPress(_ sender: Any) {
        if(emailTextField.status == .valid){
            return self.jumpToCreatingAccount()
        }
        
        let alert = UIAlertController(title: "Warning", message: "", preferredStyle: .alert)
        let proceedAction = UIAlertAction(title: "Confirm", style: .default){ (alert : UIAlertAction!) -> Void in
            self.jumpToCreatingAccount()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(proceedAction)
        alert.addAction(cancelAction)
        alert.setValue(self.buildWarningString(), forKey: "attributedMessage")
        self.present(alert, animated: true, completion: nil)
    }
    
    func jumpToCreatingAccount(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "creatingaccountview")
        self.present(controller, animated: true, completion: nil)
    }
    
    func labelInit(){
        let boldText  = "Terms and Conditions"
        let attrs = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.white]
        let attributedString = NSMutableAttributedString(string:boldText, attributes:attrs)
        
        let normalText = "By clicking create account, you agree to our "
        let normalAttrs = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.white]
        let normalString = NSMutableAttributedString(string:normalText, attributes: normalAttrs)
        
        normalString.append(attributedString)
        
        termsConditionsLabel.setAttributedTitle(normalString, for: .normal)
    }
    
    func buildWarningString() -> NSMutableAttributedString{
        let normalAttrs = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.black]
        let boldAttrs = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 14), NSAttributedStringKey.foregroundColor : UIColor.black]
        
        let boldText  = " Recovery Email "
        let boldString = NSMutableAttributedString(string:boldText, attributes:boldAttrs)
        
        let textPart1 = "\nYou did not set a"
        let stringPart1 = NSMutableAttributedString(string:textPart1, attributes: normalAttrs)
        
        let textPart2 = "so account recovery is imposible if you forget your password. \n\nProceed without recovery email?"
        let stringPart2 = NSMutableAttributedString(string:textPart2, attributes: normalAttrs)
        
        boldString.append(stringPart2)
        stringPart1.append(boldString)
        
        return stringPart1
    }
    
    func createButtonInit(){
        createAccountButton.clipsToBounds = true
        createAccountButton.layer.cornerRadius = 20
    }
    
    func backButtonInit(){
        backButton.clipsToBounds = true
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        backButton.layer.masksToBounds = false
        backButton.layer.shadowRadius = 1.0
        backButton.layer.shadowOpacity = 0.11
        backButton.layer.cornerRadius = backButton.frame.width / 2
        backButton.imageView?.contentMode = .scaleAspectFit
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
    
    func isValidEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
    
    func enableCreateAccountButton(){
        createAccountButton.isEnabled = (usernameTextField.isValid && fullnameTextField.isValid && passwordTextField.isValid && confirmPasswordTextField.isValid && emailTextField.isNotInvalid)
        if(createAccountButton.isEnabled){
            createAccountButton.backgroundColor = UIColor(red: 55/255, green: 58/255, blue: 69/255, alpha: 1.0)
        }else{
            createAccountButton.backgroundColor = UIColor(red: 55/255, green: 58/255, blue: 69/255, alpha: 0.5)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "signuptowebview"){
            let webviewController = segue.destination as! WebViewViewController
            webviewController.url = "https://criptext.com"
        }
    }
}
