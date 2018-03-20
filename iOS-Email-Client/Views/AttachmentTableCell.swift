//
//  AttachmentTableCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class AttachmentTableCell: UITableViewCell{
    @IBOutlet weak var attachmentLabel: UILabel!
    @IBOutlet weak var attachmentContainer: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        attachmentContainer.layer.borderWidth = 1
        attachmentContainer.layer.borderColor = UIColor(red:216/255, green:216/255, blue:216/255, alpha: 0.45).cgColor
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        // TO DO click attachment feature
    }
    
    func setNameAndSize(_ name: String, _ size: String){
        let nameAttrs = [NSAttributedStringKey.font : Font.bold.size(15.0), NSAttributedStringKey.foregroundColor : UIColor.black]
        let myName = NSMutableAttributedString(string: name + " ", attributes: nameAttrs)
        
        let sizeAttrs = [NSAttributedStringKey.font : Font.regular.size(12.0), NSAttributedStringKey.foregroundColor : UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)]
        let mySize = NSMutableAttributedString(string: "  \(size)", attributes: sizeAttrs)
        
        myName.append(mySize)
        attachmentLabel.attributedText = myName
    }
}
