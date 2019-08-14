//
//  SettingsGeneralHeaderView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 12/26/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SettingsGeneralHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        backgroundColor = .clear
        contentView.backgroundColor = theme.menuBackground
        titleLabel.textColor = theme.mainText
    }
}
