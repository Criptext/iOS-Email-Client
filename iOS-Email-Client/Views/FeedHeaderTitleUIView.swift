//
//  FeedHeaderTitleUIView.swift
//  iOS-Email-Client
//
//  Created by Allisson on 12/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class FeedHeaderTitleUIView: UIView {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        backgroundColor = theme.menuHeader
        titleLabel.textColor = theme.mainText
        iconImageView.tintColor = theme.mainText
    }
    
}
