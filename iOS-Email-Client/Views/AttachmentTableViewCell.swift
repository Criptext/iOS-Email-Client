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
    func tableViewCellDidTapRemove(_ cell:AttachmentTableViewCell)
    func tableViewCellDidTap(_ cell:AttachmentTableViewCell)
}

class AttachmentTableViewCell: UITableViewCell {
    
    
    @IBOutlet weak var contentContainerView: UIView!
    
    @IBOutlet weak var lockImageView: UIImageView!
    @IBOutlet weak var typeImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var viewClose: UIView!
    @IBOutlet weak var buttonClose: UIButton!
    @IBOutlet weak var successImageView: UIImageView!
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    var holdGestureRecognizer:UILongPressGestureRecognizer!
    var delegate:AttachmentTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.contentContainerView.layer.borderWidth = 1.5
        self.contentContainerView.layer.cornerRadius = 6.0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap
        
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(hold)
        self.holdGestureRecognizer = hold
        
        self.buttonClose.addTarget(self, action: #selector(didPressCloseButton(_:)), for: .touchUpInside)
        applyTheme()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        backgroundColor = .clear
        contentContainerView.backgroundColor = theme.attachmentCell
        contentContainerView.layer.borderColor = theme.attachmentBorder.cgColor
        viewClose.backgroundColor = theme.attachmentCell
        viewClose.layer.borderColor = theme.mainText.cgColor
        nameLabel.textColor = theme.markedText
        sizeLabel.textColor = theme.secondText
        buttonClose.imageView?.tintColor = theme.mainText
    }
    
    @objc func didPressCloseButton(_ view: UIButton){
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidTapRemove(self)
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidTap(self)
    }
    
    @objc func handleLongPress(_ gestureRecognizer:UITapGestureRecognizer){
        
    }
    
    func setMarkIcon(success: Bool){
        successImageView.isHidden = false
        guard success else {
            successImageView.image = #imageLiteral(resourceName: "mark-error")
            successImageView.backgroundColor = .alert
            return
        }
        progressView.isHidden = true
        successImageView.image = #imageLiteral(resourceName: "mark-success")
        successImageView.backgroundColor = .mainUI
    }
}
