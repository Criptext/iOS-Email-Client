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
    var scheduleWorker = ScheduleWorker(interval: 10.0, maxRetries: 18)
    
    var myAccount: Account!
    var recoveryEmail: String!
    var multipleAccount: Bool = false
    
    var isVerified = false
    
    let WAIT_TIME: Double = 20
    let POPOVER_HEIGHT = 220
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        applyTheme()
        setupFields()
        
        scheduleWorker.delegate = self
        scheduleWorker.start()
        
        nextButton.setTitle(String.localize("RESEND_LINK"), for: .normal)
        loadingView.stopAnimating()
    }
    
    func applyTheme() {
        titleLabel.textColor = theme.mainText
        messageLabel.textColor = theme.secondText
        stepLabel.textColor = theme.secondText
        emailLabel.textColor = theme.markedText
        verifiedLabel.textColor = UIColor(red: 61/255, green: 170/255, blue: 85/255, alpha: 1)
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
        titleLabel.text = String.localize("CUSTOMIZE_RECOVERY_EMAIL_TITLE")
        messageLabel.text = String.localize("CUSTOMIZE_RECOVERY_EMAIL_MESSAGE")
        stepLabel.text = String.localize(self.multipleAccount ? "STEP_2_HEADER" : "CUSTOMIZE_STEP_4")
        verifiedLabel.text = "(\(String.localize("VERIFIED")))"
        nextButton.setTitle(String.localize("NEXT"), for: .normal)
        skipButton.setTitle(String.localize("SKIP"), for: .normal)
        emailLabel.text = recoveryEmail
    }
    
    func showLoaderTimer(_ show: Bool){
        guard show else {
            loadingView.stopAnimating()
            loadingView.isHidden = true
            
            let defaults = CriptextDefaults()
            let lastTimeResent = defaults.lastTimeResent
            guard lastTimeResent == 0 || Date().timeIntervalSince1970 - lastTimeResent > WAIT_TIME else {
                nextButton.isEnabled = false
                nextButton.alpha = 0.5
                startTimer()
                return
            }
            
            nextButton.alpha = 1
            nextButton.isEnabled = true
            nextButton.setTitle(String.localize("RESEND_LINK"), for: .normal)
            return
        }
        
        nextButton.isEnabled = false
        nextButton.alpha = 0.5
        nextButton.setTitle("", for: .normal)
        loadingView.isHidden = false
        loadingView.startAnimating()
    }
    
    func startTimer() {
        if let myTimer = timer {
            myTimer.invalidate()
        }
        setButtonTimerLabel()
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { timer in
            let secondsLeft = self.setButtonTimerLabel()
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
        nextButton.alpha = 1
        nextButton.setTitle(String.localize("RESEND_LINK"), for: .normal)
        nextButton.backgroundColor = .mainUI
        nextButton.setTitleColor(.white, for: .normal)
    }
    
    @discardableResult func setButtonTimerLabel() -> Double {
        let defaults = CriptextDefaults()
        let lastTimeResent = defaults.lastTimeResent
        let currentTime = Date().timeIntervalSince1970
        let secondsLeft = WAIT_TIME - (currentTime - lastTimeResent)
        let title = "\(String.localize("RESEND_LINK")) (\(Int(secondsLeft)) \(secondsLeft == 1 ? "sec" : "secs"))"
        nextButton.titleLabel?.text = title
        nextButton.setTitle(title, for: .normal)
        return secondsLeft
    }
    
    func checkToEnableDisableNextButton(){
        nextButton.isEnabled = isVerified
        if(nextButton.isEnabled){
            nextButton.setTitle(String.localize("NEXT"), for: .normal)
            nextButton.alpha = 1.0
            skipButton.isHidden = true
            verifiedLabel.isHidden = false
            if let myTimer = timer {
                myTimer.invalidate()
            }
        }else{
            nextButton.setTitle(String.localize("RESEND_LINK"), for: .normal)
            skipButton.isHidden = false
            verifiedLabel.isHidden = true
        }
    }
    
    @IBAction func onNextPress(_ sender: UIButton) {
        switch sender {
        case nextButton:
            if self.isVerified {
                goToiCloudView()
                break
            }
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
                let defaults = CriptextDefaults()
                defaults.lastTimeResent = Date().timeIntervalSince1970
                self.showLoaderTimer(false)
            }
        default:
            presentRecoveryEmailWarning()
        }
    }
    
    func goToiCloudView(){
        scheduleWorker.cancel()
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "customizeiCloudView")  as! CustomizeiCloudViewController
        controller.myAccount = self.myAccount
        controller.multipleAccount = self.multipleAccount
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

extension CustomizeRecoveryEmailViewController: ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void) {
        APIManager.canSend(token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                completion(false)
                return
            }
            completion(true)
            self.isVerified = true
            self.checkToEnableDisableNextButton()
        }
    }
    
    func dangled(){
        self.scheduleWorker.start()
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
