//
//  EmailTableViewCell.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/9/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

protocol InboxTableViewCellDelegate {
    func tableViewCellDidLongPress(_ cell:InboxTableViewCell)
}

class InboxTableViewCell: UITableViewCell {
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var previewLabel: UILabel!
    
    @IBOutlet weak var secureAttachmentImageView: UIImageView!
    
    @IBOutlet weak var containerBadge: UIView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var badgeWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateWidthConstraint: NSLayoutConstraint!
    
    var holdGestureRecognizer:UILongPressGestureRecognizer!
    var delegate:InboxTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(hold)
        self.holdGestureRecognizer = hold
        
        let view = UIView()
        view.backgroundColor = UIColor(red:0.98, green:0.98, blue:0.98, alpha:1.0)
        self.selectedBackgroundView = view
    }
    
    @objc func handleLongPress(_ gestureRecognizer:UILongPressGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tableViewCellDidLongPress(self)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            self.containerBadge.backgroundColor = UIColor(red:0.76, green:0.76, blue:0.78, alpha:1.0)
            self.tintColor = Icon.system.color
        } else {
            self.tintColor = UIColor.black
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            self.containerBadge.backgroundColor = UIColor(red:0.76, green:0.76, blue:0.78, alpha:1.0)
        }
    }
}
