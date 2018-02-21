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
        feedbackLabel.text = "Notifying your existance..."
        APIManager.singUpRequest(signupData.username, signupData.fullname, signupData.password, signupData.optionalEmail) { (error) in
            guard error == nil else {
                self.feedbackLabel.text = "Woops 1..."
                return
            }
            self.percentageLabel.setValue(25.0, interval: 1.5)
            UIView.animate(withDuration: 1.5, animations: { 
                self.progressBar.setProgress(0.25, animated: true)
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
            self.percentageLabel.setValue(50.0, interval: 1.5)
            UIView.animate(withDuration: 1.5, animations: {
                self.progressBar.setProgress(0.5, animated: true)
            }, completion: { (completed) in
                self.signupData.token = token
                self.sendKeysRequest()
            })
        }
    }
    
    func sendKeysRequest(){
        self.feedbackLabel.text = "Generating keys..."
        signupData.generateKeys()
        APIManager.sendKeysRequest(signupData.publicKeys!, token: signupData.token!){ error in
            guard error == nil else {
                self.feedbackLabel.text = "Woops 3..."
                return
            }
            self.percentageLabel.setValue(75.0, interval: 1.5)
            UIView.animate(withDuration: 1.5, animations: {
                self.progressBar.setProgress(0.75, animated: true)
            }, completion: { (completed) in
                self.feedbackLabel.text = "Adding the last lego piece..."
            })
        }
    }
}
