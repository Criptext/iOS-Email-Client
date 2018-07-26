//
//  EmailSetPasswordViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 6/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

protocol EmailSetPasswordDelegate {
    func setPassword(active: Bool, password: String)
}

class EmailSetPasswordViewController: BaseUIPopover {
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var repeatPasswordTextField: TextField!
    @IBOutlet weak var noPasswordMessageLabel: UILabel!
    @IBOutlet weak var passwordContainerView: UIView!
    var delegate : EmailSetPasswordDelegate?
    
    init(){
        super.init("EmailSetPasswordUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        passwordTextField.detailColor = .alert
        repeatPasswordTextField.detailColor = .alert
        
        passwordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(sender:)))
        repeatPasswordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(sender:)))
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)){ [weak self] in
            self?.passwordTextField.becomeFirstResponder()
        }
        guard let scrollview = self.view as? UIScrollView else {
            return
        }
        scrollview.bounces = false
        scrollview.contentSize = CGSize(width: Constants.popoverWidth, height: 406)
    }
    
    @IBAction func onDidEndOnExit(_ sender: Any) {
        onDonePress(sender: sender)
    }
    
    @objc func onDonePress(sender: Any){
        switch(sender as? TextField){
        case passwordTextField:
            repeatPasswordTextField.becomeFirstResponder()
            break
        default:
            onSetPress(sender)
        }
    }
    
    @IBAction func onSetPress(_ sender: Any) {
        guard let password = passwordTextField.text,
            (!passwordTextField.isEnabled || passwordTextField.text == repeatPasswordTextField.text) else {
            repeatPasswordTextField.detail = "Passwords don’t match"
            return
        }
        self.dismiss(animated: true, completion: nil)
        self.delegate?.setPassword(active: passwordTextField.isEnabled, password: password)
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onSwitchToggle(_ sender: UISwitch) {
        passwordTextField.isEnabled = sender.isOn
        repeatPasswordTextField.isEnabled = sender.isOn
        passwordContainerView.isHidden = !sender.isOn
        noPasswordMessageLabel.isHidden = sender.isOn
        guard sender.isOn else {
            repeatPasswordTextField.detail = ""
            resignKeyboard()
            return
        }
        passwordTextField.becomeFirstResponder()
    }
    
    func resignKeyboard(){
        passwordTextField.resignFirstResponder()
        repeatPasswordTextField.resignFirstResponder()
    }
}
