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
    
    
    @IBAction func emailInputEditStart(_ sender: Any) {
        markInput(emailMark, MARK_NONE)
    }
    
    @IBAction func emailInputEditEnd(_ sender: Any) {
        if(emailInput.text == ""){
            setInputError(emailInput, "please enter your username")
            return markInput(emailMark, MARK_ERROR)
        }
        setInputError(emailInput, "")
        return markInput(emailMark, MARK_SUCCESS)
    }
    
    @IBAction func nameInputEditStart(_ sender: Any) {
        markInput(fullnameMark, MARK_NONE)
    }
    
    @IBAction func nameInputEditEnd(_ sender: Any) {
        if(fullnameInput.text == ""){
            setInputError(fullnameInput, "please enter your name")
            return markInput(fullnameMark, MARK_ERROR)
        }
        setInputError(fullnameInput, "")
        return markInput(fullnameMark, MARK_SUCCESS)
    }
    
    @IBAction func passwordInputEditStart(_ sender: Any) {
        markInput(passwordMark, MARK_NONE)
    }
    
    @IBAction func passwordInputEditEnd(_ sender: Any) {
        if((passwordInput.text?.count)! < 6){
            setInputError(passwordInput, "password must be at least 6 characters")
            return markInput(passwordMark, MARK_ERROR)
        }
        setInputError(passwordInput, "")
        return markInput(passwordMark, MARK_SUCCESS)
    }
    
    @IBAction func confirmInputEditStart(_ sender: Any) {
        markInput(confirmPasswordMark, MARK_NONE)
    }
    
    @IBAction func confirmInputEditEnd(_ sender: Any) {
        if(confirmPasswordInput.text == ""){
            return
        }else if(confirmPasswordInput.text != passwordInput.text){
            setInputError(confirmPasswordInput, "Passwords don't match")
            return markInput(confirmPasswordMark, MARK_ERROR)
        }
        setInputError(confirmPasswordInput, "")
        return markInput(confirmPasswordMark, MARK_SUCCESS)
    }
    
    @IBAction func optionalInputEditStart(_ sender: Any) {
        markInput(optionalEmailMark, MARK_NONE)
    }
    
    @IBAction func optionalInputEditEnd(_ sender: Any) {
        if(optionalEmailInput.text == ""){
            return markInput(optionalEmailMark, MARK_ERROR)
        }
        return markInput(optionalEmailMark, MARK_SUCCESS)
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
