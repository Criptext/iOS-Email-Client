//
//  SignUpNameViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/21/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class SignUpNameViewController: UIViewController{
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var fullnameTextField: StatusTextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    var multipleAccount = false
    var signUpData: TempSignUpData!
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        applyTheme()
        setupField()
        
        signUpData = TempSignUpData()
        
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    func applyTheme() {
        fullnameTextField.tintColor = theme.mainText
        fullnameTextField.textColor = theme.mainText
        fullnameTextField.validDividerColor = theme.criptextBlue
        fullnameTextField.invalidDividerColor = UIColor.red
        fullnameTextField.dividerColor = theme.alert
        fullnameTextField.detailColor = theme.alert
        titleLabel.textColor = theme.mainText
        messageLabel.textColor = theme.secondText
        view.backgroundColor = theme.background
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.setNeedsDisplay()
    }
    
    @objc func hideKeyboard(){
        self.fullnameTextField.endEditing(true)
    }
    
    func setupField(){
        let placeholderAttrs = [.foregroundColor: theme.secondText] as [NSAttributedString.Key: Any]
        
        fullnameTextField.font = Font.regular.size(17.0)
        fullnameTextField.placeholderAnimation = .hidden
        fullnameTextField.attributedPlaceholder = NSAttributedString(string: String.localize("FULLNAME"), attributes: placeholderAttrs)
        fullnameTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        
        titleLabel.text = String.localize("SIGN_UP_NAME_TITLE")
        messageLabel.text = String.localize("SIGN_UP_NAME_MESSAGE")

        fullnameTextField.becomeFirstResponder()
    }
    
    @objc func onDonePress(_ sender: Any){
        guard nextButton.isEnabled else {
            return
        }
        self.onNextPress(sender)
    }
    
    @IBAction func onFullnameChange(_ sender: Any) {
        checkToEnableDisableNextButton()
    }
    
    func checkToEnableDisableNextButton(){
        guard !fullnameTextField.isEmpty else {
            let inputError = String.localize("ENTER_NAME")
            nextButton.isEnabled = false
            nextButton.alpha = 0.5
            fullnameTextField.setStatus(.invalid, inputError)
            return
        }
        guard fullnameTextField.text!.count <= 64 else {
            let inputError = String.localize("ENTER_NAME")
            nextButton.isEnabled = false
            nextButton.alpha = 0.5
            fullnameTextField.setStatus(.invalid, inputError)
            return
        }
        fullnameTextField.setStatus(.valid)
        nextButton.isEnabled = true
        nextButton.alpha = 1.0
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        guard let name = fullnameTextField.text else {
            return
        }
        self.signUpData.fullname = name
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "usernameView")  as! SignUpUserNameViewController
        controller.multipleAccount = self.multipleAccount
        controller.signUpData = self.signUpData
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func textfieldDidEndOnExit(_ sender: Any) {
        guard nextButton.isEnabled else {
            return
        }
        self.onNextPress(sender)
    }
    
    @IBAction func didPressClose(sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension SignUpNameViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension SignUpNameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
