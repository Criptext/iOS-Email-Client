//
//  SyncDeniedUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/4/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class SyncDeniedUIView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var warningLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    var onRetry: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        applyTheme()
        applyLocalization()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.secondText
        self.backgroundColor = .clear
    }
    
    func applyLocalization() {
        titleLabel.text = String.localize("SYNC_DENIED_TITLE")
        messageLabel.text = String.localize("SYNC_DENIED_MESSAGE")
        
        let attrText = NSMutableAttributedString(string: String.localize("SYNC_DENIED_WARNING_TITLE"), attributes: [.font: Font.bold.size(warningLabel.fontSize) as Any])
        attrText.append(NSAttributedString(string: String.localize("SYNC_DENIED_WARNING_MESSAGE"), attributes: [.font: Font.regular.size(warningLabel.fontSize) as Any]))
        
        retryButton.setTitle(String.localize("SYNC_DENIED_BUTTON"), for: .normal)
    }
    
    @IBAction func onRetryPress(_ sender: Any) {
        onRetry?()
    }
}
