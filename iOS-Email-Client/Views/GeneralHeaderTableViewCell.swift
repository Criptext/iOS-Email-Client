//
//  GeneralHeaderTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class GeneralHeaderTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        titleLabel.textColor = theme.mainText
        contentView.backgroundColor = theme.settingsDetail
    }
}
