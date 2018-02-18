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
        showFeedback(false)
        checkToEnableDisableResetButton()
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func hideKeyboard(){
        self.passwordTextField.endEditing(true)
    }
    
    @IBAction func onPasswordChange(_ sender: Any) {
        showFeedback(false)
        checkToEnableDisableResetButton()
    }
    
    @IBAction func onResetPress(_ sender: Any) {
        if(failed){
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "creatingaccountview")
            self.present(controller, animated: true, completion: nil)
            showFeedback(false)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
            self.showFeedback(false, "Incorrect Password")
            self.failed = true
        }
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func checkToEnableDisableResetButton(){
        let textCount = passwordTextField.text?.count ?? 0
        resetButton.isEnabled = !(passwordTextField.isEmpty || textCount < Constants.MinCharactersPassword)
        if(resetButton.isEnabled){
            resetButton.alpha = 1.0
        }else{
            resetButton.alpha = 0.5
        }
    }
    
    func showFeedback(_ show: Bool, _ message: String? = nil){
        errorMark.isHidden = !show
        errorLabel.isHidden = !show
        errorLabel.text = message ?? ""
    }
    
    func jumpToCreatingAccount(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "creatingaccountview")
        self.present(controller, animated: true, completion: nil)
    }
    
}
