//
//  SyncUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/4/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class SyncRequestUIView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    
    var onResend: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        applyTheme()
        applyLocalization()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.secondText
    }
    
    func applyLocalization() {
        titleLabel.text = String.localize("SYNC_REQUEST_TITLE")
        messageLabel.text = String.localize("SYNC_REQUEST_MESSAGE")
        
        resendButton.setTitle(String.localize("SYNC_REQUEST_BUTTON"), for: .normal)
    }
    
    @IBAction func onRetryPress(_ sender: Any) {
        onResend?()
    }
}
