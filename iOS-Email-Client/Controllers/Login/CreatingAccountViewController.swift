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
        if let account = DBManager.getFirstAccount(),
            account.username != self.signupData.username {
            FileUtils.deleteAccountDirectory(account: account)
            DBManager.destroy()
            removeQuickGuideFlags()
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
        return (account, keys)
    }
    
    func sendKeysRequest(){
        feedbackLabel.text = String.localize("GENERATING_KEYS")
        let accountData = createAccount()
        let keyBundle = accountData.1["keybundle"] as! [String: Any]
        APIManager.postKeybundle(params: keyBundle, token: signupData.token!){ (responseData) in
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
        APIManager.signUpRequest(accountData.1) { (responseData) in
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
            let jwt = signupData.token,
            let refreshToken = signupData.refreshToken,
            let identityB64 = myBundle.store.identityKeyStore.getIdentityKeyPairB64() else {
            return
        }
        let regId = myBundle.store.identityKeyStore.getRegId()
        feedbackLabel.text = String.localize("LOGIN_AWESOME")
        DBManager.update(account: myAccount, jwt: jwt, refreshToken: refreshToken, regId: regId, identityB64: identityB64)
        let myContact = Contact()
        myContact.displayName = myAccount.name
        myContact.email = "\(myAccount.username)\(Constants.domain)"
        DBManager.store([myContact])
        let defaults = CriptextDefaults()
        defaults.activeAccount = myAccount.username
        if signupData.deviceId != 1 {
            defaults.welcomeTour = true
        }
        registerFirebaseToken(jwt: myAccount.jwt)
        animateProgress(100.0, 2.0) {
            self.goToMailbox(myAccount.username)
        }
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
    
    func goToMailbox(_ activeAccount: String){
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        DBManager.createSystemLabels()
        let mailboxVC = delegate.initMailboxRootVC(nil, activeAccount)
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
