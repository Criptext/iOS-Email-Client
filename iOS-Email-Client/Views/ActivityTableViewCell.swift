//
//  ActivityTableViewCell.swift
//  Criptext Secure Email
//
//  Created by Daniel Tigse on 4/6/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

protocol ActivityTableViewCellDelegate {
    func tableViewCellDidTapTimer(_ cell:ActivityTableViewCell)
    func tableViewCellDidTapAttachment(_ cell:ActivityTableViewCell)
    func tableViewCellDidTapLock(_ cell:ActivityTableViewCell)
    func tableViewCellDidTapUnsend(_ cell:ActivityTableViewCell)
    func tableViewCellDidTapMute(_ cell:ActivityTableViewCell)
}


class ActivityTableViewCell: UITableViewCell {
    
    @IBOutlet weak var unsendView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var unsendLabel: UILabel!
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var openedLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var locationImageView: UIImageView!
    @IBOutlet weak var timerView: UIView!
    @IBOutlet weak var attachmentView: UIView!
    @IBOutlet weak var lockView: UIView!
    @IBOutlet weak var timerImageView: UIImageView!
    @IBOutlet weak var attachmentImageView: UIImageView!
    @IBOutlet weak var lockImageView: UIImageView!
    @IBOutlet weak var stackViewButtons: UIStackView!
    @IBOutlet weak var buttonUnsend: UIButton!
    @IBOutlet weak var muteView: UIView!
    @IBOutlet weak var muteImageView: UIImageView!
    
    @IBOutlet weak var noActivityTitleLabel: UILabel!
    @IBOutlet weak var noActivityDescriptionLabel: UILabel!
    @IBOutlet weak var noActivityTitleWidthConstraint: NSLayoutConstraint! //35, 53
    
    var tapGestureRecognizer:UITapGestureRecognizer!
    var delegate:ActivityTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.lockView.isUserInteractionEnabled = true
        self.lockImageView.isUserInteractionEnabled = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
        self.tapGestureRecognizer = tap
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        
        let touchPt = gestureRecognizer.location(in: self.containerView)
        
        guard let tappedView = self.hitTest(touchPt, with: nil) else {
            return
        }
        
        if tappedView == self.attachmentImageView || tappedView == self.attachmentView{
            delegate.tableViewCellDidTapAttachment(self)
        } else if tappedView == self.timerImageView || tappedView == self.timerView{
            delegate.tableViewCellDidTapTimer(self)
        } else if tappedView == self.lockImageView || tappedView == self.lockView{
            delegate.tableViewCellDidTapLock(self)
        } else if tappedView == self.muteImageView || tappedView == self.muteView {
            delegate.tableViewCellDidTapMute(self)
        }
    }
    
    @IBAction func didPressUnsend(_ sender: UIBarButtonItem) {
        
        guard let delegate = self.delegate else {
            return
        }
        
        delegate.tableViewCellDidTapUnsend(self)
    }
    
}
