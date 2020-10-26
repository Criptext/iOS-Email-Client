//
//  SignUpConfirmPasswordViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/21/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class SignUpConfirmPasswordViewController: UIViewController{
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var conditionOne: UILabel!
    @IBOutlet weak var confirmPasswordTextField: StatusTextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
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
        confirmPasswordTextField.tintColor = theme.mainText
        confirmPasswordTextField.textColor = theme.mainText
        confirmPasswordTextField.validDividerColor = theme.criptextBlue
        confirmPasswordTextField.invalidDividerColor = theme.alert
        confirmPasswordTextField.dividerColor = theme.criptextBlue
        confirmPasswordTextField.detailColor = theme.alert
        confirmPasswordTextField.visibilityIconButton?.tintColor = theme.mainText
        titleLabel.textColor = theme.mainText
        conditionOne.textColor = theme.secondText
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
        self.confirmPasswordTextField.endEditing(true)
    }
    
    func checkPasswords() {
        guard let confirmPassword = confirmPasswordTextField.text else {
            self.setConditionState(isCorrect: nil, text: "", conditionLabel: self.conditionOne)
            checkToEnableDisableNextButton()
            return
        }
        
        if(confirmPassword != self.signUpData?.password) {
            self.setConditionState(isCorrect: false, text: String.localize("SIGN_UP_CONFIRM_PASSWORD_CONDITION"), conditionLabel: self.conditionOne)
            confirmPasswordTextField.setStatus(.invalid)
            checkToEnableDisableNextButton()
            return
        }
        self.setConditionState(isCorrect: true, text: String.localize("SIGN_UP_CONFIRM_PASSWORD_CONDITION"), conditionLabel: self.conditionOne)
        confirmPasswordTextField.setStatus(.valid)
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
        
        confirmPasswordTextField.font = Font.regular.size(17.0)
        confirmPasswordTextField.rightViewMode = .always
        confirmPasswordTextField.placeholderAnimation = .hidden
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("CONFIRM_PASSWORD"), attributes: placeholderAttrs)
        
        confirmPasswordTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        
        titleLabel.text = String.localize("SIGN_UP_CONFIRM_PASSWORD_TITLE")
        conditionOne.text = String.localize("SIGN_UP_CONFIRM_PASSWORD_CONDITION")
        
        confirmPasswordTextField.becomeFirstResponder()
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
        guard confirmPasswordTextField.text != nil else {
            return
        }
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "recoveryEmailView")  as! SignUpRecoveryEmailViewController
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
        nextButton.isEnabled = confirmPasswordTextField.isValid
        if(nextButton.isEnabled){
            nextButton.alpha = 1.0
        }else{
            nextButton.alpha = 0.5
        }
    }
}

extension SignUpConfirmPasswordViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension SignUpConfirmPasswordViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
