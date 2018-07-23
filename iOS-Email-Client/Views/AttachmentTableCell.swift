//
//  AttachmentTableCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol AttachmentTableCellDelegate {
    func tableCellDidTap(_ cell: AttachmentTableCell)
}

class AttachmentTableCell: UITableViewCell{
    @IBOutlet weak var attachmentLabel: UILabel!
    @IBOutlet weak var attachmentContainer: UIView!
    @IBOutlet weak var typeView: UIImageView!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var markImageView: UIImageView!
    @IBOutlet weak var iconDownloadImageView: UIImageView!
    var delegate: AttachmentTableCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        attachmentContainer.layer.borderWidth = 1
        attachmentContainer.layer.borderColor = UIColor(red:216/255, green:216/255, blue:216/255, alpha: 0.45).cgColor
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        delegate?.tableCellDidTap(self)
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
        let nameAttrs = [NSAttributedStringKey.font : Font.bold.size(15.0)!, NSAttributedStringKey.foregroundColor : UIColor.black]
        let myName = NSMutableAttributedString(string: name + " ", attributes: nameAttrs)
        
        let sizeAttrs = [NSAttributedStringKey.font : Font.regular.size(12.0)!, NSAttributedStringKey.foregroundColor : UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)]
        let mySize = NSMutableAttributedString(string: "  \(size)", attributes: sizeAttrs)
        
        myName.append(mySize)
        attachmentLabel.attributedText = myName
    }
    
    func setAttachmentType(_ mimeType: String){
        typeView.image = Utils.getImageByFileType(mimeType)
    }
    
    func setAsUnsend(){
        let attrs = [NSAttributedStringKey.font : Font.bold.size(15.0)!, NSAttributedStringKey.foregroundColor : UIColor.black]
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
