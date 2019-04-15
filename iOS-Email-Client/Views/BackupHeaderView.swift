//
//  BackupHeaderView.swift
//  iOS-Email-Client
//
//  Created by Allisson on 4/4/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class BackupHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var backupLabel: UILabel!
    @IBOutlet weak var lastBackupLabel: UILabel!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var backupContainerView: UIView!
    @IBOutlet weak var detailContainerView: UIView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var cloudImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        progressView.layer.cornerRadius = 2
        progressView.layer.sublayers![1].cornerRadius = 2
        progressView.subviews[1].clipsToBounds = true
        
        let theme = ThemeManager.shared.theme
        
        backgroundColor = .clear
        emailLabel.textColor = theme.mainText
        backupLabel.textColor = theme.mainText
        lastBackupLabel.textColor = theme.mainText
        progressLabel.textColor = theme.menuText
        progressView.tintColor = theme.criptextBlue
        
        detailContainerView.backgroundColor = theme.settingsDetail
        detailLabel.textColor = theme.mainText
    }
    
    func setContent(email: String, isUploading: Bool, lastBackupDate: Date?, lastBackupSize: Int?) {
        emailLabel.text = email
        if let backupDate = lastBackupDate,
            let backupSize = lastBackupSize {
            setBackupContent(date: backupDate, size: backupSize)
        }
        
        backupContainerView.isHidden = !(isUploading || lastBackupDate != nil)
        if isUploading {
            progressView.isHidden = false
            progressLabel.isHidden = false
            lastBackupLabel.isHidden = true
            backupLabel.isHidden = true
            cloudImageView.image = UIImage(named: "cloud-small")
        } else if lastBackupDate != nil {
            progressView.isHidden = true
            progressLabel.isHidden = true
            lastBackupLabel.isHidden = false
            backupLabel.isHidden = false
            cloudImageView.image = UIImage(named: "cloud-success")
        } else {
            cloudImageView.image = UIImage(named: "cloud-small")
        }
    }
    
    func setBackupContent(date: Date, size: Int) {
        let attrStat = NSMutableAttributedString(string: String.localize("LAST_BACKUP"), attributes: [.font: Font.bold.size(16)!])
        attrStat.append(NSAttributedString(string: DateUtils.conversationTime(date), attributes: [.font: Font.regular.size(16)!]))
        
        let attrStat2 = NSMutableAttributedString(string: String.localize("BACKUP_SIZE"), attributes: [.font: Font.bold.size(16)!])
        attrStat2.append(NSAttributedString(string: File.prettyPrintSize(size: size), attributes: [.font: Font.regular.size(16)!]))
        
        lastBackupLabel.attributedText = attrStat
        backupLabel.attributedText = attrStat2
    }
}
