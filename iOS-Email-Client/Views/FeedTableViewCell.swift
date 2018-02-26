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
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
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
            headerLabel.font = UIFont.systemFont(ofSize: headerLabel.font.pointSize)
            subjectLabel.font = UIFont.systemFont(ofSize: subjectLabel.font.pointSize)
            dateLabel.font = UIFont.systemFont(ofSize: dateLabel.font.pointSize)
            backgroundColor = .clear
            return
        }
        headerLabel.font = UIFont.boldSystemFont(ofSize: headerLabel.font.pointSize)
        subjectLabel.font = UIFont.boldSystemFont(ofSize: subjectLabel.font.pointSize)
        dateLabel.font = UIFont.boldSystemFont(ofSize: dateLabel.font.pointSize)
        backgroundColor = UIColor(red: 242/255, green: 248/255, blue: 1, alpha: 1)
        
    }
}
