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
    
    override func awakeFromNib() {
        goImageView.transform = goImageView.transform.rotated(by: CGFloat(Double.pi * 1.5))
    }
}
