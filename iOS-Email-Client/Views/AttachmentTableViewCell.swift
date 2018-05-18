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
        
        self.contentContainerView.layer.borderColor = UIColor(hex:"f6f6f6").cgColor
        self.contentContainerView.layer.borderWidth = 1.5
        self.contentContainerView.layer.cornerRadius = 6.0
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap
        
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(hold)
        self.holdGestureRecognizer = hold
        
        self.viewClose.layer.borderColor = UIColor(hex:"e2e2e2").cgColor
        self.buttonClose.addTarget(self, action: #selector(didPressCloseButton(_:)), for: .touchUpInside)
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
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tableViewCellDidTapRemove(self)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        if highlighted {
            self.contentContainerView.backgroundColor = UIColor.lightGray
        }else{
            self.contentContainerView.backgroundColor = UIColor(hex:"FAFAFA")
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        //do nothing
    }
}
