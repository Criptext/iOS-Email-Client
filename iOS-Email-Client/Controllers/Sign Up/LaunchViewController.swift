//
//  LaunchViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/27/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class LaunchViewController: UIViewController {
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var sloganImageView: UIImageView!
    
    var multipleAccount = false
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFields()
        applyTheme()
    }
    
    func applyTheme() {
        signupButton.backgroundColor = .white
        signupButton.layer.borderWidth = 1;
        signupButton.layer.borderColor = UIColor(red: 138/255, green: 138/255, blue: 138/255, alpha: 1).cgColor
        
        view.backgroundColor = theme.overallBackground
        versionLabel.textColor = theme.secondText
        
        logoImageView.image = theme.name == "Dark" ? UIImage(named: "new-logo-dark") : UIImage(named: "new-logo")
        sloganImageView.image = theme.name == "Dark" ? UIImage(named: "slogan-dark") : UIImage(named: "slogan")
    }
    
    func setupFields() {
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        versionLabel.text = "\(String.localize("VERSION").lowercased()) \(appVersionString)"
    }
    
    @IBAction func onLoginPress(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "loginviewcontroller")  as! LoginViewController
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func onSignupPress(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "fullNameView")  as! SignUpNameViewController
        controller.multipleAccount = self.multipleAccount
        navigationController?.pushViewController(controller, animated: true)
    }
}
