//
//  ChangePassViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class ChangePassViewController: UIViewController {
    
    var myAccount: Account!
    @IBOutlet weak var forgotButton: UIButton!
    @IBOutlet weak var oldPassTextField: TextField!
    @IBOutlet weak var newPassTextField: TextField!
    @IBOutlet weak var confirmPassTextField: TextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var saveLoader: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.isEnabled = false
        saveButton.alpha = 0.6
        saveLoader.isHidden = true
        oldPassTextField.rightViewMode = .always
        newPassTextField.rightViewMode = .always
        confirmPassTextField.rightViewMode = .always
        oldPassTextField.dividerActiveColor = .mainUI
        newPassTextField.dividerActiveColor = .mainUI
        confirmPassTextField.dividerActiveColor = .mainUI
        oldPassTextField.detailColor = .alert
        newPassTextField.detailColor = .alert
        confirmPassTextField.detailColor = .alert
        oldPassTextField.rightView?.contentScaleFactor = 0.8
        oldPassTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        newPassTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        confirmPassTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        
        navigationItem.title = "Change Password"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        oldPassTextField.becomeFirstResponder()
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onForgotPress(_ sender: Any) {
        sendResetLink()
    }
    
    func sendResetLink(){
        forgotButton.isEnabled = false
        let username = myAccount.username
        APIManager.resetPassword(username: username) { (responseData) in
            self.forgotButton.isEnabled = true
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.presentResetAlert(title: "Request Error", message: error.description)
                return
            }
            guard case let .SuccessDictionary(data) = responseData,
                let email = data["address"] as? String else {
                    self.presentResetAlert(title: "Request Error", message: "A recovery email address has not been set up or confirmed for this account, without it you cannot reset the password")
                    return
            }
            self.presentResetAlert(title: "Reset Password", message: "An email was sent to \(Utils.maskEmailAddress(email: email)) with the instructions to reset your password.")
        }
    }
    
    func presentResetAlert(title: String, message: String){
        let alertVC = GenericAlertUIPopover()
        alertVC.myTitle = title
        alertVC.myMessage = message
        self.presentPopover(popover: alertVC, height: 220)
    }
    
    @IBAction func onTextFieldChange(_ sender: TextField) {
        switch(sender){
        case oldPassTextField:
            guard oldPassTextField.text!.count > 7 else {
                setValidField(oldPassTextField, valid: false, error: "must be 8 characters long")
                break
            }
            setValidField(oldPassTextField, valid: true)
        case newPassTextField, confirmPassTextField:
            guard newPassTextField.text!.count > 7 else {
                setValidField(newPassTextField, valid: false, error: "must be 8 characters long")
                break
            }
            setValidField(newPassTextField, valid: true)
            guard confirmPassTextField.text == newPassTextField.text else {
                setValidField(confirmPassTextField, valid: false, error: "Passwords must match!")
                break
            }
            setValidField(confirmPassTextField, valid: true)
        default:
            break
        }
        
        saveButton.isEnabled = validateForm()
        saveButton.alpha = saveButton.isEnabled ? 1.0 : 0.6
    }
    
    @IBAction func didEndOnExit(_ sender: Any) {
        onDonePress(sender)
    }
    
    @objc func onDonePress(_ sender: Any){
        switch(sender as? TextField){
        case oldPassTextField:
            newPassTextField.becomeFirstResponder()
            break
        case newPassTextField:
            confirmPassTextField.becomeFirstResponder()
            break
        default:
            if(saveButton.isEnabled){
                onSavePress(sender)
            }
        }
    }
    
    func validateForm() -> Bool {
        return oldPassTextField.text!.count > 7 && newPassTextField.text!.count > 7 && newPassTextField.text! == confirmPassTextField.text!
    }
    
    func setValidField(_ field: TextField, valid: Bool, error: String = "") {
        field.detail = error
        field.dividerActiveColor = valid ? .mainUI : .alertLight
    }
    
    @IBAction func onSavePress(_ sender: Any) {
        guard let oldPass = oldPassTextField.text,
            let newPass = newPassTextField.text else {
                return
        }
        showLoader(true)
        APIManager.changePassword(oldPassword: oldPass.sha256()!, newPassword: newPass.sha256()!, token: myAccount.jwt) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            guard case .Success = responseData else {
                self.showLoader(false)
                self.presentResetAlert(title: "Request Error", message: "Unable to change password. Please verify that your password is correct!")
                return
            }
            self.goBack()
        }
    }
    
    func showLoader(_ show: Bool){
        oldPassTextField.isEnabled = !show
        newPassTextField.isEnabled = !show
        confirmPassTextField.isEnabled = !show
        saveLoader.isHidden = !show
        saveButton.isEnabled = !show
        
        guard show else {
            saveLoader.stopAnimating()
            saveButton.setTitle("Save", for: .disabled)
            return
        }
        saveLoader.startAnimating()
        saveButton.setTitle("", for: .disabled)
    }
}

extension ChangePassViewController: LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = myAccount
        self.present(linkDeviceVC, animated: true, completion: nil)
    }
    func onCancelLinkDevice(linkData: LinkData) {
        APIManager.linkDeny(randomId: linkData.randomId, token: myAccount.jwt, completion: {_ in })
    }
}
