//
//  CustomizeRecoveryEmailViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/24/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class CustomizeRecoveryEmailViewController: UIViewController {
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var stepLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var verifiedLabel: UILabel!
    
    var timer: Timer?
    
    var myAccount: Account!
    var recoveryEmail: String!
    
    var isVerified = false
    
    let WAIT_TIME: Double = 300
    let POPOVER_HEIGHT = 220
    
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
        verifiedLabel.textColor = UIColor(red: 61/255, green: 170/255, blue: 85/255, alpha: 1)
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
        titleLabel.text = String.localize("CUSTOMIZE_RECOVERY_EMAIL_TITLE")
        messageLabel.text = String.localize("CUSTOMIZE_RECOVERY_EMAIL_MESSAGE")
        stepLabel.text = String.localize("CUSTOMIZE_STEP_4")
        verifiedLabel.text = "(" + String.localize("VERIFIED") + ")"
        nextButton.setTitle(String.localize("NEXT"), for: .normal)
        skipButton.setTitle(String.localize("SKIP"), for: .normal)
        emailLabel.text = recoveryEmail
    }
    
    func presentResendAlert(){
        let alertVC = GenericAlertUIPopover()
        alertVC.myTitle = String.localize("LINK_SENT")
        alertVC.myMessage = String.localize("CHECK_INBOX_LINK")
        self.presentPopover(popover: alertVC, height: POPOVER_HEIGHT)
    }
    
    func showLoaderTimer(_ show: Bool){
        guard show else {
            loadingView.stopAnimating()
            loadingView.isHidden = true
            
            let defaults = CriptextDefaults()
            let lastTimeResent = defaults.lastTimeResent
            guard lastTimeResent == 0 || Date().timeIntervalSince1970 - lastTimeResent > WAIT_TIME else {
                nextButton.backgroundColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1)
                nextButton.isEnabled = false
                startTimer()
                return
            }
            
            nextButton.isEnabled = true
            nextButton.setTitle(String.localize("RESEND_LINK"), for: .normal)
            return
        }
        
        nextButton.isEnabled = false
        nextButton.setTitle("", for: .normal)
        loadingView.isHidden = false
        loadingView.startAnimating()
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
        nextButton.isEnabled = true
        nextButton.setTitle(String.localize("RESEND_LINK"), for: .normal)
        nextButton.backgroundColor = .mainUI
        nextButton.setTitleColor(.white, for: .normal)
    }
    
    @discardableResult func setButtonTimerLable() -> Double {
        let defaults = CriptextDefaults()
        let lastTimeResent = defaults.lastTimeResent
        let currentTime = Date().timeIntervalSince1970
        let secondsLeft = 300 - (currentTime - lastTimeResent)
        let minsLeft = Int(ceil(secondsLeft/60))
        let title = "\(minsLeft) \(minsLeft == 1 ? "min" : "mins")"
        nextButton.setTitle(title, for: .normal)
        nextButton.setTitleColor(UIColor(red: 138/255, green: 138/255, blue: 138/255, alpha: 1), for: .normal)
        return secondsLeft
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
            nextButton.setTitle(String.localize("NEXT"), for: .normal)
            loadingView.isHidden = true
            loadingView.stopAnimating()
        }
    }
    
    func checkToEnableDisableNextButton(){
        nextButton.isEnabled = isVerified
        if(nextButton.isEnabled){
            nextButton.alpha = 1.0
            skipButton.isHidden = true
            verifiedLabel.isHidden = false
        }else{
            nextButton.alpha = 0.5
            skipButton.isHidden = false
            verifiedLabel.isHidden = true
        }
    }
    
    @IBAction func onNextPress(_ sender: UIButton) {
        switch sender {
        case nextButton:
            if(self.isVerified){
                toggleLoadingView(true)
                goToiCloudView()
                toggleLoadingView(false)
            } else {
                self.showLoaderTimer(true)
                APIManager.resendConfirmationEmail(token: myAccount.jwt) { (responseData) in
                    if case .Removed = responseData {
                        self.logout(account: self.myAccount, manually: false)
                        return
                    }
                    if case .Unauthorized = responseData {
                        self.showAlert(String.localize("AUTH_ERROR"), message: String.localize("AUTH_ERROR_MESSAGE"), style: .alert)
                        return
                    }
                    self.showLoaderTimer(false)
                    if case .Forbidden = responseData {
                        self.presentPasswordPopover(myAccount: self.myAccount)
                        return
                    }
                    if case let .Error(error) = responseData,
                        error.code != .custom {
                        self.showAlert(String.localize("REQUEST_ERROR"), message: "\(error.description). \(String.localize("TRY_AGAIN"))", style: .alert)
                        return
                    }
                    guard case .Success = responseData else {
                        self.showAlert(String.localize("NETWORK_ERROR"), message: String.localize("UNABLE_RESEND_LINK"), style: .alert)
                        return
                    }
                    self.presentResendAlert()
                    let defaults = CriptextDefaults()
                    defaults.lastTimeResent = Date().timeIntervalSince1970
                    self.showLoaderTimer(false)
                }
            }
        default:
            presentRecoveryEmailWarning()
        }
    }
    
    func goToiCloudView(){
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "customizeiCloudView")  as! CustomizeiCloudViewController
        controller.myAccount = self.myAccount
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func presentRecoveryEmailWarning(){
        let retryPopup = GenericDualAnswerUIPopover()
        retryPopup.initialMessage = String.localize("CUSTOMIZE_RECOVERY_EMAIL_WARNING_MESSAGE")
        retryPopup.initialTitle = String.localize("CUSTOMIZE_RECOVERY_EMAIL_WARNING_TITLE")
        retryPopup.leftOption = String.localize("SKIP")
        retryPopup.rightOption = String.localize("CANCEL")
        retryPopup.onResponse = { accept in
            if(!accept){
                self.goToiCloudView()
            }
        }
        self.presentPopover(popover: retryPopup, height: 235)
    }
}

extension CustomizeRecoveryEmailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension CustomizeRecoveryEmailViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
