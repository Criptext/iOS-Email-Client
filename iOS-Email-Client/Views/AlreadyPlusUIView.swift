//
//  AlreadyPlusUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 5/22/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class AlreadyPlusUIView: UIView {
    @IBOutlet weak var settingsImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.mainText
        self.backgroundColor = .clear
    }
    
    func applyLocalization() {
        titleLabel.text = String.localize("PLUS_SETTINGS_TITLE")
        messageLabel.text = String.localize("PLUS_SETTINGS_MESSAGE")
    }
}
