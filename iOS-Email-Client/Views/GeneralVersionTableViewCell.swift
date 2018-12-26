//
//  GeneralVersionTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/12/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class GeneralVersionTableViewCell: UITableViewCell {
    @IBOutlet weak var versionLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
    
    func applyTheme() {
        backgroundColor = .clear
    }
}
