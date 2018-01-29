//
//  AttachmentTableViewCell.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 4/5/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

protocol AttachmentTableViewCellDelegate {
    func tableViewCellDidTapReadOnly(_ cell:AttachmentTableViewCell)
    func tableViewCellDidTapPassword(_ cell:AttachmentTableViewCell)
    func tableViewCellDidLongPress(_ cell:AttachmentTableViewCell)
    func tableViewCellDidTap(_ cell:AttachmentTableViewCell)
}

class AttachmentTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var contentContainerView: UIView!
    
    @IBOutlet weak var lockImageView: UIImageView!
    @IBOutlet weak var typeImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var readOnlyContainerView: UIView!
    @IBOutlet weak var readOnlyImageView: UIImageView!
    @IBOutlet weak var readOnlyLabel: UILabel!
    @IBOutlet weak var passwordContainerView: UIView!
    @IBOutlet weak var passwordImageView: UIImageView!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    var holdGestureRecognizer:UILongPressGestureRecognizer!
    var delegate:AttachmentTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.passwordContainerView.isUserInteractionEnabled = true
        self.passwordLabel.isUserInteractionEnabled = true
        self.passwordImageView.isUserInteractionEnabled = true
        
        self.readOnlyContainerView.isUserInteractionEnabled = true
        self.readOnlyLabel.isUserInteractionEnabled = true
        self.readOnlyImageView.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap
        
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(hold)
        self.holdGestureRecognizer = hold
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        
        let touchPt = gestureRecognizer.location(in: self.contentContainerView)
        
        guard let tappedView = self.hitTest(touchPt, with: nil) else {
            return
        }
        
        if tappedView == self.readOnlyContainerView{
            delegate.tableViewCellDidTapReadOnly(self)
        } else if tappedView == self.passwordContainerView{
            delegate.tableViewCellDidTapPassword(self)
        } else {
            delegate.tableViewCellDidTap(self)
        }
    }
    
    @objc func handleLongPress(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tableViewCellDidLongPress(self)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.contentContainerView.backgroundColor = UIColor.lightGray
        }else{
            self.contentContainerView.backgroundColor = UIColor.white
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        //do nothing
    }
}
