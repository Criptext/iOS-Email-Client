//
//  ChangePasswordUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class ChangePasswordUIPopover: BaseUIPopover {
    
    @IBOutlet weak var oldPasswordTextField: TextField!
    @IBOutlet weak var newPasswordTextField: TextField!
    @IBOutlet weak var confirmPasswordTextField: TextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var errorLabel: UILabel!
    var myAccount: Account!
    var onSuccess: (() -> Void)?
    
    init(){
        super.init("ChangePasswordUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader.isHidden = true
        errorLabel.isHidden = true
        oldPasswordTextField.isVisibilityIconButtonEnabled = true
        newPasswordTextField.isVisibilityIconButtonEnabled = true
        confirmPasswordTextField.isVisibilityIconButtonEnabled = true
        oldPasswordTextField.detailColor = .alert
        newPasswordTextField.detailColor = .alert
        confirmPasswordTextField.detailColor = .alert
        oldPasswordTextField.becomeFirstResponder()
        
        oldPasswordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        newPasswordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        confirmPasswordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
    }
    
    @objc func onDonePress(_ sender: Any){
        switch(sender as? TextField){
        case oldPasswordTextField:
            newPasswordTextField.becomeFirstResponder()
            break
        case newPasswordTextField:
            confirmPasswordTextField.becomeFirstResponder()
            break
        default:
            if(saveButton.isEnabled){
                onSavePress(sender)
            }
        }
    }
    
    @IBAction func onDidEndOnExit(_ sender: Any) {
        onDonePress(sender)
    }
    
    @IBAction func onTextFieldChange(_ sender: TextField) {
        errorLabel.isHidden = true
        switch(sender){
        case oldPasswordTextField:
            guard oldPasswordTextField.text!.count > 7 else {
                setValidField(oldPasswordTextField, valid: false, error: "Password must be 8 characters long")
                break
            }
            setValidField(oldPasswordTextField, valid: true)
        case newPasswordTextField, confirmPasswordTextField:
            guard newPasswordTextField.text!.count > 7 else {
                setValidField(newPasswordTextField, valid: false, error: "Password must be 8 characters long")
                break
            }
            setValidField(newPasswordTextField, valid: true)
            guard confirmPasswordTextField.text == newPasswordTextField.text else {
                setValidField(confirmPasswordTextField, valid: false, error: "Passwords must match!")
                break
            }
            setValidField(confirmPasswordTextField, valid: true)
        default:
            break
        }
        
        saveButton.isEnabled = validateForm()
    }
    
    func setValidField(_ field: TextField, valid: Bool, error: String = "") {
        field.detail = error
        field.dividerActiveColor = valid ? .mainUI : .alertLight
    }
    
    func validateForm() -> Bool {
        return oldPasswordTextField.text!.count > 7 && newPasswordTextField.text!.count > 7 && newPasswordTextField.text! == confirmPasswordTextField.text!
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onSavePress(_ sender: Any) {
        guard let oldPass = oldPasswordTextField.text,
            let newPass = newPasswordTextField.text else {
                return
        }
        showLoader(true)
        errorLabel.isHidden = true
        APIManager.changePassword(oldPassword: oldPass.sha256()!, newPassword: newPass.sha256()!, token: myAccount.jwt) { (error) in
            guard error == nil else {
                self.showLoader(false)
                self.errorLabel.isHidden = false
                self.errorLabel.text = "Unable to change password"
                return
            }
            self.dismiss(animated: true, completion: {
                self.onSuccess?()
            })
        }
    }
    
    func showLoader(_ show: Bool){
        oldPasswordTextField.isEnabled = !show
        newPasswordTextField.isEnabled = !show
        confirmPasswordTextField.isEnabled = !show
        shouldDismiss = !show
        loader.isHidden = !show
        cancelButton.isEnabled = !show
        saveButton.isEnabled = !show
        
        guard show else {
            loader.stopAnimating()
            cancelButton.setTitle("Cancel", for: .normal)
            saveButton.setTitle("Save", for: .disabled)
            return
        }
        loader.startAnimating()
        cancelButton.setTitle("", for: .normal)
        saveButton.setTitle("", for: .disabled)
    }
}
