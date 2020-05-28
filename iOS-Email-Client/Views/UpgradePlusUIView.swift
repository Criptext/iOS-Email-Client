//
//  UpgradePlusUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 5/22/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class UpgradePlusUIView: UIView {
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var borderImage: UIImageView!
    @IBOutlet weak var perksTitleLabel: UILabel!
    @IBOutlet weak var perkOneLabel: UILabel!
    @IBOutlet weak var perkTwoLabel: UILabel!
    @IBOutlet weak var perkThreeLabel: UILabel!
    @IBOutlet weak var perkFourLabel: UILabel!
    @IBOutlet weak var perkFiveLabel: UILabel!
    @IBOutlet weak var redirectLabel: UILabel!
    @IBOutlet weak var redirectContainer: UIView!
    @IBOutlet weak var perksContainer: UIView!
    @IBOutlet weak var plusLabel: UILabel!
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        perksTitleLabel.textColor = theme.markedText
        perkOneLabel.textColor = theme.mainText
        perkTwoLabel.textColor = theme.mainText
        perkThreeLabel.textColor = theme.mainText
        perkFourLabel.textColor = theme.mainText
        perkFiveLabel.textColor = theme.mainText
        redirectLabel.textColor = theme.markedText
        redirectContainer.backgroundColor = theme.secondBackground
        redirectContainer.layer.borderColor = theme.groupEmailBorder.cgColor
        redirectContainer.layer.borderWidth = 1.0
        perksContainer.layer.borderColor = theme.groupEmailBorder.cgColor
        perksContainer.layer.borderWidth = 1.0
        perksContainer.backgroundColor = .clear
        self.backgroundColor = .clear
        plusLabel.layer.cornerRadius = 5
        plusLabel.layer.masksToBounds = true
        
        perksContainer.layer.cornerRadius = 5
        redirectContainer.layer.cornerRadius = 5
    }
    
    func applyLocalization() {
        perksTitleLabel.text = String.localize("PERKS_PLUS")
        perkOneLabel.text = String.localize("PERK_PLUS_ONE")
        perkTwoLabel.text = String.localize("PERK_PLUS_TWO")
        perkThreeLabel.text = String.localize("PERK_PLUS_THREE")
        perkFourLabel.text = String.localize("PERK_PLUS_FOUR")
        perkFiveLabel.text = String.localize("PERK_PLUS_FIVE")
    }
}
