//
//  ReadHistoryTableCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/9/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ReadHistoryTableCell: UITableViewCell{
    @IBOutlet weak var contactLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    func setLabels(_ contact: String, _ date: String){
        contactLabel.text = contact
        dateLabel.text = date
    }
}
