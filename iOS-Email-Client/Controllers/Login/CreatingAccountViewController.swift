//
//  CreatingAccountViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/9/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class CreatingAccountViewController: UIViewController{
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var percentageLabel: CounterLabelUIView!
    @IBOutlet weak var feedbackLabel: UILabel!
    var signupData: SignUpData!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        progressBar.layer.cornerRadius = 5
        progressBar.layer.sublayers![1].cornerRadius = 5
        progressBar.subviews[1].clipsToBounds = true
        sendSignUpRequest()
    }
    
    func sendSignUpRequest(){
        feedbackLabel.text = "Generating keys..."
        signupData.generateKeys()
        APIManager.singUpRequest(signupData.buildDataForRequest()) { (error) in
            guard error == nil else {
                self.feedbackLabel.text = "Woops 1..."
                return
            }
            self.percentageLabel.setValue(33.0, interval: 1.5)
            UIView.animate(withDuration: 1.5, animations: { 
                self.progressBar.setProgress(0.33, animated: true)
            }, completion: { (completed) in
                self.sendLoginRequest()
            })
        }
    }
    
    func sendLoginRequest(){
        feedbackLabel.text = "Login into awesomeness..."
        APIManager.loginRequest(signupData.username, signupData.password) { (error, token) in
            guard error == nil else {
                self.feedbackLabel.text = "Woops 2..."
                return
            }
            self.percentageLabel.setValue(66.0, interval: 1.5)
            UIView.animate(withDuration: 1.5, animations: {
                self.progressBar.setProgress(0.66, animated: true)
            }, completion: { (completed) in
                self.signupData.token = token
                self.createAccount()
            })
        }
    }
    
    func createAccount(){
        let myAccount = Account()
        myAccount.username = signupData.username
        myAccount.name = signupData.fullname
        myAccount.password = signupData.password
        myAccount.jwt = signupData.token!
        myAccount.rawIdentityKeyPair = signupData.getRawIdentityKeyPar() ?? ""
        DBManager.store(myAccount)
        let defaults = UserDefaults.standard
        defaults.set(myAccount.username, forKey: "activeAccount")
        
        self.percentageLabel.setValue(100.0, interval: 1.5)
        UIView.animate(withDuration: 1.5, animations: {
            self.progressBar.setProgress(1, animated: true)
        }, completion: { (completed) in

        })
    }
}
