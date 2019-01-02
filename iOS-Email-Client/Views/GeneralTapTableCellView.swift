//
//  GeneralTapTableCellView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class GeneralTapTableCellView : UITableViewCell {
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var goImageView: UIImageView!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        optionLabel.textColor = theme.mainText
        messageLabel.textColor = theme.secondText
        backgroundColor = .clear
    }
}
