//
//  EmailDetailHeaderCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import TagListView

class EmailDetailHeaderCell: UITableViewHeaderFooterView{
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var subjectHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelsListView: TagListView!
    @IBOutlet weak var starButton: UIButton!
    @IBOutlet weak var marginTopView: UIView!
    @IBOutlet weak var marginBottomView: UIView!
    var onStarPressed: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        labelsListView.textFont = Font.regular.size(12.0)!
        labelsListView.marginX = 10.0
        labelsListView.marginY = 9.0
        labelsListView.paddingX = 10.0
        labelsListView.paddingY = 3.0
        labelsListView.cornerRadius = 8
        applyTheme()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        subjectLabel.textColor = theme.mainText
        contentView.backgroundColor = .clear
    }
    
    func addLabels(_ labels: [Label]){
        labelsListView.removeAllTags()
        var starredImage = #imageLiteral(resourceName: "starred_empty")
        for label in labels {
            guard label.id != SystemLabel.inbox.id && label.id != SystemLabel.sent.id else {
                continue
            }
            guard label.id != SystemLabel.starred.id else {
                starredImage = #imageLiteral(resourceName: "starred_full")
                continue
            }
            let tag = labelsListView.addTag(label.localized)
            tag.tagBackgroundColor = UIColor(hex: label.color)
        }
        labelsListView.invalidateIntrinsicContentSize()
        starButton.setImage(starredImage, for: .normal)
        let hideTagsViews = labelsListView.tagViews.count == 0
        marginTopView.isHidden = hideTagsViews
        marginBottomView.isHidden = hideTagsViews
        labelsListView.isHidden = hideTagsViews
    }
    
    func setSubject(_ subject: String){
        let mySubject = subject.isEmpty ? String.localize("NO_SUBJECT") : subject
        subjectLabel.text = mySubject
        subjectLabel.numberOfLines = 0
        let myHeight = UIUtils.getLabelHeight(mySubject, width: subjectLabel.frame.width, fontSize: 21.0)
        subjectHeightConstraint.constant = myHeight
    }
    
    @IBAction func onStarButtonPressed(_ sender: Any) {
        self.onStarPressed?()
    }
}
