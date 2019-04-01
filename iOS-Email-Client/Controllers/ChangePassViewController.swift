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
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var newLabel: UILabel!
    @IBOutlet weak var saveLoader: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveButton.isEnabled = false
        saveButton.alpha = 0.6
        saveLoader.isHidden = true
        oldPassTextField.rightViewMode = .always
        newPassTextField.rightViewMode = .always
        confirmPassTextField.rightViewMode = .always
        oldPassTextField.rightView?.contentScaleFactor = 0.8
        oldPassTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        newPassTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        confirmPassTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        navigationItem.title = String.localize("CHANGE_PASS_TITLE")
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        oldPassTextField.becomeFirstResponder()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        self.view.backgroundColor = theme.overallBackground
        oldPassTextField.textColor = theme.mainText
        newPassTextField.textColor = theme.mainText
        confirmPassTextField.textColor = theme.mainText
        currentLabel.textColor = theme.mainText
        newLabel.textColor = theme.mainText
        
        oldPassTextField.attributedPlaceholder = NSAttributedString(string: String.localize("ENTER_OLD_PASS"), attributes: [.foregroundColor: theme.placeholder, .font: Font.regular.size(oldPassTextField.minimumFontSize)!])
        oldPassTextField.visibilityIconButton?.tintColor = theme.placeholder
        newPassTextField.attributedPlaceholder = NSAttributedString(string: String.localize("ENTER_NEW_PASS"), attributes: [.foregroundColor: theme.placeholder, .font: Font.regular.size(newPassTextField.minimumFontSize)!])
        newPassTextField.visibilityIconButton?.tintColor = theme.placeholder
        confirmPassTextField.attributedPlaceholder = NSAttributedString(string: String.localize("CONFIRM_NEW_PASS"), attributes: [.foregroundColor: theme.placeholder, .font: Font.regular.size(confirmPassTextField.minimumFontSize)!])
        confirmPassTextField.visibilityIconButton?.tintColor = theme.placeholder
        
        saveButton.backgroundColor = theme.criptextBlue
        forgotButton.setTitleColor(theme.criptextBlue, for: .normal)
        oldPassTextField.dividerActiveColor = theme.criptextBlue
        newPassTextField.dividerActiveColor = theme.criptextBlue
        confirmPassTextField.dividerActiveColor = theme.criptextBlue
        oldPassTextField.detailColor = theme.alert
        newPassTextField.detailColor = theme.alert
        confirmPassTextField.detailColor = theme.alert
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
                self.presentResetAlert(title: String.localize("REQUEST_ERROR"), message: error.description)
                return
            }
            guard case let .SuccessDictionary(data) = responseData,
                let email = data["address"] as? String else {
                    self.presentResetAlert(title: String.localize("REQUEST_ERROR"), message: String.localize("RECOVERY_NOT_SET_RESET"))
                    return
            }
            self.presentResetAlert(title: String.localize("RESET_PASSWORD"), message: String.localize("EMAIL_INSTRUCTIONS", arguments: Utils.maskEmailAddress(email: email)))
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
                setValidField(oldPassTextField, valid: false, error: String.localize("8_CHARS"))
                break
            }
            setValidField(oldPassTextField, valid: true)
        case newPassTextField, confirmPassTextField:
            guard newPassTextField.text!.count > 7 else {
                setValidField(newPassTextField, valid: false, error: String.localize("8_CHARS"))
                break
            }
            setValidField(newPassTextField, valid: true)
            guard confirmPassTextField.text == newPassTextField.text else {
                setValidField(confirmPassTextField, valid: false, error: String.localize("PASS_MATCH"))
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
        field.dividerActiveColor = valid ? .mainUI : .alert
    }
    
    @IBAction func onSavePress(_ sender: Any) {
        guard let oldPass = oldPassTextField.text,
            let newPass = newPassTextField.text else {
                return
        }
        showLoader(true)
        APIManager.changePassword(oldPassword: oldPass.sha256()!, newPassword: newPass.sha256()!, account: myAccount) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout(account: self.myAccount)
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.presentResetAlert(title: String.localize("REQUEST_ERROR"), message: error.description)
                return
            }
            guard case .Success = responseData else {
                self.showLoader(false)
                self.presentResetAlert(title: String.localize("REQUEST_ERROR"), message: String.localize("UNABLE_CHANGE_PASS"))
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
            saveButton.setTitle(String.localize("SAVE"), for: .disabled)
            return
        }
        saveLoader.startAnimating()
        saveButton.setTitle("", for: .disabled)
    }
}

extension ChangePassViewController: LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData) {
        guard linkData.version == Env.linkVersion else {
            let popover = GenericAlertUIPopover()
            popover.myTitle = String.localize("VERSION_TITLE")
            popover.myMessage = String.localize("VERSION_MISMATCH")
            self.presentPopover(popover: popover, height: 220)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = myAccount
        self.present(linkDeviceVC, animated: true, completion: nil)
    }
    func onCancelLinkDevice(linkData: LinkData) {
        if case .sync = linkData.kind {
            APIManager.syncDeny(randomId: linkData.randomId, account: myAccount, completion: {_ in })
        } else {
            APIManager.linkDeny(randomId: linkData.randomId, account: myAccount, completion: {_ in })
        }
    }
}

extension ChangePassViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}
