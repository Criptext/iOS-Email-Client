//
//  LabelsFooterViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/2/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class LabelsFooterViewCell: UITableViewHeaderFooterView {
    @IBOutlet weak var footerLabel: UILabel!
    @IBOutlet weak var plusImage: UIImageView!
    var onTapCell: (() -> Void)?
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tapCell))
        self.contentView.addGestureRecognizer(gesture)
        applyTheme()
    }
    
    @objc func tapCell(){
        self.onTapCell?()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.applyTheme()
    }
    
    func applyTheme() {
        footerLabel.textColor = theme.underSelector
        plusImage.tintColor = theme.underSelector
    }
}
