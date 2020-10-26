//
//  SignUpPasswordViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/21/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class SignUpPasswordViewController: UIViewController{
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var conditionOne: UILabel!
    @IBOutlet weak var conditionTwo: UILabel!
    @IBOutlet weak var passwordTextField: StatusTextField!
    @IBOutlet weak var titleLabel: UILabel!
    var signUpData: TempSignUpData!
    var multipleAccount = false
    let signUpValidator = ValidateString.signUp
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        applyTheme()
        setupField()
        
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    func applyTheme() {
        passwordTextField.textColor = theme.mainText
        passwordTextField.validDividerColor = theme.criptextBlue
        passwordTextField.invalidDividerColor = UIColor.red
        passwordTextField.dividerColor = theme.criptextBlue
        passwordTextField.detailColor = UIColor.red
        titleLabel.textColor = theme.mainText
        conditionOne.textColor = theme.secondText
        conditionTwo.textColor = theme.secondText
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
        self.passwordTextField.endEditing(true)
    }
    
    func checkFirstCondition() -> Bool {
        guard let password = passwordTextField.text else {
            self.setConditionState(isCorrect: nil, text: String.localize("SIGN_UP_PASS_SAME_USERNAME"), conditionLabel: self.conditionOne)
            return false
        }
        if password == self.signUpData.username {
            self.setConditionState(isCorrect: false, text: String.localize("SIGN_UP_PASS_SAME_USERNAME"), conditionLabel: self.conditionOne)
            return false
        }
        self.setConditionState(isCorrect: true, text: String.localize("SIGN_UP_PASS_SAME_USERNAME"), conditionLabel: self.conditionOne)
        return true
    }
    
    func checkSecondCondition() -> Bool {
        guard let password = passwordTextField.text else {
            self.setConditionState(isCorrect: nil, text: String.localize("SIGN_UP_PASS_LENGTH"), conditionLabel: self.conditionTwo)
            return false
        }
        if (password.count < 8) {
            self.setConditionState(isCorrect: false, text: String.localize("SIGN_UP_PASS_LENGTH"), conditionLabel: self.conditionTwo)
            return false
        }
        self.setConditionState(isCorrect: true, text: String.localize("SIGN_UP_PASS_LENGTH"), conditionLabel: self.conditionTwo)
        return true
    }
    
    func checkPasswords() {
        passwordTextField.setStatus(.none)
        if(checkFirstCondition() && checkSecondCondition()){
            passwordTextField.setStatus(.valid)
        } else {
            passwordTextField.setStatus(.invalid)
        }
        checkToEnableDisableNextButton()
    }
    
    func setConditionState(isCorrect: Bool?, text: String, conditionLabel: UILabel){
        var attributedMark: NSMutableAttributedString
        guard let correct = isCorrect else {
            conditionLabel.textColor = theme.secondText
            conditionLabel.text = text
            return
        }
        if(correct){
            attributedMark = NSMutableAttributedString(string: "✓ ", attributes: [.font: Font.regular.size(14)!])
            conditionLabel.textColor = UIColor(red: 97/255, green: 185/255, blue: 0, alpha: 1)
        } else {
            attributedMark = NSMutableAttributedString(string: "x ", attributes: [.font: Font.regular.size(14)!])
            conditionLabel.textColor = .red
        }
        let attributedText = NSAttributedString(string: text, attributes: [.font: Font.regular.size(14)!])
        attributedMark.append(attributedText)
        conditionLabel.attributedText = attributedMark
    }
    
    func setupField(){
        let placeholderAttrs = [.foregroundColor: theme.secondText] as [NSAttributedString.Key: Any]
        
        passwordTextField.tintColor = theme.mainText
        passwordTextField.font = Font.regular.size(17.0)
        passwordTextField.rightViewMode = .always
        passwordTextField.placeholderAnimation = .hidden
        passwordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("PASSWORD"), attributes: placeholderAttrs)
        passwordTextField.visibilityIconButton?.tintColor = theme.mainText
        passwordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        
        titleLabel.text = String.localize("SIGN_UP_PASSWORD_TITLE")
        conditionOne.text = String.localize("SIGN_UP_PASSWORD_CONDITION_ONE")
        conditionTwo.text = String.localize("SIGN_UP_PASSWORD_CONDITION_TWO")
        
        passwordTextField.becomeFirstResponder()
    }
    
    @objc func onDonePress(_ sender: Any){
        guard nextButton.isEnabled else {
            return
        }
        self.onNextPress(sender)
    }
    
    @IBAction func onPasswordChange(_ sender: Any) {
        checkPasswords()
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        guard let password = passwordTextField.text else {
            return
        }
        self.signUpData!.password = password
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "confirmPasswordView")  as! SignUpConfirmPasswordViewController
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
    
    func checkToEnableDisableNextButton(){
        nextButton.isEnabled = passwordTextField.isValid
        if(nextButton.isEnabled){
            nextButton.alpha = 1.0
        }else{
            nextButton.alpha = 0.5
        }
    }
}

extension SignUpPasswordViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension SignUpPasswordViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
