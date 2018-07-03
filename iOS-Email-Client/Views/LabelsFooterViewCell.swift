//
//  LabelsFooterViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/2/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class LabelsFooterViewCell: UITableViewHeaderFooterView {
    var onTapCell: (() -> Void)?
    
    override func awakeFromNib() {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.tapCell))
        self.contentView.addGestureRecognizer(gesture)
    }
    
    @objc func tapCell(){
        self.onTapCell?()
    }
}
