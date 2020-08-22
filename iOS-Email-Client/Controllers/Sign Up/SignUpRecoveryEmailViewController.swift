//
//  SignUpRecoveryEmailViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/21/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class SignUpRecoveryEmailViewController: UIViewController{
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var emailTextField: StatusTextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    var signUpData: TempSignUpData?
    var multipleAccount = false
    let signUpValidator = ValidateString.signUp
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        applyTheme()
        nextButtonInit()
        setupField()
        
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        if(signUpData == nil){
            signUpData = TempSignUpData()
        } else {
            toggleLoadingView(false)
            checkToEnableDisableNextButton()
        }
        closeButton.isHidden = !multipleAccount
    }
    
    func applyTheme() {
        emailTextField.textColor = theme.mainText
        emailTextField.validDividerColor = theme.criptextBlue
        emailTextField.invalidDividerColor = UIColor.red
        emailTextField.dividerColor = theme.criptextBlue
        emailTextField.detailColor = UIColor.red
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
        self.emailTextField.endEditing(true)
    }
    
    func checkOptionalEmail(){
        guard !emailTextField.isEmpty,
            let email = emailTextField.text else {
                emailTextField.setStatus(.invalid, String.localize("ENTER_RECOVERY_EMAIL"))
                return
        }
        guard Utils.validateEmail(emailTextField.text!) else {
            let inputError = String.localize("NOT_VALID_EMAIL")
            emailTextField.setStatus(.invalid, inputError)
            return
        }
        APIManager.checkAvailableRecoveryEmail(self.signUpData!.username!, recoveryEmail: email) { (responseData) in
            switch(responseData) {
                case .ConflictsInt(let error):
                    self.emailTextField.setStatus(.invalid)
                    self.handleChangeRecoveryEmailError(error)
                    return
                case .ConflictsData(let errorCode, let data):
                    self.emailTextField.setStatus(.invalid)
                    self.handleChangeRecoveryEmailError(errorCode, limit: data["max"] as? Int ?? 0)
                    return
                case .Success:
                    self.emailTextField.detail = ""
                    self.emailTextField.setStatus(.valid)
                    self.checkToEnableDisableNextButton()
                default:
                    return
            }
        }
    }
    
    func handleChangeRecoveryEmailError(_ error: Int, limit: Int = 0) {
        var message = ""
        switch(error) {
        case 1:
            message = String.localize("RECOVERY_EMAIL_UNVERIFIED")
        case 2:
            message = String.localize("RECOVERY_EMAIL_USED", arguments: limit)
        case 3:
            message = String.localize("RECOVERY_EMAIL_BLOCKED")
        case 4:
            message = String.localize("RECOVERY_EMAIL_SAME")
        default:
            self.showAlert("ODD", message: String.localize("UNABLE_CHANGE_RECOVERY"), style: .alert)
            return
        }
        emailTextField.dividerActiveColor = .alert
        emailTextField.detailColor = .alert
        emailTextField.detail = message
        nextButton.isEnabled = false
        nextButton.alpha = 0.6
    }
    
    func setConditionState(isCorrect: Bool?, text: String, conditionLabel: UILabel){
        var attributedMark: NSMutableAttributedString
        let theme = ThemeManager.shared.theme
        guard let correct = isCorrect else {
            conditionLabel.textColor = theme.secondText
            conditionLabel.text = text
            return
        }
        if(correct){
            attributedMark = NSMutableAttributedString(string: "✓ ", attributes: [.font: Font.regular.size(14)!])
            conditionLabel.textColor = .green
        } else {
            attributedMark = NSMutableAttributedString(string: "x ", attributes: [.font: Font.regular.size(14)!])
            conditionLabel.textColor = .red
        }
        let attributedText = NSAttributedString(string: text, attributes: [.font: Font.regular.size(14)!])
        attributedMark.append(attributedText)
        conditionLabel.attributedText = attributedMark
    }
    
    func setupField(){
        let placeholderAttrs = [.foregroundColor: UIColor(red: 1, green: 1, blue: 1, alpha: 0.6)] as [NSAttributedString.Key: Any]
        
        emailTextField.font = Font.regular.size(17.0)
        emailTextField.placeholderAnimation = .hidden
        emailTextField.attributedPlaceholder = NSAttributedString(string: String.localize("RECOVERY_OPT"), attributes: placeholderAttrs)
        
        emailTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        
        titleLabel.text = String.localize("SIGN_UP_RECOVERY_EMAIL_TITLE")
        messageLabel.text = String.localize("SIGN_UP_RECOVERY_EMAIL_MESSAGE")
        nextButton.setTitle(String.localize("SIGN_UP_RECOVERY_EMAIL_BTN"), for: .normal)
    }
    
    func nextButtonInit(){
        nextButton.clipsToBounds = true
        nextButton.layer.cornerRadius = 20
    }
    
    @objc func onDonePress(_ sender: Any){
        guard nextButton.isEnabled else {
            return
        }
        self.onNextPress(sender)
    }
    
    func toggleLoadingView(_ show: Bool){
        if(show){
            nextButton.setTitle("", for: .normal)
            loadingView.isHidden = false
            loadingView.startAnimating()
        }else{
            nextButton.setTitle(String.localize("SIGN_UP_RECOVERY_EMAIL_BTN"), for: .normal)
            loadingView.isHidden = true
            loadingView.stopAnimating()
        }
        checkToEnableDisableNextButton()
    }
    
    @IBAction func onPasswordChange(_ sender: Any) {
        checkOptionalEmail()
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        guard let recoveryEmail = emailTextField.text else {
            return
        }
        self.signUpData!.optionalEmail = recoveryEmail
        toggleLoadingView(true)
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "termsAndConditionsView")  as! SignUpTermsAndConditionsViewController
        controller.multipleAccount = self.multipleAccount
        controller.signUpData = self.signUpData
        navigationController?.pushViewController(controller, animated: true)
        toggleLoadingView(false)
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
        nextButton.isEnabled = emailTextField.isValid
        if(nextButton.isEnabled){
            nextButton.alpha = 1.0
        }else{
            nextButton.alpha = 0.5
        }
    }
}

extension SignUpRecoveryEmailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension SignUpRecoveryEmailViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
