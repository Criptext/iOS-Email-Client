//
//  RecoveryEmailViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class RecoveryEmailViewController: UIViewController {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Recovery Email"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        recoveryEmailLabel.text = recoveryEmail
        statusLabel.text = recoveryEmailStatus.description
        statusLabel.textColor = recoveryEmailStatus.color
        resendButton.isHidden = recoveryEmailStatus == .verified
        resendButtonHeightConstraint.constant = recoveryEmailStatus != .pending ? 0.0 : 44.0
        showLoader(false)
    }

    @IBAction func onChangeEmailPress(_ sender: Any) {
        self.goToChangeEmail()
    }
    
    @IBAction func onResendPress(_ sender: Any) {
        self.showLoader(true)
        APIManager.resendConfirmationEmail(token: myAccount.jwt) { (error) in
            guard error == nil else {
                self.showLoader(false)
                self.showAlert("Network Error", message: "Unable to resend link, please try again.", style: .alert)
                return
            }
            self.presentResendAlert()
            let defaults = UserDefaults.standard
            defaults.set(Date().timeIntervalSince1970, forKey: "lastTimeResent")
            self.showLoader(false)
        }
    }
    
    func presentResendAlert(){
        let alertVC = GenericAlertUIPopover()
        alertVC.myTitle = "Confirmation Link Sent"
        alertVC.myMessage = "Please check your inbox for a confirmation email. Click the link in the email to confirm your email address."
        self.presentPopover(popover: alertVC, height: 220)
    }
    
    func showLoader(_ show: Bool){
        guard show else {
            resendLoader.stopAnimating()
            resendLoader.isHidden = true
            
            let defaults = UserDefaults.standard
            let lastTimeResent = defaults.double(forKey: "lastTimeResent")
            guard lastTimeResent == 0 || Date().timeIntervalSince1970 - lastTimeResent > 300 else {
                resendButton.backgroundColor = UIColor(red: 246/255, green: 246/255, blue: 246/255, alpha: 1)
                resendButton.isEnabled = false
                startTimer()
                return
            }
            
            resendButton.isEnabled = true
            resendButton.setTitle("Resend Link", for: .normal)
            return
        }
        
        resendButton.isEnabled = false
        resendButton.setTitle("", for: .normal)
        resendLoader.isHidden = false
        resendLoader.startAnimating()
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
        resendButton.setTitle("Resend Link", for: .normal)
        resendButton.backgroundColor = .mainUI
        resendButton.setTitleColor(.white, for: .normal)
    }
    
    @discardableResult func setButtonTimerLable() -> Double {
        let defaults = UserDefaults.standard
        let lastTimeResent = defaults.double(forKey: "lastTimeResent")
        let currentTime = Date().timeIntervalSince1970
        let secondsLeft = 300 - (currentTime - lastTimeResent)
        let minsLeft = Int(ceil(secondsLeft/60))
        let title = "\(minsLeft) \(minsLeft == 1 ? "min" : "mins")"
        resendButton.setTitle(title, for: .normal)
        resendButton.setTitleColor(UIColor(red: 138/255, green: 138/255, blue: 138/255, alpha: 1), for: .normal)
        return secondsLeft
    }
    
    func goToChangeEmail(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let changeRecoveryVC = storyboard.instantiateViewController(withIdentifier: "changeRecoveryEmailViewController") as! ChangeRecoveryEmailViewController
        changeRecoveryVC.generalData = self.generalData
        changeRecoveryVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(changeRecoveryVC, animated: true)
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
}
