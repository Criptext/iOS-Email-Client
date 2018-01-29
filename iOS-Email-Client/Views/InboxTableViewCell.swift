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
    func tableViewCellDidTapTimer(_ cell:InboxTableViewCell)
    func tableViewCellDidTapAttachment(_ cell:InboxTableViewCell)
    func tableViewCellDidTapLock(_ cell:InboxTableViewCell)
    func tableViewCellDidTap(_ cell:InboxTableViewCell)
}

class InboxTableViewCell: UITableViewCell {
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var previewLabel: UILabel!
    
    @IBOutlet weak var respondMailView: UIView!
    @IBOutlet weak var respondMailImageView: UIImageView!
    
    @IBOutlet weak var lockView: UIView!
    @IBOutlet weak var lockImageView: UIImageView!
    
    @IBOutlet weak var secureAttachmentView: UIView!
    @IBOutlet weak var secureAttachmentImageView: UIImageView!
    
    @IBOutlet weak var attachmentView: UIView!
    @IBOutlet weak var attachmentImageView: UIImageView!
    
    @IBOutlet weak var timerView: UIView!
    @IBOutlet weak var timerImageView: UIImageView!
    
    @IBOutlet weak var containerBadge: UIView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var badgeWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var timerWidthConstraint: NSLayoutConstraint!
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    var holdGestureRecognizer:UILongPressGestureRecognizer!
    var delegate:InboxTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(hold)
        self.holdGestureRecognizer = hold
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap
        
        let view = UIView()
        view.backgroundColor = UIColor(red:0.98, green:0.98, blue:0.98, alpha:1.0)
        self.selectedBackgroundView = view
    }
    
    @objc func handleLongPress(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tableViewCellDidLongPress(self)
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        
        let touchPt = gestureRecognizer.location(in: self)
        
        guard let tappedView = self.hitTest(touchPt, with: nil) else {
            return
        }
        
        
        if tappedView == self.secureAttachmentImageView || tappedView == self.secureAttachmentView{
            delegate.tableViewCellDidTapAttachment(self)
        } else if tappedView == self.timerImageView || tappedView == self.timerView{
            delegate.tableViewCellDidTapTimer(self)
        } else if tappedView == self.lockImageView || tappedView == self.lockView{
            delegate.tableViewCellDidTapLock(self)
        } else {
            delegate.tableViewCellDidTap(self)
        }
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
