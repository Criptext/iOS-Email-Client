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
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var containerBadge: UIView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var badgeWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var readWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var readImageView: UIImageView!
    
    var holdGestureRecognizer:UILongPressGestureRecognizer!
    var delegate:InboxTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(hold)
        self.holdGestureRecognizer = hold
    }
    
    @objc func handleLongPress(_ gestureRecognizer:UILongPressGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tableViewCellDidLongPress(self)
    }
    
    func setReadStatus(status: Email.Status){
        readWidthConstraint.constant = status == .none ? 0.0 : 17.0
        readImageView.isHidden = status == .none
        switch(status){
        case .none:
            break
        case .sent:
            readImageView.image = #imageLiteral(resourceName: "double-check")
            readImageView.tintColor = UIColor(red: 182/255, green: 182/255, blue: 182/255, alpha: 1)
        case .delivered:
            readImageView.image = #imageLiteral(resourceName: "double-check")
            readImageView.tintColor = UIColor(red: 182/255, green: 182/255, blue: 182/255, alpha: 1)
        case .opened:
            readImageView.image = #imageLiteral(resourceName: "double-check")
            readImageView.tintColor = .mainUI
        case .unsent:
            readWidthConstraint.constant = 0.0
            readImageView.isHidden = true
        }
    }
    
    func setAsSelected(){
        backgroundColor = UIColor(red:253/255, green:251/255, blue:235/255, alpha:1.0)
        avatarImageView.layer.backgroundColor = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.0).cgColor
        avatarImageView.image = #imageLiteral(resourceName: "check")
        avatarImageView.tintColor = UIColor.white
        avatarImageView.layer.borderWidth = 1.0
        avatarImageView.layer.borderColor = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.0).cgColor
    }
    
    func setAsNotSelected(){
        avatarImageView.image = nil
        avatarImageView.layer.borderWidth = 1.0
        avatarImageView.layer.borderColor = UIColor.lightGray.cgColor
        avatarImageView.layer.backgroundColor = UIColor.lightGray.cgColor
    }
    
    func setBadge(_ value: Int){
        guard value > 1 else {
            containerBadge.isHidden = true
            return
        }
        containerBadge.isHidden = false
        badgeLabel.text = value.description
        switch value {
        case _ where value > 9:
            badgeWidthConstraint.constant = 20
            break
        case _ where value > 99:
            badgeWidthConstraint.constant = 25
            break
        default:
            badgeWidthConstraint.constant = 20
            break
        }
    }
}
