//
//  SignUpUserNameViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/21/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material
import Alamofire

class SignUpUserNameViewController: UIViewController{
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var usernameTextField: StatusTextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var criptextLabel: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    var signUpData: TempSignUpData!
    var multipleAccount = false
    var apiRequest : DataRequest?
    
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
        usernameTextField.tintColor = theme.mainText
        usernameTextField.textColor = theme.mainText
        usernameTextField.validDividerColor = theme.criptextBlue
        usernameTextField.invalidDividerColor = theme.alert
        usernameTextField.dividerColor = theme.criptextBlue
        usernameTextField.detailColor = theme.alert
        titleLabel.textColor = theme.mainText
        criptextLabel.textColor = theme.mainText
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
        self.usernameTextField.endEditing(true)
    }
    
    func checkUsername(){
        usernameTextField.text = usernameTextField.text?.lowercased()
        guard let username = usernameTextField.text,
            Utils.isValidUsername(username) else {
            let inputError = String.localize("VALID_EMAIL_CONDITION")
            usernameTextField.setStatus(.invalid, inputError)
            self.checkToEnableDisableNextButton()
            return
        }
        
        usernameTextField.setStatus(.none)
        apiRequest?.cancel()
        apiRequest = APIManager.checkAvailableUsername(username) { (responseData) in
            if username != self.usernameTextField.text {
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.usernameTextField.setStatus(.invalid, error.description)
                self.checkToEnableDisableNextButton()
                return
            }
            guard case .Success = responseData else {
                self.usernameTextField.setStatus(.invalid, String.localize("USERNAME_EXISTS"))
                self.checkToEnableDisableNextButton()
                return
            }
            self.usernameTextField.setStatus(.valid)
            self.checkToEnableDisableNextButton()
        }
    }
    
    func setupField(){
        let placeholderAttrs = [.foregroundColor: theme.secondText] as [NSAttributedString.Key: Any]
        
        usernameTextField.autocorrectionType = .no
        usernameTextField.autocapitalizationType = .none
        usernameTextField.font = Font.regular.size(17.0)
        usernameTextField.placeholderAnimation = .hidden
        usernameTextField.attributedPlaceholder = NSAttributedString(string: String.localize("USERNAME"), attributes: placeholderAttrs)

        titleLabel.text = String.localize("SIGN_UP_USER_NAME_TITLE")
        messageLabel.text = String.localize("SIGN_UP_USER_NAME_MESSAGE")
        criptextLabel.text = Env.domain
        
        usernameTextField.becomeFirstResponder()
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
            nextButton.setTitle(String.localize("NEXT"), for: .normal)
            loadingView.isHidden = true
            loadingView.stopAnimating()
        }
        checkToEnableDisableNextButton()
    }
    
    @IBAction func onUserNameChange(_ sender: Any) {
        checkUsername()
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        guard let userName = usernameTextField.text?.lowercased() else {
            return
        }
        self.signUpData!.username = userName
        toggleLoadingView(true)
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "passwordView")  as! SignUpPasswordViewController
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
        nextButton.isEnabled = usernameTextField.isValid
        if(nextButton.isEnabled){
            nextButton.alpha = 1.0
        }else{
            nextButton.alpha = 0.5
        }
    }
}

extension SignUpUserNameViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension SignUpUserNameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
