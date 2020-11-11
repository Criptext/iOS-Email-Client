//
//  SetSettingsTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/10/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class SetSettingsTableViewCell: UITableViewCell {
    @IBOutlet weak var settingLabel: UILabel!
    @IBOutlet weak var activateSwitch: UISwitch!
    var onToggle: ((Setting, Bool) -> Void)?
    var setting: Setting?
    
    enum Setting {
        case theme
        case contacts
        case notifications
        case backup
        
        var description: String {
            switch(self) {
            case .theme:
                return String.localize("SET_THEME")
            case .contacts:
                return String.localize("SET_CONTACTS")
            case .notifications:
                return String.localize("SET_NOTIFICATIONS")
            case .backup:
                return String.localize("SET_BACKUP")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        activateSwitch.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        applyTheme()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        settingLabel.textColor = theme.markedText
        activateSwitch.tintColor = theme.criptextBlue
        self.contentView.backgroundColor = .clear
        self.backgroundColor = .clear
    }
    
    func setContent(setting: Setting, activated: Bool) {
        settingLabel.text = setting.description
        activateSwitch.isOn = activated
    }
    
    @IBAction func onActivateToggle(_ sender: UISwitch) {
        guard let mySetting = setting else {
            return
        }
        onToggle?(mySetting, sender.isOn)
    }
}
