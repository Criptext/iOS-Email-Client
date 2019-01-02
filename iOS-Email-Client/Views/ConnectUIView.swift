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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dotsProgressView: DotsProgressUIView!
    @IBOutlet weak var successImage: UIImageView!
    @IBOutlet weak var backgroundCircle: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var goBackButton: UIButton!
    @IBOutlet weak var percentageView: TipUIView!
    @IBOutlet weak var leftDeviceImage: UIImageView!
    @IBOutlet weak var rightDeviceImage: UIImageView!
    @IBOutlet weak var counterLabel: CounterLabelUIView!
    @IBOutlet weak var progressAnimatedView: ProgressAnimatedUIView!
    var goBack: (() -> Void)?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "ConnectView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
    }
    
    func initialLoad(email: String) {
        emailLabel.text = email
        progressAnimatedView.isHidden = false
        successImage.isHidden = true
        backgroundCircle.isHidden = true
    }
    
    func handleSuccess(){
        backgroundCircle.isHidden = false
        successImage.isHidden = false
        progressAnimatedView.isHidden = true
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
        self.progressAnimatedView.animateProgress(value: value, duration: duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration){
            if value == 100 {
                self.handleSuccess()
            }
            completion()
        }
    }
    
    func setDeviceIcons(leftType: Device.Kind, rightType: Device.Kind) {
        switch(leftType){
        case .pc:
            leftDeviceImage.image = UIImage(named: "device-desktop")!
        case .ios, .android:
            leftDeviceImage.image = UIImage(named: "device-mobile")!
        }
        
        switch(rightType){
        case .pc:
            rightDeviceImage.image = UIImage(named: "device-desktop")!
        case .ios, .android:
            rightDeviceImage.image = UIImage(named: "device-mobile")!
        }
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        view.backgroundColor = theme.overallBackground
        emailLabel.textColor = theme.secondText
        messageLabel.textColor = theme.mainText
        goBackButton.setTitleColor(theme.criptextBlue, for: .normal)
        percentageView.backgroundColor = .clear
        counterLabel.textColor = theme.overallBackground
        counterLabel.backgroundColor = theme.mainText
        titleLabel.textColor = theme.markedText
        progressAnimatedView.backgroundColor = .clear
        percentageView.tipColor = theme.mainText
        percentageView.layoutIfNeeded()
    }

    @IBAction func goBack(_ sender: Any) {
        goBack?()
    }
}
