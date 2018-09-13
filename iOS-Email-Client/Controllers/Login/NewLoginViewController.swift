//
//  LoginViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/2/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class NewLoginViewController: UIViewController{
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var usernameTextField: TextField!
    @IBOutlet weak var errorImage: UIImageView!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var loginErrorLabel: UILabel!
    var loggedOutRemotely = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        loginButtonInit()
        usernameTextFieldInit()
        
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        toggleLoadingView(false)
        clearErrors()
        checkToEnableDisableLoginButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if loggedOutRemotely {
            loggedOutRemotely = false
            showAlert("Logged Out!", message: "This device has been removed remotely.", style: .alert)
        }
    }
    
    @objc func hideKeyboard(){
        self.usernameTextField.endEditing(true)
    }
    
    func usernameTextFieldInit(){
        let placeholderAttrs = [.foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)] as [NSAttributedStringKey: Any]
        usernameTextField.placeholderAnimation = .hidden
        usernameTextField.attributedPlaceholder = NSAttributedString(string: "Username", attributes: placeholderAttrs)
        usernameTextField.delegate = self
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.font = Font.regular.size(17.0)
        usernameTextField.textColor = UIColor.white
        usernameTextField.dividerNormalColor = UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
        usernameTextField.dividerActiveColor = UIColor.white
        usernameTextField.placeholderActiveScale = 0
        usernameTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
    }
    
    func loginButtonInit(){
        loginButton.clipsToBounds = true
        loginButton.layer.cornerRadius = 20
        
        let boldText  = "Sign up"
        let attrs = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 17), NSAttributedStringKey.foregroundColor : UIColor.white]
        let attributedString = NSMutableAttributedString(string:boldText, attributes:attrs)
    
        let normalText = "Not registered? "
        let normalAttrs = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17), NSAttributedStringKey.foregroundColor : UIColor.white]
        let normalString = NSMutableAttributedString(string:normalText, attributes: normalAttrs)
    
        normalString.append(attributedString)
        signupButton.setAttributedTitle(normalString, for: .normal)
    }
    
    @objc func onDonePress(_ sender: Any){
        guard loginButton.isEnabled else {
            return
        }
        self.onLoginPress(sender)
    }
    
    func toggleLoadingView(_ show: Bool){
        if(show){
            loginButton.setTitle("", for: .normal)
            loadingView.isHidden = false
            loadingView.startAnimating()
        }else{
            loginButton.setTitle("Sign In", for: .normal)
            loadingView.isHidden = true
            loadingView.stopAnimating()
        }
        checkToEnableDisableLoginButton()
    }
    
    @IBAction func usernameChange(_ sender: Any) {
        checkToEnableDisableLoginButton()
        if(!errorImage.isHidden){
            clearErrors()
        }
    }
    
    func checkToEnableDisableLoginButton(){
        loginButton.isEnabled = !usernameTextField.isEmpty
        if(loginButton.isEnabled && loadingView.isHidden){
            loginButton.alpha = 1.0
        }else{
            loginButton.alpha = 0.5
        }
    }
    
    @IBAction func onLoginPress(_ sender: Any) {
        guard let username = usernameTextField.text?.lowercased() else {
            return
        }
        toggleLoadingView(true)
        APIManager.checkAvailableUsername(username) { (responseData) in
            guard case let .Error(error) = responseData else {
                self.showLoginError(error: "Username does not exist")
                return
            }
            guard error.code == .custom else {
                self.showLoginError(error: error.description)
                return
            }
            self.jumpToLoginDeviceView()
        }
        
    }
    
    @IBAction func textfieldDidEndOnExit(_ sender: Any) {
        guard loginButton.isEnabled else {
            return
        }
        self.onLoginPress(sender)
    }
    
    func showLoginError(error: String){
        self.setLoginError(error)
        self.toggleLoadingView(false)
    }
    
    func jumpToLoginDeviceView(){
        let email = usernameTextField.text!.lowercased() + Constants.domain
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "resetdeviceview")  as! ResetDeviceViewController
        controller.loginData = LoginData(email)
        navigationController?.pushViewController(controller, animated: true)
        
        toggleLoadingView(false)
        clearErrors()
    }
    
    func setLoginError(_ message: String){
        errorImage.isHidden = false
        loginErrorLabel.isHidden = false
        loginErrorLabel.text = message
    }
    
    func clearErrors(){
        errorImage.isHidden = true
        loginErrorLabel.isHidden = true
    }
}

extension NewLoginViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension NewLoginViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
