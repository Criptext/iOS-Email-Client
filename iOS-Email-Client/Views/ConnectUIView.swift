//
//  ConnectUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ConnectUIView: UIView {
    
    @IBOutlet var view: UIView!
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dotsProgressView: DotsProgressUIView!
    @IBOutlet weak var successImage: UIImageView!
    @IBOutlet weak var backgroundCircle: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var goBackButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var percentageView: UIView!
    @IBOutlet weak var counterLabel: CounterLabelUIView!
    var goBack: (() -> Void)?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "ConnectView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
    }
    
    func initialLoad(email: String) {
        progressView.layer.cornerRadius = 5
        progressView.layer.sublayers![1].cornerRadius = 5
        progressView.subviews[1].clipsToBounds = true
        emailLabel.text = email
        successImage.isHidden = true
        backgroundCircle.isHidden = true
    }
    
    func handleSuccess(){
        backgroundCircle.isHidden = false
        successImage.isHidden = false
        progressView.isHidden = true
        percentageView.isHidden = true
    }
    
    func progressChange(value: Double, message: String?, cancel: Bool = false, completion: @escaping () -> Void){
        goBackButton.isHidden = !cancel
        if let myMessage = message {
            messageLabel.text = myMessage
        }
        animateProgress(value, 1.0, completion: completion)
    }
    
    func animateProgress(_ value: Double, _ duration: Double, completion: @escaping () -> Void){
        self.counterLabel.setValue(value, interval: duration)
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
            self.progressView.setProgress(Float(value/100), animated: true)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + duration){
            if value == 100 {
                self.handleSuccess()
            }
            completion()
        }
    }

    @IBAction func goBack(_ sender: Any) {
        goBack?()
    }
}
