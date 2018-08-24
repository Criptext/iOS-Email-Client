//
//  ChangeRecoveryEmailViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class ChangeRecoveryEmailViewController: UIViewController {
    
    @IBOutlet weak var buttonLoader: UIActivityIndicatorView!
    @IBOutlet weak var emailTextField: TextField!
    @IBOutlet weak var doneButton: UIButton!
    var generalData: GeneralSettingsData!
    var myAccount: Account!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonLoader.isHidden = true
        navigationItem.title = "Recovery Email"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        emailTextField.keyboardType = .emailAddress
        emailTextField.detailColor = .alert
        emailTextField.becomeFirstResponder()
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }

    @IBAction func onDonePress(_ sender: Any) {
        guard let email = emailTextField.text else {
            return
        }
        guard email != "\(myAccount.username)\(Constants.domain)" else {
            emailTextField.detail = "Don't use the same criptext account"
            return
        }
        guard email != generalData.recoveryEmail else {
            emailTextField.detail = "Please enter a different email"
            return
        }
        guard Utils.validateEmail(email) else {
            emailTextField.detail = "Please enter a valid email"
            return
        }
        presentPasswordPopover()
    }
    
    func presentPasswordPopover(){
        let passwordVC = PasswordUIPopover()
        passwordVC.onOkPress = { [weak self] password in
            self?.sendRequest(password: password.sha256()!)
        }
        self.presentPopover(popover: passwordVC, height: 213)
    }
    
    func sendRequest(password: String){
        guard let email = emailTextField.text else {
            return
        }
        showLoader(true)
        APIManager.changeRecoveryEmail(email: email, password: password, token: myAccount.jwt) { error in
            self.showLoader(false)
            guard error == nil else {
                self.showAlert("Network Error", message: "Unable to change recovery email. Please try again", style: .alert)
                return
            }
            self.generalData.recoveryEmail = email
            self.generalData.recoveryEmailStatus = .pending
            self.goBack()
        }
    }
    
    func showLoader(_ show: Bool){
        guard show else {
            buttonLoader.isHidden = true
            buttonLoader.stopAnimating()
            doneButton.isEnabled = true
            doneButton.setTitle("Done", for: .normal)
            return
        }
        
        buttonLoader.isHidden = false
        buttonLoader.startAnimating()
        doneButton.isEnabled = false
        doneButton.setTitle("", for: .normal)
    }
}
