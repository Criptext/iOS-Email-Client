//
//  EmailSetPasswordViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 6/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material
import IQKeyboardManagerSwift

protocol EmailSetPasswordDelegate {
    func setPassword(active: Bool, password: String?)
}

class EmailSetPasswordViewController: BaseUIPopover {
    let MIN_PASS_LENGTH = 3
    
    @IBOutlet weak var popoverView: UIView!
    @IBOutlet weak var passphraseLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var noPasswordMessageLabel: UILabel!
    @IBOutlet weak var passwordContainerView: UIView!
    var isBackup = false
    var onSetPassword: ((Bool, String?) -> Void)?
    var delegate : EmailSetPasswordDelegate?
    
    init(){
        super.init("EmailSetPasswordUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        passwordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(sender:)))
        guard let scrollview = self.view as? UIScrollView else {
            return
        }
        scrollview.bounces = false
        scrollview.contentSize = CGSize(width: Constants.popoverWidth, height: 335)
        if isBackup {
            applyBackup()
        } else {
            applyEncrypted()
        }
        applyTheme()
    }
    
    func applyEncrypted() {
        titleLabel.text = String.localize("NON_CRIPTEXT")
        subTitleLabel.text = String.localize("SEND_ENCRYPTED")
        passphraseLabel.text = String.localize("SET_PASSPHRASE")
        noPasswordMessageLabel.text = String.localize("NOTE")
        sendButton.setTitle(String.localize("SEND"), for: .normal)
    }
    
    func applyBackup() {
        titleLabel.text = String.localize("ENTER_PASSPHRASE")
        subTitleLabel.text = String.localize("ENCRYPT_BACKUP")
        passphraseLabel.text = String.localize("LOSE_PASSPHRASE")
        noPasswordMessageLabel.text = String.localize("NOTE_BACKUP")
        sendButton.setTitle(String.localize("CONTINUE"), for: .normal)
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.overallBackground
        popoverView.backgroundColor = theme.overallBackground
        passwordContainerView.backgroundColor = theme.overallBackground
        passwordTextField.detailColor = theme.alert
        passwordTextField.textColor = theme.mainText
        passwordTextField.placeholderLabel.textColor = theme.mainText
        passwordTextField.visibilityIconButton?.tintColor = theme.mainText
        passwordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("Passphrase"), attributes: [NSAttributedString.Key.foregroundColor: theme.placeholder])
        titleLabel.textColor = theme.mainText
        passphraseLabel.textColor = theme.mainText
        subTitleLabel.textColor = theme.mainText
        noPasswordMessageLabel.textColor = theme.mainText
        subTitleLabel.textColor = theme.mainText
        subTitleLabel.textColor = theme.mainText
        sendButton.backgroundColor = theme.popoverButton
        cancelButton.backgroundColor = theme.popoverButton
        sendButton.setTitleColor(theme.mainText, for: .normal)
        cancelButton.setTitleColor(theme.mainText, for: .normal)
    }
    
    @IBAction func onDidEndOnExit(_ sender: Any) {
        onDonePress(sender: sender)
    }
    
    @objc func onDonePress(sender: Any){
        switch(sender as? TextField){
        default:
            onSetPress(sender)
        }
    }
    
    @IBAction func onSetPress(_ sender: Any) {
        let passwordEnabled = passwordTextField.isEnabled
        let password = passwordTextField.text!
        guard (!passwordEnabled || password.count >= MIN_PASS_LENGTH) else {
            passwordTextField.detail = String.localize("AT_LEAST_3_CHARS")
            return
        }
        self.dismiss(animated: true, completion: nil)
        self.delegate?.setPassword(active: passwordEnabled, password: passwordEnabled ? password : nil)
        onSetPassword?(passwordEnabled, passwordEnabled ? password : nil)
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onSwitchToggle(_ sender: UISwitch) {
        passwordTextField.isEnabled = sender.isOn
        passwordContainerView.isHidden = !sender.isOn
        noPasswordMessageLabel.isHidden = sender.isOn
        guard sender.isOn else {
            passwordTextField.detail = ""
            resignKeyboard()
            return
        }
        passwordTextField.becomeFirstResponder()
    }
    
    func resignKeyboard(){
        passwordTextField.resignFirstResponder()
    }
}
