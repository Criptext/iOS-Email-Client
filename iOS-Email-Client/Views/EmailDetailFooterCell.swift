//
//  EmailDetailFooterCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/2/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol EmailDetailFooterDelegate {
    func onPressReply()
    func onPressReplyAll()
    func onPressForward()
}

class EmailDetailFooterCell: UITableViewCell{
    
    var delegate : EmailDetailFooterDelegate?
    
    @IBAction func onPressReply(_ sender: Any) {
        delegate?.onPressReply()
    }
    
    @IBAction func onPressReplyAll(_ sender: Any) {
        delegate?.onPressReplyAll()
    }
    
    @IBAction func onPressForward(_ sender: Any) {
        delegate?.onPressForward()
    }
}
