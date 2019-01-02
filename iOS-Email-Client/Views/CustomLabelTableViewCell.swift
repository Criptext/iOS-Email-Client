//
//  CustomLabelTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class CustomLabelTableViewCell: UITableViewCell{
    @IBOutlet weak var myTextLabel: UILabel!
    @IBOutlet weak var dotView: UIView!
    
    func setLabel(_ text: String, color: UIColor){
        myTextLabel.text = text
        dotView.backgroundColor = color
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
        let theme = ThemeManager.shared.theme
        backgroundColor = .clear
        myTextLabel.textColor = theme.mainText
    }
}
