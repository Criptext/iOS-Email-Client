//
//  AttachmentHistoryTableCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/8/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class AttachmentHistoryTableCell: UITableViewCell{
    @IBOutlet weak var contactActionLabel: UILabel!
    @IBOutlet weak var typeImage: UIImageView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var fileNameLabel: UILabel!
    
    func setLabels(_ action: String, _ filename: String, _ date: String){
        contactActionLabel.text = action
        fileNameLabel.text = filename
        dateLabel.text = date
    }
}
