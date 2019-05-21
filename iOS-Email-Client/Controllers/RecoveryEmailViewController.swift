//
//  RecoveryEmailViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class RecoveryEmailViewController: UIViewController {
    
    let BUTTON_HEIGHT: CGFloat = 44.0
    let POPOVER_HEIGHT = 220
    let WAIT_TIME: Double = 300
    
    var generalData: GeneralSettingsData!
    var myAccount: Account!
    var recoveryEmail: String {
        return generalData.recoveryEmail ?? "None"
    }
    var recoveryEmailStatus: GeneralSettingsData.RecoveryStatus {
        return generalData.recoveryEmailStatus
    }
    var timer: Timer?
    @IBOutlet weak var recoveryEmailLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var resendButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var resendLoader: UIActivityIndicatorView!
    @IBOutlet weak var emailTextField: TextField!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var currentLabel: UILabel!
    @IBOutlet weak var newLabel: UILabel!
    @IBOutlet weak var noteLabel: UILabel!
    @IBOutlet weak var buttonLoader: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        navigationItem.title = String.localize("RECOVERY_EMAIL_TITLE")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        prepareView()
        applyTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        self.view.backgroundColor = theme.overallBackground
        newLabel.textColor = theme.mainText
        currentLabel.textColor = theme.mainText
        noteLabel.textColor = theme.secondText
        recoveryEmailLabel.textColor = theme.mainText
        emailTextField.textColor = theme.mainText
        emailTextField.attributedPlaceholder = NSAttributedString(string: String.localize("ENTER_NEW_RECOVERY"), attributes: [.foregroundColor: theme.placeholder, .font: Font.regular.size(emailTextField.minimumFontSize)!])
        emailTextField.visibilityIconButton?.tintColor = theme.placeholder
        
        emailTextField.detailColor = theme.criptextBlue
        doneButton.backgroundColor = theme.criptextBlue
        resendButton.backgroundColor = theme.criptextBlue
    }
    
    func prepareView(){
        recoveryEmailLabel.text = recoveryEmail
        statusLabel.text = recoveryEmailStatus.description
        statusLabel.textColor = recoveryEmailStatus.color
        resendButton.isHidden = recoveryEmailStatus == .verified
        resendButtonHeightConstraint.constant = recoveryEmailStatus != .pending ? 0.0 : BUTTON_HEIGHT
        showLoaderTimer(false)
        
        buttonLoader.isHidden = true
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocorrectionType = .no
        emailTextField.autocapitalizationType = .none
        emailTextField.detailColor = .alert
        
        emailTextField.text = ""
        doneButton.isEnabled = false
        doneButton.alpha = 0.6
    }
    
    @IBAction func onResendPress(_ sender: Any) {
        self.showLoaderTimer(true)
        APIManager.resendConfirmationEmail(token: myAccount.jwt) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout(account: self.myAccount)
                return
            }
            self.showLoaderTimer(false)
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.showAlert("REQUEST_ERROR", message: "\(error.description). \(String.localize("TRY_AGAIN"))", style: .alert)
                return
            }
            guard case .Success = responseData else {
                self.showAlert("NETWORK_ERROR", message: "UNABLE_RESEND_LINK", style: .alert)
                return
            }
            self.presentResendAlert()
            let defaults = CriptextDefaults()
            defaults.lastTimeResent = Date().timeIntervalSince1970
            self.showLoaderTimer(false)
        }
    }
    
    func presentResendAlert(){
        let alertVC = GenericAlertUIPopover()
        alertVC.myTitle = String.localize("LINK_SENT")
        alertVC.myMessage = String.localize("CHECK_INBOX_LINK")
        self.presentPopover(popover: alertVC, height: POPOVER_HEIGHT)
    }
    
    @IBAction func onEditingChanged(_ sender: Any) {
        guard let email = emailTextField.text,
            Utils.validateEmail(email) else {
                doneButton.isEnabled = false
                doneButton.alpha = 0.6
            return
        }
        
        doneButton.isEnabled = true
        doneButton.alpha = 1.0
    }
    
    @IBAction func onDonePress(_ sender: Any) {
        guard let email = emailTextField.text else {
            return
        }
        guard email != "\(myAccount.username)\(Constants.domain)" else {
            emailTextField.detail = String.localize("SAME_ACCOUNT")
            return
        }
        guard email != generalData.recoveryEmail else {
            emailTextField.detail = String.localize("DIFFERENT_EMAIL")
            return
        }
        presentChangePasswordPopover()
    }
    
    func presentChangePasswordPopover(){
        let passwordVC = PasswordUIPopover()
        passwordVC.onOkPress = { [weak self] password in
            self?.sendRequest(password: password.sha256()!)
        }
        self.presentPopover(popover: passwordVC, height: 213)
    }
    
    func sendRequest(password: String){
        guard let email = emailTextField.text else {
            return
        }
        showLoader(true)
        APIManager.changeRecoveryEmail(email: email, password: password, token: myAccount.jwt) { responseData in
            if case .Unauthorized = responseData {
                self.logout(account: self.myAccount)
                return
            }
            self.showLoader(false)
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.showAlert("NETWORK_ERROR", message: "\(error.description). Please try again", style: .alert)
                return
            }
            if case .BadRequest = responseData {
                self.showAlert("ODD", message: String.localize("ENTERED_WRONG_PASS"), style: .alert)
                return
            }
            if case .Conflicts = responseData {
                self.showAlert("ODD", message: String.localize("DIFFERENT_RECOVERY"), style: .alert)
                return
            }
            guard case .Success = responseData else {
                self.showAlert("ODD", message: String.localize("UNABLE_CHANGHE_RECOVERY"), style: .alert)
                return
            }
            self.generalData.recoveryEmail = email
            self.generalData.recoveryEmailStatus = .pending
            self.generalData.isTwoFactor = false
            self.emailTextField.detail = ""
            self.prepareView()
            self.presentResendAlert()
        }
    }
    
    func showLoaderTimer(_ show: Bool){
        guard show else {
            resendLoader.stopAnimating()
            resendLoader.isHidden = true
            
            let defaults = CriptextDefaults()
            let lastTimeResent = defaults.lastTimeResent
            guard lastTimeResent == 0 || Date().timeIntervalSince1970 - lastTimeResent > WAIT_TIME else {
                resendButton.backgroundColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1)
                resendButton.isEnabled = false
                startTimer()
                return
            }
            
            resendButton.isEnabled = true
            resendButton.setTitle(String.localize("RESEND_LINK"), for: .normal)
            return
        }
        
        resendButton.isEnabled = false
        resendButton.setTitle("", for: .normal)
        resendLoader.isHidden = false
        resendLoader.startAnimating()
    }
    
    func showLoader(_ show: Bool){
        guard show else {
            buttonLoader.isHidden = true
            buttonLoader.stopAnimating()
            doneButton.isEnabled = true
            doneButton.setTitle(String.localize("Change"), for: .normal)
            return
        }
        
        buttonLoader.isHidden = false
        buttonLoader.startAnimating()
        doneButton.isEnabled = false
        doneButton.setTitle("", for: .normal)
    }
    
    func startTimer() {
        if let myTimer = timer {
            myTimer.invalidate()
        }
        setButtonTimerLable()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { timer in
            let secondsLeft = self.setButtonTimerLable()
            self.checkTimer(seconds: secondsLeft)
        })
    }
    
    func checkTimer(seconds: Double) {
        guard seconds <= 0 else {
            return
        }
        if let myTimer = timer {
            myTimer.invalidate()
        }
        resendButton.isEnabled = true
        resendButton.setTitle(String.localize("RESEND_LINK"), for: .normal)
        resendButton.backgroundColor = .mainUI
        resendButton.setTitleColor(.white, for: .normal)
    }
    
    @discardableResult func setButtonTimerLable() -> Double {
        let defaults = CriptextDefaults()
        let lastTimeResent = defaults.lastTimeResent
        let currentTime = Date().timeIntervalSince1970
        let secondsLeft = 300 - (currentTime - lastTimeResent)
        let minsLeft = Int(ceil(secondsLeft/60))
        let title = "\(minsLeft) \(minsLeft == 1 ? "min" : "mins")"
        resendButton.setTitle(title, for: .normal)
        resendButton.setTitleColor(UIColor(red: 138/255, green: 138/255, blue: 138/255, alpha: 1), for: .normal)
        return secondsLeft
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
}

extension RecoveryEmailViewController: CustomTabsChildController {
    func reloadView() {
        recoveryEmailLabel.text = recoveryEmail
        statusLabel.text = recoveryEmailStatus.description
        statusLabel.textColor = recoveryEmailStatus.color
        resendButton.isHidden = recoveryEmailStatus == .verified
        resendButtonHeightConstraint.constant = recoveryEmailStatus != .pending ? 0.0 : BUTTON_HEIGHT
    }
}

extension RecoveryEmailViewController: LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData, account: Account) {
        guard linkData.version == Env.linkVersion else {
            let popover = GenericAlertUIPopover()
            popover.myTitle = String.localize("VERSION_TITLE")
            popover.myMessage = String.localize("VERSION_MISMATCH")
            self.presentPopover(popover: popover, height: 220)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = account
        self.present(linkDeviceVC, animated: true, completion: nil)
    }
    func onCancelLinkDevice(linkData: LinkData, account: Account) {
        if case .sync = linkData.kind {
            APIManager.syncDeny(randomId: linkData.randomId, token: account.jwt, completion: {_ in })
        } else {
            APIManager.linkDeny(randomId: linkData.randomId, token: account.jwt, completion: {_ in })
        }
    }
}

extension RecoveryEmailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}
