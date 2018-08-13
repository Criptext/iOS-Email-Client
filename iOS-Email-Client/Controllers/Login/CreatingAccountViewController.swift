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

class CreatingAccountViewController: UIViewController{
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var percentageLabel: CounterLabelUIView!
    @IBOutlet weak var feedbackLabel: UILabel!
    var signupData: SignUpData!
    var state : CreationState = .signupRequest
    
    enum CreationState{
        case signupRequest
        case accountCreate
    }
    
    func handleState(){
        switch(state){
        case .signupRequest:
            guard signupData.deviceId == 1 else {
                sendKeysRequest()
                break
            }
            sendSignUpRequest()
        case .accountCreate:
            createActiveDevice()
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
    
    func sendKeysRequest(){
        feedbackLabel.text = "Generating keys..."
        let keyBundle = signupData.buildDataForRequest()["keybundle"] as! [String: Any]
        APIManager.postKeybundle(params: keyBundle, token: signupData.token!){ (error, jwt) in
            guard error == nil else {
                self.displayErrorMessage()
                return
            }
            self.signupData.token = jwt!
            self.animateProgress(50.0, 2.0) {
                self.state = .accountCreate
                self.handleState()
            }
        }
    }
    
    func sendSignUpRequest(){
        feedbackLabel.text = "Generating keys..."
        APIManager.singUpRequest(signupData.buildDataForRequest()) { (error, token) in
            guard error == nil && token != nil else {
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
        myAccount.password = signupData.password
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
        registerFirebaseToken(jwt: myAccount.jwt)
        animateProgress(100.0, 2.0) {
            self.goToMailbox(myAccount.username)
        }
    }
    
    func createActiveDevice(){
        let device = Device()
        device.name = systemIdentifier()
        device.type = Device.Kind.current.rawValue
        device.active = true
        DBManager.store(device)
    }
    
    func displayErrorMessage(){
        let alert = UIAlertController(title: "Warning", message: "Unable to complete your sign-up, would you like to try again?", preferredStyle: .alert)
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
        delegate.createSystemLabels()
        let mailboxVC = delegate.initMailboxRootVC(nil, activeAccount)
        present(mailboxVC, animated: true) { [weak self] in
            delegate.replaceRootViewController(mailboxVC)
            self?.removeFromParentViewController()
        }
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
