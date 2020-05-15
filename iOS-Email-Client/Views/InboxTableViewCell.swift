//
//  EmailTableViewCell.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/9/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

protocol InboxTableViewCellDelegate: class {
    func tableViewCellDidLongPress(_ cell:InboxTableViewCell)
}

class InboxTableViewCell: UITableViewCell {
    let SUBJECT_MAX_WIDTH : CGFloat = 250.0
    @IBOutlet weak var senderLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var previewLabel: UILabel!
    
    @IBOutlet weak var secureAttachmentImageView: UIImageView!
    @IBOutlet weak var secureLockImageView: UIImageView!
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarBorderView: UIImageView!
    @IBOutlet weak var containerBadge: UIView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var badgeWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var subjectWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var readWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var readImageView: UIImageView!
    @IBOutlet weak var starredImageView: UIImageView!
    
    weak var delegate:InboxTableViewCellDelegate?
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(hold)
        
        let myView = UIView()
        myView.backgroundColor = UIColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.2)
        self.selectedBackgroundView = myView
    }
    
    @objc func handleLongPress(_ gestureRecognizer:UILongPressGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tableViewCellDidLongPress(self)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        if highlighted {
            containerBadge.backgroundColor = theme.threadBadge
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            containerBadge.backgroundColor = theme.threadBadge
        }
    }
    
    func setFields(thread: Thread, label: Int, myEmail: String){
        containerBadge.backgroundColor = theme.threadBadge
        subjectLabel.textColor = theme.mainText
        senderLabel.textColor = theme.mainText
        dateLabel.textColor = theme.secondText
        secureAttachmentImageView.isHidden = true
        secureAttachmentImageView.tintColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0)
        secureLockImageView.isHidden = true
        secureLockImageView.tintColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0)
        
        senderLabel.attributedText =  thread.buildContactString(theme: theme, fontSize: 15.0)
        if !thread.unread {
            backgroundColor = theme.background
            senderLabel.font = Font.regular.size(15)
        }else{
            backgroundColor = theme.secondBackground
            senderLabel.font = Font.bold.size(15)
        }
        subjectLabel.text = thread.subject == "" ? String.localize("NO_SUBJECT") : thread.subject
        dateLabel.text = thread.getFormattedDate()
        
        
        previewLabel.text = thread.preview.isEmpty ? String.localize("NO_CONTENT") : thread.preview
        
        if(thread.isUnsent){
            previewLabel.textColor = .alertText
            previewLabel.font = Font.italic.size(15.0)!
        } else if thread.preview.isEmpty {
            previewLabel.textColor = theme.secondText
            previewLabel.font = Font.italic.size(15.0)!
        } else {
            previewLabel.textColor = theme.secondText
            previewLabel.font = Font.regular.size(15.0)!
        }
        
        let size = dateLabel.sizeThatFits(CGSize(width: 130, height: 21))
        dateWidthConstraint.constant = size.width
        
        let subjectSize = subjectLabel.sizeThatFits(CGSize(width: SUBJECT_MAX_WIDTH, height: 20))
        subjectWidthConstraint.constant = subjectSize.width > SUBJECT_MAX_WIDTH ? SUBJECT_MAX_WIDTH : subjectSize.width
        
        setReadStatus(status: thread.status)
        setBadge(thread.counter)
        starredImageView.isHidden = !thread.isStarred
        secureAttachmentImageView.isHidden = !thread.hasAttachments
        secureLockImageView.isHidden = !thread.isSecure
    }
    
    func setReadStatus(status: Email.Status){
        readWidthConstraint.constant = status == .none ? 0.0 : 23.0
        readImageView.isHidden = status == .none
        switch(status){
        case .none:
            break
        case .sent:
            readImageView.image = #imageLiteral(resourceName: "single-check-icon")
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
        case .sending, .fail:
            readImageView.image = #imageLiteral(resourceName: "waiting-icon")
            readImageView.tintColor = UIColor(red: 182/255, green: 182/255, blue: 182/255, alpha: 1)
        }
    }
    
    func setAsSelected(){
        backgroundColor = theme.cellHighlight
        avatarImageView.layer.backgroundColor = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.0).cgColor
        avatarImageView.image = #imageLiteral(resourceName: "check")
        avatarImageView.contentMode = .center
        avatarImageView.tintColor = UIColor.white
        avatarImageView.layer.borderWidth = 2.0
        avatarImageView.layer.borderColor = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.0).cgColor
        containerBadge.backgroundColor = theme.threadBadge
    }
    
    func setAsNotSelected(){
        avatarImageView.image = nil
        avatarImageView.layer.borderWidth = 2.0
        avatarImageView.layer.borderColor = theme.separator.cgColor
        avatarImageView.layer.backgroundColor = UIColor.clear.cgColor
        containerBadge.backgroundColor = theme.threadBadge
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
