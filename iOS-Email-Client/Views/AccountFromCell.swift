//
//  AccountFromCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/9/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class AccountFromCell: UITableViewCell{
    @IBOutlet weak var emailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let theme = ThemeManager.shared.theme
        emailLabel.textColor = theme.mainText
        backgroundColor = .clear
    }
}
