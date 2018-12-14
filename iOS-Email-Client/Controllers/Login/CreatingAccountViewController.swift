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
            createAccount()
        }
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        progressBar.layer.cornerRadius = 5
        progressBar.layer.sublayers![1].cornerRadius = 5
        progressBar.subviews[1].clipsToBounds = true
        handleState()
    }
    
    func checkDatabase(){
        self.state = .signupRequest
        if let account = DBManager.getFirstAccount(),
            account.username != self.signupData.username {
            DBManager.destroy()
            removeQuickGuideFlags()
        }
        self.handleState()
    }
    
    func removeQuickGuideFlags(){
        let defaults = CriptextDefaults()
        defaults.removeQuickGuideFlags()
    }
    
    func sendKeysRequest(){
        feedbackLabel.text = String.localize("GENERATING_KEYS")
        let keyBundle = signupData.buildDataForRequest()["keybundle"] as! [String: Any]
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
        APIManager.signUpRequest(signupData.buildDataForRequest()) { (responseData) in
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
    
    func createAccount(){
        feedbackLabel.text = String.localize("LOGIN_AWESOME")
        let myAccount = Account()
        myAccount.username = signupData.username
        myAccount.name = signupData.fullname
        myAccount.jwt = signupData.token!
        myAccount.refreshToken = signupData.refreshToken
        myAccount.regId = signupData.getRegId()
        myAccount.identityB64 = signupData.getIdentityKeyPairB64() ?? ""
        myAccount.deviceId = signupData.deviceId
        DBManager.store(myAccount)
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
