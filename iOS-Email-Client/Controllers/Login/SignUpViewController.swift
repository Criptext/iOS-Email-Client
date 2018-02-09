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
    let MARK_ERROR = -1
    let MARK_SUCCESS = 1
    let MARK_NONE = 0
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var termsConditionsLabel: UIButton!
    @IBOutlet weak var createAccountButton: UIButton!
    
    @IBOutlet weak var emailInput: TextField!
    @IBOutlet weak var fullnameInput: TextField!
    @IBOutlet weak var optionalEmailInput: TextField!
    @IBOutlet weak var confirmPasswordInput: TextField!
    @IBOutlet weak var passwordInput: TextField!
    
    @IBOutlet weak var emailMark: UIImageView!
    @IBOutlet weak var fullnameMark: UIImageView!
    @IBOutlet weak var passwordMark: UIImageView!
    @IBOutlet weak var confirmPasswordMark: UIImageView!
    @IBOutlet weak var optionalEmailMark: UIImageView!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        backButtonInit()
        labelInit()
        createButtonInit()
        fieldsInit()
        
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @IBAction func inputEditStart(_ sender: TextField){
        guard let markView = mapInputToMark(sender) else {return}
        markInput(markView , MARK_NONE)
    }
    
    @IBAction func inputEditEnd(_ sender: TextField){
        guard let markView = mapInputToMark(sender) else {return}
        let inputError = getInputError(sender)
        setInputError(sender, inputError)
        if(inputError.isEmpty){
            return markInput(markView, MARK_SUCCESS)
        }
        markInput(markView , MARK_ERROR)
    }
    
    func mapInputToMark(_ textfield: TextField) -> UIImageView?{
        switch (textfield){
        case emailInput: return emailMark
        case fullnameInput: return fullnameMark
        case passwordInput: return passwordMark
        case confirmPasswordInput: return confirmPasswordMark
        case optionalEmailInput: return optionalEmailMark
        default: return nil
        }
    }
    
    func getInputError(_ textfield: TextField) -> String {
        switch(textfield){
        case emailInput:
            if(emailInput.isEmpty){
                return "please enter your username"
            }
            break
        case fullnameInput:
            if(fullnameInput.isEmpty){
                return "please enter your name"
            }
            break
        case passwordInput:
            if((passwordInput.text?.count)! < 6){
                return "password must be at least 6 characters"
            }
            break
        case confirmPasswordInput:
            if((confirmPasswordInput.text?.count)! < 6){
                return "password must be at least 6 characters"
            }else if(confirmPasswordInput.text != passwordInput.text){
                return "Passwords don't match"
            }
            break
        case emailInput:
            if(emailInput.isEmpty){
                return "please enter your username"
            }
            break
        default: return ""
        }
        return ""
    }
    
    func markInput(_ markView : UIImageView, _ status: Int){
        switch(status){
        case 1:
            markView.image = UIImage(named: "mark-success")
            markView.isHidden = false;
            markView.tintColor = UIColor.white
            break
        case -1:
            markView.image = UIImage(named: "mark-error")
            markView.tintColor = UIColor.black
            markView.isHidden = false;
            break
        default:
            markView.isHidden = true
        }
    }
    
    func setInputError(_ input : TextField, _ error : String){
        input.detail = error
        if(error != ""){
            input.dividerNormalColor = UIColor.black
            return
        }
        input.dividerNormalColor = UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
    }
    
    @objc func hideKeyboard(){
        self.fullnameInput.endEditing(true)
        self.passwordInput.endEditing(true)
        self.confirmPasswordInput.endEditing(true)
        self.optionalEmailInput.endEditing(true)
        self.emailInput.endEditing(true)
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func termsConditionsPress(_ sender: Any) {
        if let url = URL(string: "https://criptext.com") {
            UIApplication.shared.open(url, options: [:])
        }
    }
    
    @IBAction func createAccountPress(_ sender: Any) {
        if(self.optionalEmailInput.text != ""){
            return self.jumpToCreatingAccount()
        }
        
        let alert = UIAlertController(title: "Warning", message: "", preferredStyle: .alert)
        let proceedAction = UIAlertAction(title: "Confirm", style: .default){ (alert : UIAlertAction!) -> Void in
            self.jumpToCreatingAccount()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel){ (alert : UIAlertAction!) -> Void in
        }
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
        emailMark.isHidden = true
        fullnameMark.isHidden = true
        passwordMark.isHidden = true
        confirmPasswordMark.isHidden = true
        optionalEmailMark.isHidden = true
        
        emailInput.placeholderAnimation = .hidden
        fullnameInput.placeholderAnimation = .hidden
        passwordInput.placeholderAnimation = .hidden
        confirmPasswordInput.placeholderAnimation = .hidden
        optionalEmailInput.placeholderAnimation = .hidden
    }
}
