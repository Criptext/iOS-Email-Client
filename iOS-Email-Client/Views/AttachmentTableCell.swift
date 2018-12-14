//
//  AttachmentTableCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit

protocol AttachmentTableCellDelegate {
    func tableVCellDidTapReadOnly(_ cell:AttachmentTableCell)
    func tableCellDidTapPassword(_ cell:AttachmentTableCell)
    func tableCellDidTapRemove(_ cell:AttachmentTableCell)
    func tableCellDidTap(_ cell:AttachmentTableCell)
}

class AttachmentTableCell: UITableViewCell{
    @IBOutlet weak var attachmentLabel: UILabel!
    @IBOutlet weak var attachmentSizeLabel: UILabel!
    @IBOutlet weak var attachmentContainer: UIView!
    @IBOutlet weak var typeView: UIImageView!
    @IBOutlet weak var lockView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var markImageView: UIImageView!
    @IBOutlet weak var iconDownloadImageView: UIImageView!
    @IBOutlet weak var viewClose: UIView!
    @IBOutlet weak var buttonClose: UIButton!
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    var holdGestureRecognizer:UILongPressGestureRecognizer!
    var delegate: AttachmentTableCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.attachmentContainer.layer.borderColor = UIColor(red:216/255, green:216/255, blue:216/255, alpha: 0.45).cgColor
        self.attachmentContainer.layer.borderWidth = 1.5
        self.attachmentContainer.layer.cornerRadius = 6.0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap
        
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(hold)
        self.holdGestureRecognizer = hold
        
        self.viewClose.layer.borderColor = UIColor(red:0.89, green:0.89, blue:0.89, alpha:1.0).cgColor
        self.buttonClose.addTarget(self, action: #selector(didPressCloseButton(_:)), for: .touchUpInside)
    }
    
    @objc func didPressCloseButton(_ view: UIButton){
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableCellDidTapRemove(self)
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableCellDidTap(self)
    }
    
    @objc func handleLongPress(_ gestureRecognizer:UITapGestureRecognizer){
        
    }

    func setFields(_ attachment: File){
        setNameAndSize(attachment.name, attachment.prettyPrintSize())
        setAttachmentType(attachment.mimeType)
        progressView.setProgress(Float(attachment.progress)/100.0, animated: false)
        progressView.isHidden = attachment.requestStatus != .processing && attachment.requestStatus != .pending
        if (attachment.requestStatus == .finish || attachment.requestStatus == .failed){
            setMarkIcon(success: attachment.requestStatus == .finish)
        } else {
            markImageView.isHidden = true
        }
    }
    
    func setNameAndSize(_ name: String, _ size: String){
        let nameAttrs = [NSAttributedString.Key.foregroundColor : UIColor.black]
        let myName = NSMutableAttributedString(string: name + " ", attributes: nameAttrs)
        
        let sizeAttrs = [NSAttributedString.Key.foregroundColor : UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)]
        let mySize = NSMutableAttributedString(string: "  \(size)", attributes: sizeAttrs)
        attachmentLabel.attributedText = myName
        attachmentSizeLabel.attributedText = mySize
    }
    
    func setAttachmentType(_ mimeType: String){
        typeView.image = Utils.getImageByFileType(mimeType)
    }
    
    func setAsUnsend(){
        let attrs = [NSAttributedString.Key.font : Font.bold.size(15.0)!, NSAttributedString.Key.foregroundColor : UIColor.black]
        let myName = NSMutableAttributedString(string: "Attachment Unsent", attributes: attrs)
        attachmentLabel.attributedText = myName
        progressView.isHidden = true
        markImageView.isHidden = true
        iconDownloadImageView.isHidden = true
        typeView.image = #imageLiteral(resourceName: "attachment_expired")
    }
    
    func setMarkIcon(success: Bool){
        markImageView.isHidden = false
        guard success else {
            markImageView.image = #imageLiteral(resourceName: "mark-error")
            markImageView.backgroundColor = .alert
            return
        }
        progressView.isHidden = true
        markImageView.image = #imageLiteral(resourceName: "mark-success")
        markImageView.backgroundColor = .mainUI
    }
}
