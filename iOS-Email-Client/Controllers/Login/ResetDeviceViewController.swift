//
//  ResetDeviceViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/15/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class ResetDeviceViewController: UIViewController{

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var errorMark: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var resetLoaderView: UIActivityIndicatorView!
    var loginData: LoginData!
    var failed = false
    
    override func viewDidLoad() {
        emailLabel.text = loginData.email
        resetLoaderView.isHidden = true
        showFeedback(false)
        checkToEnableDisableResetButton()
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        passwordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        passwordTextField.becomeFirstResponder()
    }
    
    @objc func onDonePress(_ sender: Any){
        if(resetButton.isEnabled){
            self.onResetPress(sender)
        }
    }
    
    @objc func hideKeyboard(){
        self.passwordTextField.endEditing(true)
    }
    
    @IBAction func onPasswordChange(_ sender: Any) {
        showFeedback(false)
        checkToEnableDisableResetButton()
    }
    
    @IBAction func onResetPress(_ sender: Any) {
        guard let password = passwordTextField.text else {
            return
        }
        showLoader(true)
        let email = loginData.email
        let username = String(email.split(separator: "@")[0])
        APIManager.loginRequest(username, password) { (responseError, responseData) in
            self.showLoader(false)
            if let error = responseError {
                self.showFeedback(true, error.localizedDescription)
                return
            }
            guard let data = responseData else {
                self.showFeedback(true, "Unable to sign-in. Please try again.")
                return
            }
            let name = data["name"] as! String
            let deviceId = data["deviceId"] as! Int
            let token = data["token"] as! String
            let signupData = SignUpData(username: username, password: password, fullname: name, optionalEmail: nil)
            signupData.deviceId = deviceId
            signupData.token = token
            self.jumpToCreatingAccount(signupData: signupData)
        }
    }
    
    @IBAction func textfieldDidEndOnExit(_ sender: Any) {
        if(resetButton.isEnabled){
            self.onResetPress(sender)
        }
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func checkToEnableDisableResetButton(){
        let textCount = passwordTextField.text?.count ?? 0
        resetButton.isEnabled = !(passwordTextField.isEmpty || textCount < Constants.MinCharactersPassword) && resetLoaderView.isHidden
        resetButton.setTitle(resetLoaderView.isHidden ? "Reset" : "", for: .normal)
        if(resetButton.isEnabled){
            resetButton.alpha = 1.0
        }else{
            resetButton.alpha = 0.5
        }
    }
    
    func showFeedback(_ show: Bool, _ message: String? = nil){
        errorMark.isHidden = !show
        errorLabel.isHidden = !show
        errorLabel.text = message ?? ""
    }
    
    func jumpToCreatingAccount(signupData: SignUpData){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "creatingaccountview") as! CreatingAccountViewController
        controller.signupData = signupData
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
