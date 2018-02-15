//
//  ResetDeviceViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/15/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class ResetDeviceViewController: UIViewController{

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var errorMark: UIImageView!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var resetButton: UIButton!
    @IBOutlet weak var passwordTextField: TextField!
    var loginData: LoginData!
    var failed = false
    
    override func viewDidLoad() {
        emailLabel.text = loginData.email
        clearErrors()
        enableResetButton()
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func hideKeyboard(){
        self.passwordTextField.endEditing(true)
    }
    
    @IBAction func onPasswordChange(_ sender: Any) {
        clearErrors()
        enableResetButton()
    }
    
    @IBAction func onResetPress(_ sender: Any) {
        if(failed){
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "creatingaccountview")
            self.present(controller, animated: true, completion: nil)
            clearErrors()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
            self.setResetError("Incorrect Password")
            self.failed = true
        }
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func enableResetButton(){
        let textCount = passwordTextField.text?.count ?? 0
        resetButton.isEnabled = !(passwordTextField.isEmpty || textCount < 6)
        if(resetButton.isEnabled){
            resetButton.alpha = 1.0
        }else{
            resetButton.alpha = 0.5
        }
    }
    
    func setResetError(_ error: String){
        errorMark.isHidden = false
        errorLabel.isHidden = false
        errorLabel.text = error
    }
    
    func clearErrors(){
        errorMark.isHidden = true
        errorLabel.isHidden = true
    }
    
    func jumpToCreatingAccount(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "creatingaccountview")
        self.present(controller, animated: true, completion: nil)
    }
    
}
