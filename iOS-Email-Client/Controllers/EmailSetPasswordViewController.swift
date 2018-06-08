//
//  EmailSetPasswordViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 6/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

protocol emailSetPasswordDelegate {
    func setPassword(guestEmails: [String: Any], criptextEmails: [String: Any], password: String)
}

class EmailSetPasswordViewController: BaseUIPopover {
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var repeatPasswordTextField: TextField!
    var guestEmails = [String: Any]()
    var criptextEmails = [String: Any]()
    var delegate : emailSetPasswordDelegate?
    
    init(){
        super.init("EmailSetPasswordUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        passwordTextField.detailColor = .black
        repeatPasswordTextField.detailColor = .black
    }
    
    @IBAction func onSetPress(_ sender: Any) {
        guard let password = passwordTextField.text, passwordTextField.text == repeatPasswordTextField.text else {
            repeatPasswordTextField.detail = "Passwords must match"
            return
        }
        self.dismiss(animated: true, completion: nil)
        self.delegate?.setPassword(guestEmails: self.guestEmails, criptextEmails: self.criptextEmails, password: password)
    }
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
