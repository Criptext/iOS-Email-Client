//
//  CustomizeiCloudViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/24/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class CustomizeiCloudViewController: UIViewController {
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var stepLabel: UILabel!
    
    var myAccount: Account!
    var multipleAccount: Bool = false
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        applyTheme()
        setupFields()
    }
    
    func applyTheme() {
        titleLabel.textColor = theme.mainText
        messageLabel.textColor = theme.mainText
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
        titleLabel.text = String.localize("CUSTOMIZE_ICLOUD_TITLE")
        messageLabel.text = String.localize("CUSTOMIZE_ICLOUD_MESSAGE")
        stepLabel.text = String.localize(self.multipleAccount ? "STEP_3_HEADER" : "CUSTOMIZE_STEP_5")
        nextButton.setTitle(String.localize("CUSTOMIZE_ICLOUD_BTN"), for: .normal)
        skipButton.setTitle(String.localize("SKIP"), for: .normal)
    }
    
    @IBAction func onNextPress(_ sender: UIButton) {
        switch sender {
        case nextButton:
            let defaults = CriptextDefaults()
            guard BackupManager.shared.hasCloudAccessDir(email: self.myAccount.email) else {
                self.showAlert(String.localize("CLOUD_ERROR"), message: String.localize("CLOUD_ERROR_MSG"), style: .alert)
                return
            }
            DBManager.update(account: self.myAccount, hasCloudBackup: !self.myAccount.hasCloudBackup)
            DBManager.update(account: self.myAccount, frequency: BackupFrequency.daily.rawValue)
            BackupManager.shared.clearAccount(accountId: self.myAccount.compoundKey)
            BackupManager.shared.backupNow(account: self.myAccount)
            defaults.setShownAutobackup(email: self.myAccount.email)
            self.showSnackbar(String.localize("BACKUP_ACTIVATED"), attributedText: nil, permanent: false)
            goToMailbox()
        default:
            goToMailbox()
        }
    }
    
    func goToMailbox(){
        if (multipleAccount) {
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
                self.dismiss(animated: true)
                return
            }
            delegate.swapAccount(account: myAccount, showRestore: false)
        } else {
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let mailboxVC = delegate.initMailboxRootVC(nil, myAccount, showRestore: false)
            let options = UIWindow.TransitionOptions()
            options.direction = .toTop
            options.duration = 0.4
            options.style = .easeOut
            UIApplication.shared.keyWindow?.set(rootViewController: mailboxVC, options: options, nil)
        }
    }
}

extension CustomizeiCloudViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

extension CustomizeiCloudViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
