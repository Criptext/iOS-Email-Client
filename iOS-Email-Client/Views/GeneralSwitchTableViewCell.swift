//
//  GeneralSwitchTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class GeneralSwitchTableViewCell: UITableViewCell {
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak var availableSwitch: UISwitch!
    var switchToggle: ((Bool) -> Void)?
    
    @IBAction func onSwitchToggle(_ sender: Any) {
        switchToggle?(availableSwitch.isOn)
    }
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
    
    func applyTheme() {
        optionLabel.textColor = theme.mainText
        backgroundColor = .clear
    }
}
