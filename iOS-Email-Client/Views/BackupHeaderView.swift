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
    @IBOutlet weak var detailContainerView: UIView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var cancelButton: UIButton!
    
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
        
        detailContainerView.backgroundColor = theme.cellHighlight
        detailLabel.textColor = theme.secondText
        
        cancelButton.imageView?.tintColor = theme.markedText
    }
}
