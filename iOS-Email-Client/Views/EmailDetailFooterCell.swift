//
//  EmailDetailFooterCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/2/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class EmailDetailFooterCell: UITableViewCell{
    
    
    @IBAction func onPressReply(_ sender: Any) {
        print("Reply!")
    }
    
    @IBAction func onPressReplyAll(_ sender: Any) {
        print("Reply All!")
    }
    
    @IBAction func onPressForward(_ sender: Any) {
        print("Forward!")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
    }
    
    func setupView(){
    }
}
