//
//  EmailDetailHeaderCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import TagListView

class EmailDetailHeaderCell: UITableViewCell{
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var subjectHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelsListView: TagListView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        labelsListView.textFont = Font.regular.size(12.0)!
        labelsListView.marginX = 10.0
        labelsListView.marginY = 9.0
        labelsListView.paddingX = 10.0
        labelsListView.paddingY = 3.0
        labelsListView.cornerRadius = 8
    }
    
    func addLabels(_ labels: [Label]){
        guard labelsListView.tagViews.count == 0 else {
            return
        }
        for label in labels {
            let tag = labelsListView.addTag(label.text)
            tag.tagBackgroundColor = UIColor(hex: label.color)
        }
        labelsListView.invalidateIntrinsicContentSize()
    }
    
    func setSubject(_ subject: String){
        subjectLabel.text = subject
        subjectLabel.numberOfLines = 0
        let myHeight = Utils.getLabelHeight(subject, width: subjectLabel.frame.width, fontSize: 21.0)
        subjectHeightConstraint.constant = myHeight
    }
    
}
