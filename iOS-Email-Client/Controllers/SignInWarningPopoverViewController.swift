//
//  LogoutPopoverViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/1/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SignInWarningPopoverViewController: BaseUIPopover {
    var onTrigger: ((Bool) -> Void)?
    var timer: Timer?
    var secondsLeft = 10
    var initialMessage: NSAttributedString?
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    
    init(){
        super.init("SignInWarningUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.attributedText = initialMessage
        startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let myTimer = timer {
            myTimer.invalidate()
        }
    }
    
    @IBAction func onLogoutPress(_ sender: Any) {
        onTrigger?(true)
        self.dismiss(animated: true)
    }
    @IBAction func onCancelPress(_ sender: Any) {
        onTrigger?(false)
        self.dismiss(animated: true)
    }
    
    func startTimer() {
        if let myTimer = timer {
            myTimer.invalidate()
        }
        checkTimer(seconds: self.secondsLeft)
        logoutButton.isEnabled = false
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { timer in
            self.checkTimer(seconds: self.secondsLeft)
        })
    }
    
    func checkTimer(seconds: Int) {
        guard secondsLeft <= 0 else {
            UIView.performWithoutAnimation {
                logoutButton.setTitle("\(String.localize("Yes")) (\(secondsLeft))", for: .disabled)
                self.logoutButton.layoutIfNeeded()
            }
            secondsLeft = secondsLeft - 1
            return
        }
        if let myTimer = timer {
            myTimer.invalidate()
        }
        UIView.performWithoutAnimation {
            self.logoutButton.setTitle(String.localize("Yes"), for: .normal)
            self.logoutButton.layoutIfNeeded()
        }
        logoutButton.isEnabled = true
    }
    
}
