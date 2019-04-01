//
//  AccountsFooterCell.swift
//  iOS-Email-Client
//
//  Created by Allisson on 3/13/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol AccountsFooterDelegate: class {
    func addAccount()
}

class AccountsFooterCell: UITableViewHeaderFooterView {
    @IBOutlet weak var existingContainerButton: UIButton!
    @IBOutlet weak var existingLabel: UILabel!
    @IBOutlet weak var existingIconImage: UIImageView!
    weak var delegate: AccountsFooterDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.applyTheme()
        self.applyLocalization()
    }
    
    func applyLocalization() {
        existingLabel.text = String.localize("ADD_ACCOUNT")
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        existingLabel.textColor = theme.mainText
        existingIconImage.tintColor = theme.criptextBlue
    }
    
    @IBAction func addAccount(sender: Any) {
        delegate?.addAccount()
    }
}
