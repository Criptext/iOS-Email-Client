//
//  CustomizeThemeViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/24/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class CustomizeThemeViewController: UIViewController {
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var themeSwitch: UISegmentedControl!
    
    var myAccount: Account!
    var recoveryEmail: String!
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        applyTheme()
        setupFields()
        
        themeSwitch.selectedSegmentIndex = ThemeManager.shared.theme.name != "Dark" ? 0 : 1
    }
    
    func applyTheme() {
        titleLabel.textColor = theme.mainText
        messageLabel.textColor = theme.secondText
        stepLabel.textColor = theme.secondText
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.mainText]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .normal)
        view.backgroundColor = theme.background
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.setNeedsDisplay()
    }
    
    func setupFields(){
        titleLabel.text = String.localize("CUSTOMIZE_THEME_TITLE")
        messageLabel.text = String.localize("CUSTOMIZE_THEME_MESSAGE")
        stepLabel.text = String.localize("CUSTOMIZE_STEP_2")
        nextButton.setTitle(String.localize("ADD_BTN"), for: .normal)
        themeSwitch.setTitle(String.localize("CUSTOMIZE_THEME_LIGHT"), forSegmentAt: 0)
        themeSwitch.setTitle(String.localize("CUSTOMIZE_THEME_DARK"), forSegmentAt: 1)
    }
    
    @objc func onDonePress(_ sender: Any){
        guard nextButton.isEnabled else {
            return
        }
        self.onNextPress(sender)
    }
    
    @IBAction func actionTriggered(sender: Any) {
        let index = themeSwitch.selectedSegmentIndex
        switch(index){
            case 0:
                ThemeManager.shared.swapTheme(theme: Theme.init())
            default:
                ThemeManager.shared.swapTheme(theme: Theme.dark())
        }
        let defaults = CriptextDefaults()
        defaults.themeMode = ThemeManager.shared.theme.name
        applyTheme()
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "customizePermissionView")  as! CustomizePermissionViewController
        controller.myAccount = self.myAccount
        controller.recoveryEmail = self.recoveryEmail
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension CustomizeThemeViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension CustomizeThemeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
