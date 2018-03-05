//
//  FeedTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class FeedTableViewCell: UITableViewCell{
    @IBOutlet weak var typeIconImage: UIImageView!
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var mutedIconImage: UIImageView!

    func setLabels(_ header: String, _ subject: String, _ myDate: String){
        headerLabel.text = header
        subjectLabel.text = subject
        dateLabel.text = myDate
    }
    
    func setIcons(isOpen: Bool, isMuted: Bool){
        if(isOpen){
            typeIconImage.image = UIImage(named: "read")
            typeIconImage.tintColor = UIColor(red: 0, green: 145/255, blue: 1, alpha: 1)
        }else{
            typeIconImage.image = UIImage(named: "attachment")
            typeIconImage.tintColor = UIColor(red: 212/255, green: 212/255, blue: 212/255, alpha: 1)
        }
        
        mutedIconImage.isHidden = !isMuted
    }
    
    func handleViewed(isNew: Bool){
        if(!isNew){
            let regularFont = Font.regular.size(FontSize.feed.rawValue)
            headerLabel.font = regularFont
            subjectLabel.font = regularFont
            dateLabel.font = Font.regular.size(FontSize.feedDate.rawValue)
            backgroundColor = .white
            return
        }
        let boldFont = Font.bold.size(FontSize.feed.rawValue)
        headerLabel.font = boldFont
        subjectLabel.font = boldFont
        dateLabel.font = Font.bold.size(FontSize.feedDate.rawValue)
        backgroundColor = UIColor(red: 242/255, green: 248/255, blue: 1, alpha: 1)
        
    }
}
