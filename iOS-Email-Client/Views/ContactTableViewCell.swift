//
//  ContactTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Daniel Tigse on 3/1/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ContactTableViewCell: UITableViewCell{
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let theme = ThemeManager.shared.theme
        nameLabel.textColor = theme.mainText
        emailLabel.textColor = theme.secondText
        backgroundColor = .clear
    }
    
}
