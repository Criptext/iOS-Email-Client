//
//  LoginViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/2/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class NewLoginViewController: UIViewController{
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var emailInput: TextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButton.clipsToBounds = true
        loginButton.layer.cornerRadius = 20
        
        let boldText  = "Sign up"
        let attrs = [NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 17), NSAttributedStringKey.foregroundColor : UIColor.white]
        let attributedString = NSMutableAttributedString(string:boldText, attributes:attrs)
        
        let normalText = "Not registered? "
        let normalAttrs = [NSAttributedStringKey.font : UIFont.systemFont(ofSize: 17), NSAttributedStringKey.foregroundColor : UIColor.white]
        let normalString = NSMutableAttributedString(string:normalText, attributes: normalAttrs)
        
        normalString.append(attributedString)
        signupButton.setAttributedTitle(normalString, for: .normal)
        
        emailInput.placeholder = "Username"
        emailInput.placeholderNormalColor = UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
        emailInput.textColor = UIColor.white
        emailInput.dividerNormalColor = UIColor(displayP3Red: 1.0, green: 1.0, blue: 1.0, alpha: 0.25)
        emailInput.dividerActiveColor = UIColor.white
        emailInput.placeholderActiveScale = 0
        
        let tap : UIGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tap)
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
    }
    
    @objc func hideKeyboard(){
        self.emailInput.endEditing(true)
    }
    
    
}

extension NewLoginViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}
