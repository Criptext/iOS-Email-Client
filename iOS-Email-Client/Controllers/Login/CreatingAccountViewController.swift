//
//  CreatingAccountViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/9/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework
import FirebaseMessaging
import UIWindowTransitions

class CreatingAccountViewController: UIViewController{
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var percentageLabel: CounterLabelUIView!
    @IBOutlet weak var feedbackLabel: UILabel!
    var fromSignup = false
    var multipleAccount = false
    var signupData: SignUpData!
    var account: Account?
    var bundle: CRBundle?
    var state : CreationState = .checkDB
    
    enum CreationState{
        case checkDB
        case signupRequest
        case accountCreate
    }
    
    func handleState(){
        switch(state){
        case .checkDB:
            checkDatabase()
        case .signupRequest:
            guard signupData.deviceId == 1 else {
                sendKeysRequest()
                break
            }
            sendSignUpRequest()
        case .accountCreate:
            updateAccount()
        }
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        progressBar.layer.cornerRadius = 5
        progressBar.layer.sublayers![1].cornerRadius = 5
        progressBar.subviews[1].clipsToBounds = true
        handleState()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        
        if let myAccount = self.account {
            DBManager.signout(account: myAccount)
            DBManager.delete(account: myAccount)
        }
    }
    
    func checkDatabase(){
        self.state = .signupRequest
        let accountId = self.signupData.domain == Env.plainDomain ? signupData.username : "\(signupData.username)@\(signupData.domain)"
        if DBManager.getLoggedOutAccount(accountId: accountId) == nil {
            let loggedOutAccounts = DBManager.getLoggedOutAccounts()
            for account in loggedOutAccounts {
                FileUtils.deleteAccountDirectory(account: account)
                DBManager.signout(account: account)
                DBManager.clearMailbox(account: account)
                DBManager.delete(account: account)
            }
        }
        self.handleState()
    }
    
    func removeQuickGuideFlags(){
        let defaults = CriptextDefaults()
        defaults.removeQuickGuideFlags()
    }
    
    func createAccount() -> (Account, [String: Any]) {
        if let myKeys = self.bundle?.publicKeys,
            let myAccount = self.account {
            return(myAccount, myKeys)
        }
        let account = SignUpData.createAccount(from: self.signupData)
        DBManager.store(account)
        
        let bundle = CRBundle(account: account)
        let keys = bundle.generateKeys()
        self.account = account
        self.bundle = bundle
        return (account, keys)
    }
    
    func sendKeysRequest(){
        feedbackLabel.text = String.localize("GENERATING_KEYS")
        let accountData = createAccount()
        APIManager.postKeybundle(params: accountData.1, token: signupData.token){ (responseData) in
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.displayErrorMessage(message: error.description)
                return
            }
            guard case let .SuccessDictionary(tokens) = responseData,
                let jwt = tokens["token"] as? String,
                let refreshToken = tokens["refreshToken"] as? String else {
                self.displayErrorMessage()
                return
            }
            self.signupData.token = jwt
            self.signupData.refreshToken = refreshToken
            self.animateProgress(50.0, 2.0) {
                self.state = .accountCreate
                self.handleState()
            }
        }
    }
    
    func sendSignUpRequest(){
        feedbackLabel.text = String.localize("GENERATING_KEYS")
        let accountData = createAccount()
        let signupRequestData = signupData.buildDataForRequest(publicKeys: accountData.1)
        APIManager.signUpRequest(signupRequestData) { (responseData) in
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.displayErrorMessage(message: error.description)
                return
            }
            if case let .TooManyRequests(waitingTime) = responseData {
                if waitingTime < 0 {
                    self.displayErrorMessage(message: String.localize("TOO_MANY_SIGNIN_ATTEMPTS"))
                } else {
                    self.displayErrorMessage(message: String.localize("ATTEMPTS_TIME_LEFT", arguments: Time.remaining(seconds: waitingTime)))
                }
                return
            }
            guard case let .SuccessDictionary(tokens) = responseData,
                let sessionToken = tokens["token"] as? String,
                let refreshToken = tokens["refreshToken"] as? String else {
                self.displayErrorMessage()
                return
            }
            self.signupData.token = sessionToken
            self.signupData.refreshToken = refreshToken
            self.animateProgress(50.0, 2.0) {
                self.state = .accountCreate
                self.handleState()
            }
        }
    }
    
    func sendNewKeysRequest(){
        feedbackLabel.text = String.localize("GENERATING_KEYS")
    }
    
    func updateAccount(){
        guard let myAccount = self.account,
            let myBundle = self.bundle,
            !signupData.token.isEmpty,
            let refreshToken = signupData.refreshToken,
            let identityB64 = myBundle.store.identityKeyStore.getIdentityKeyPairB64() else {
            return
        }
        let regId = myBundle.store.identityKeyStore.getRegId()
        feedbackLabel.text = String.localize("LOGIN_AWESOME")
        DBManager.update(account: myAccount, jwt: signupData.token, refreshToken: refreshToken, regId: regId, identityB64: identityB64)
        let myContact = Contact()
        myContact.displayName = myAccount.name
        myContact.email = "\(myAccount.username)\(Constants.domain)"
        DBManager.store([myContact], account: myAccount)
        let defaults = CriptextDefaults()
        defaults.activeAccount = myAccount.compoundKey
        if signupData.deviceId != 1 {
            defaults.welcomeTour = true
        }
        registerFirebaseToken(jwt: myAccount.jwt)
        animateProgress(100.0, 2.0) {
            let hasEmails = self.fromSignup ? true : DBManager.hasEmails(account: myAccount)
            if self.multipleAccount {
                self.goBackToMailbox(account: myAccount, showRestore: !hasEmails)
            } else {
                self.goToMailbox(myAccount.compoundKey, showRestore: !hasEmails)
            }
        }
    }
    
    func goBackToMailbox(account: Account, showRestore: Bool) {
        self.account = nil
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            self.dismiss(animated: true)
            return
        }
        delegate.swapAccount(account: account, showRestore: showRestore)
    }
    
    func displayErrorMessage(message: String = String.localize("SIGNUP_FALLBACK_ERROR")){
        let alert = UIAlertController(title: String.localize("WARNING"), message: "\(message)\(String.localize("WOULD_TRY_AGAIN"))", preferredStyle: .alert)
        let proceedAction = UIAlertAction(title: String.localize("RETRY"), style: .default){ (alert : UIAlertAction!) -> Void in
            self.handleState()
        }
        let cancelAction = UIAlertAction(title: String.localize("CANCEL"), style: .cancel){ (alert : UIAlertAction!) -> Void in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(proceedAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func goToMailbox(_ activeAccount: String, showRestore: Bool){
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        DBManager.createSystemLabels()
        let mailboxVC = delegate.initMailboxRootVC(nil, activeAccount, showRestore: showRestore)
        var options = UIWindow.TransitionOptions()
        options.direction = .toTop
        options.duration = 0.4
        options.style = .easeOut
        UIApplication.shared.keyWindow?.setRootViewController(mailboxVC, options: options)
    }
    
    func animateProgress(_ value: Double, _ duration: Double, completion: @escaping () -> Void){
        self.percentageLabel.setValue(value, interval: duration)
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
            self.progressBar.setProgress(Float(value/100), animated: true)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + duration){
            completion()
        }
    }
    
    func registerFirebaseToken(jwt: String){
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return
        }
        APIManager.registerToken(fcmToken: fcmToken, token: jwt)
    }
}
