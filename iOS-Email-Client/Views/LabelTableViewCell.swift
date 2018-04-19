//
//  LabelTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/18/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class LabelTableViewCell : UITableViewCell {
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var descTextLabel: UILabel!
    @IBOutlet weak var checkMarkView: CheckMarkUIView!
    
    func setLabel(_ text: String, color: UIColor){
        dotView.backgroundColor = color
        descTextLabel.text = text
    }
    
    func setAsSelected(){
        checkMarkView.setChecked(true)
    }
    
    func setAsDeselected(){
        checkMarkView.setChecked(false)
    }
}
