//
//  CustomizePermissionViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/24/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class CustomizePermissionViewController: UIViewController {
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var contactSwitch: UISwitch!
    @IBOutlet weak var contactLabel: UILabel!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var notificationLabel: UILabel!
    
    var myAccount: Account!
    var recoveryEmail: String!
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        applyTheme()
        setupFields()
        checkToEnableDisableNextButton()
    }
    
    func applyTheme() {
        titleLabel.textColor = theme.mainText
        messageLabel.textColor = theme.secondText
        stepLabel.textColor = theme.secondText
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: theme.mainText]
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes(titleTextAttributes, for: .normal)
        view.backgroundColor = theme.background
        skipButton.setTitleColor(theme.markedText, for: .normal)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.setNeedsDisplay()
    }
    
    func setupFields(){
        titleLabel.text = String.localize("CUSTOMIZE_PERMISSIONS_TITLE")
        messageLabel.text = String.localize("CUSTOMIZE_PERMISSIONS_MESSAGE")
        stepLabel.text = String.localize("CUSTOMIZE_STEP_3")
        nextButton.setTitle(String.localize("NEXT"), for: .normal)
        skipButton.setTitle(String.localize("SKIP"), for: .normal)
        stepLabel.text = String.localize("CUSTOMIZE_STEP_3")
        contactLabel.text = String.localize("CUSTOMIZE_PERMISSIONS_CONTACTS")
        notificationLabel.text = String.localize("CUSTOMIZE_PERMISSIONS_NOTIFICATIONS")
    }
    
    @objc func onDonePress(_ sender: Any){
        guard let button = sender as? UIButton else {
            return
        }
        if(button.isEnabled){
            self.onNextPress(button)
        }
    }
    
    @IBAction func onSwitchToggle(_ sender: UISwitch) {
        switch(sender){
            case contactSwitch:
                if(contactSwitch.isOn){
                    let syncContactsTask = RetrieveContactsTask(accountId: myAccount.compoundKey)
                    syncContactsTask.start { [weak self] (success) in
                        guard let weakSelf = self else {
                            self?.checkToEnableDisableNextButton()
                            return
                        }
                        weakSelf.checkToEnableDisableNextButton()
                    }
                }
                self.checkToEnableDisableNextButton()
            case notificationSwitch:
                if(notificationSwitch.isOn){
                    guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
                        self.checkToEnableDisableNextButton()
                        return
                    }
                    delegate.registerPushNotifications()
                }
                self.checkToEnableDisableNextButton()
            default:
                break
        }
    }
    
    func checkToEnableDisableNextButton(){
        nextButton.isEnabled = contactSwitch.isOn && notificationSwitch.isOn
        if(nextButton.isEnabled){
            nextButton.alpha = 1.0
            skipButton.isHidden = true
            messageLabel.isHidden = false
        }else{
            nextButton.alpha = 0.5
            skipButton.isHidden = false
            messageLabel.isHidden = true
        }
    }
    
    @IBAction func onNextPress(_ sender: UIButton) {
        goToRecoveryEmailView()
    }
    
    func goToRecoveryEmailView(){
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "customizeRecoveryEmailView")  as! CustomizeRecoveryEmailViewController
        controller.myAccount = self.myAccount
        controller.recoveryEmail = self.recoveryEmail
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension CustomizePermissionViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension CustomizePermissionViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
