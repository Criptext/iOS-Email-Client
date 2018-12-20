//
//  LabelsLabelTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class LabelsLabelTableViewCell: UITableViewCell{
    @IBOutlet weak var checkMarkView: CheckMarkUIView!
    @IBOutlet weak var labelLabel: UILabel!
    @IBOutlet weak var colorDotsContainer: UIView!
    @IBOutlet weak var colorDotsView: UIView!
    
    var theme: Theme {
        return ThemeManager.shared.theme
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
        labelLabel.textColor = theme.mainText
        backgroundColor = theme.background
    }
    
    func fillFields(label: Label) {
        let isDisabled = label.id == SystemLabel.starred.id
        labelLabel.text = label.localized
        checkMarkView.setChecked(label.visible, disabled: isDisabled)
        colorDotsView.backgroundColor = UIColor(hex: label.color)
    }
}
