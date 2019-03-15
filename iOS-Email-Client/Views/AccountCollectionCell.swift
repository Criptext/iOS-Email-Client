//
//  AccountCollectionCell.swift
//  iOS-Email-Client
//
//  Created by Allisson on 3/14/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class AccountCollectionCell: UICollectionViewCell {
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var badgeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let theme = ThemeManager.shared.theme
        badgeLabel.backgroundColor = theme.criptextBlue
    }
    
    func setContent(account: Account, counter: Int) {
        UIUtils.setProfilePictureImage(imageView: avatarImage, contact: (account.email, account.name))
        if counter == 0 {
            badgeLabel.isHidden = true
        } else {
            badgeLabel.isHidden = false
            badgeLabel.text = counter.description
        }
        backgroundColor = .clear
    }
}
