//
//  AccountTableCell.swift
//  iOS-Email-Client
//
//  Created by Allisson on 3/13/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class AccountTableCell: UITableViewCell {
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var badgeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let theme = ThemeManager.shared.theme
        nameLabel.textColor = theme.markedText
        emailLabel.textColor = theme.secondText
        badgeLabel.textColor = theme.criptextBlue
    }
    
    func setContent(account: Account, counter: Int) {
        UIUtils.setProfilePictureImage(imageView: self.avatarImage, contact: (account.email, account.name))
        nameLabel.text = account.name
        emailLabel.text = account.email
        badgeLabel.text = counter == 0 ? "" : counter.description
    }
}
