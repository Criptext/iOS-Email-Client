//
//  PasswordUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class PasswordUIPopover: BaseUIPopover {
    
    var onOkPress: ((String) -> (Void))?
    var remotelyCheckPassword = false
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var passwordTextField: TextField!
    
    init(){
        super.init("PasswordUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isVisibilityIconButtonEnabled = true
        passwordTextField.becomeFirstResponder()
    }
    
    @IBAction func okPress(_ sender: Any) {
        guard let password = passwordTextField.text else {
            return
        }
        okButton.isEnabled = false
        passwordTextField.isEnabled = false
        passwordTextField.resignFirstResponder()
        guard !remotelyCheckPassword else {
            validatePassword(password)
            return
        }
        self.dismiss(animated: true, completion: { [weak self] in
            self?.onOkPress?(password)
        })
    }
    
    func validatePassword(_ password: String){
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.dismiss(animated: true, completion: { [weak self] in
                self?.onOkPress?(password)
            })
        }
    }
    
    @IBAction func cancelPress(_ sender: Any) {
        dismiss(animated: true)
    }
}
