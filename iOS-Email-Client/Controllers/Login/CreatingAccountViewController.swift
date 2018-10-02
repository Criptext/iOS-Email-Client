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
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "guideAttachments")
        defaults.removeObject(forKey: "guideUnsend")
        defaults.removeObject(forKey: "guideFeed")
        defaults.removeObject(forKey: "guideComposer")
    }
    
    func sendKeysRequest(){
        feedbackLabel.text = "Generating keys..."
        let keyBundle = signupData.buildDataForRequest()["keybundle"] as! [String: Any]
        APIManager.postKeybundle(params: keyBundle, token: signupData.token!){ (responseData) in
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.displayErrorMessage(message: error.description)
                return
            }
            guard case let .SuccessString(jwt) = responseData else {
                self.displayErrorMessage()
                return
            }
            self.signupData.token = jwt
            self.animateProgress(50.0, 2.0) {
                self.state = .accountCreate
                self.handleState()
            }
        }
    }
    
    func sendSignUpRequest(){
        feedbackLabel.text = "Generating keys..."
        APIManager.signUpRequest(signupData.buildDataForRequest()) { (responseData) in
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.displayErrorMessage(message: error.description)
                return
            }
            guard case let .SuccessString(token) = responseData else {
                self.displayErrorMessage()
                return
            }
            self.signupData.token = token
            self.animateProgress(50.0, 2.0) {
                self.state = .accountCreate
                self.handleState()
            }
        }
    }
    
    func sendNewKeysRequest(){
        feedbackLabel.text = "Generating keys..."
    }
    
    func createAccount(){
        feedbackLabel.text = "Login into awesomeness..."
        let myAccount = Account()
        myAccount.username = signupData.username
        myAccount.name = signupData.fullname
        myAccount.jwt = signupData.token!
        myAccount.regId = signupData.getRegId()
        myAccount.identityB64 = signupData.getIdentityKeyPairB64() ?? ""
        myAccount.deviceId = signupData.deviceId
        DBManager.store(myAccount)
        let myContact = Contact()
        myContact.displayName = myAccount.name
        myContact.email = "\(myAccount.username)\(Constants.domain)"
        DBManager.store([myContact])
        let defaults = UserDefaults.standard
        defaults.set(myAccount.username, forKey: "activeAccount")
        if signupData.deviceId != 1 {
            defaults.set(true, forKey: "welcomeTour")
        }
        registerFirebaseToken(jwt: myAccount.jwt)
        animateProgress(100.0, 2.0) {
            self.goToMailbox(myAccount.username)
        }
    }
    
    func displayErrorMessage(message: String = "Unable to complete your sign-up"){
        let alert = UIAlertController(title: "Warning", message: "\(message). would you like to try again?", preferredStyle: .alert)
        let proceedAction = UIAlertAction(title: "Retry", style: .default){ (alert : UIAlertAction!) -> Void in
            self.handleState()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel){ (alert : UIAlertAction!) -> Void in
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
