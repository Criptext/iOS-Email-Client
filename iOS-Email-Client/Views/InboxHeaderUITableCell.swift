//
//  InboxHeaderUITableCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class InboxHeaderUITableCell: UITableViewCell {
    var onEmptyPress: (() -> Void)?
    
    @IBAction func onEmptyTrashPress(_ sender: Any) {
        onEmptyPress?()
    }
    
}
