//
//  LabelsHeaderCellView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 12/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class LabelsHeaderCellView: UITableViewHeaderFooterView {
    @IBOutlet weak var headerLabel: UILabel!
    
    override func awakeFromNib() {
        applyTheme()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.applyTheme()
    }
    
    func applyTheme() {
        headerLabel.textColor = ThemeManager.shared.theme.mainText
    }
}
