//
//  SyncUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/4/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Lottie

class SyncRequestUIView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var animateView: UIView!
    
    var animationView: AnimationView? = nil
    var onResend: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        applyTheme()
        applyLocalization()
        setupAnimations()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.secondText
        self.backgroundColor = .clear
    }
    
    func applyLocalization() {
        titleLabel.text = String.localize("SYNC_REQUEST_TITLE")
        messageLabel.text = String.localize("SYNC_REQUEST_MESSAGE")
        
        resendButton.setTitle(String.localize("SYNC_REQUEST_BUTTON"), for: .normal)
    }
    
    func setupAnimations() {
        let animationPath = Bundle.main.path(forResource: "WaitingDesktop", ofType: "json")!
        animationView = AnimationView(filePath: animationPath)
        self.animateView.addSubview(animationView!)
        animationView!.center = self.animateView.center
        animationView!.frame = self.animateView.bounds
        animationView!.contentMode = .scaleAspectFit
        animationView!.loopMode = .loop
    }
    
    func animate(_ animate: Bool) {
        guard let animation = animationView else  {
            return
        }
        if animate {
            animation.play()
        } else {
            animation.stop()
        }
    }
    
    @IBAction func onRetryPress(_ sender: Any) {
        onResend?()
    }
}
