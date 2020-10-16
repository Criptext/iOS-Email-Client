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
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var stepLabel: UILabel!
    
    var myAccount: Account!
    
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
        titleLabel.text = String.localize("CUSTOMIZE_ICLOUD_TITLE")
        messageLabel.text = String.localize("CUSTOMIZE_ICLOUD_MESSAGE")
        stepLabel.text = String.localize("CUSTOMIZE_STEP_5")
        nextButton.setTitle(String.localize("CUSTOMIZE_ICLOUD_BTN"), for: .normal)
        skipButton.setTitle(String.localize("SKIP"), for: .normal)
    }
    
    @objc func onDonePress(_ sender: Any){
        guard let button = sender as? UIButton else {
            return
        }
        if(button.isEnabled){
            self.onNextPress(button)
        }
    }
    
    func toggleLoadingView(_ show: Bool){
        if(show){
            nextButton.setTitle("", for: .normal)
            loadingView.isHidden = false
            loadingView.startAnimating()
        }else{
            nextButton.setTitle(String.localize("CUSTOMIZE_ICLOUD_BTN"), for: .normal)
            loadingView.isHidden = true
            loadingView.stopAnimating()
        }
    }
    
    @IBAction func onNextPress(_ sender: UIButton) {
        toggleLoadingView(true)
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
            self.showSnackbar(String.localize("BACKUP_ACTIVATED"), attributedText: nil, buttons: "", permanent: false)
            toggleLoadingView(false)
            goToMailbox()
        default:
            goToMailbox()
        }
    }
    
    func goToMailbox(){
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let mailboxVC = delegate.initMailboxRootVC(nil, myAccount, showRestore: false)
        var options = UIWindow.TransitionOptions()
        options.direction = .toTop
        options.duration = 0.4
        options.style = .easeOut
        UIApplication.shared.keyWindow?.setRootViewController(mailboxVC, options: options)
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
