//
//  TableEndCellView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class TableEndViewCell: UITableViewCell{
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var messageLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        loader.color = .black
        loader.activityIndicatorViewStyle = .gray
        isUserInteractionEnabled = false
        backgroundColor = .clear
    }
    
    func displayLoader(){
        messageLabel.isHidden = true
        loader.isHidden = false
        loader.startAnimating()
    }
    
    func displayMessage(_ message: String){
        messageLabel.isHidden = false
        messageLabel.text = message
        loader.stopAnimating()
        loader.isHidden = true
    }
}
