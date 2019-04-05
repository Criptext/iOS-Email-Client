//
//  PrivacyUIViewCell.swift
//  iOS-Email-Client
//
//  Created by Allisson on 12/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class PrivacyUIViewCell: UITableViewCell {
    var switchToggle: ((Bool) -> Void)?
    @IBOutlet weak var detailContainerView: UIView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var optionSwitch: UISwitch!
    @IBOutlet weak var optionNextImage: UIImageView!
    @IBOutlet weak var optionTextLabel: UILabel!
    @IBOutlet weak var optionPickLabel: UILabel!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        optionSwitch.transform = CGAffineTransform(scaleX: 0.67, y: 0.67)
        optionSwitch.isUserInteractionEnabled = false
        applyTheme()
    }
    
    func applyTheme() {
        backgroundColor = .clear
        detailContainerView.backgroundColor = theme.cellHighlight
        detailLabel.textColor = theme.secondText
    }
    
    func fillFields(option: SecurityPrivacyViewController.PrivacyOption) {
        detailContainerView.isHidden = option.detail == nil
        detailLabel.text = option.detail
        optionNextImage.isHidden = !option.hasFlow
        optionSwitch.isHidden = option.isOn == nil
        optionSwitch.isOn = option.isOn ?? false
        optionTextLabel.text = String.localize(option.label.description)
        optionPickLabel.isHidden = option.pick == nil
        optionPickLabel.text = String.localize(option.pick ?? "")
        if option.isEnabled {
            optionTextLabel.textColor = theme.mainText
            optionPickLabel.textColor = theme.underSelector
            optionSwitch.isEnabled = true
        } else {
            optionTextLabel.textColor = theme.placeholder
            optionPickLabel.textColor = theme.placeholder
            optionSwitch.isEnabled = false
        }
    }
    
    func fillFields(option: BackupViewController.BackupOption) {
        detailContainerView.isHidden = option.detail == nil
        detailLabel.text = option.detail
        optionNextImage.isHidden = !option.hasFlow
        optionSwitch.isHidden = option.isOn == nil
        optionSwitch.isOn = option.isOn ?? false
        optionTextLabel.text = String.localize(option.label.description)
        optionPickLabel.isHidden = option.pick == nil
        optionPickLabel.text = String.localize(option.pick ?? "")
        if option.isEnabled {
            optionTextLabel.textColor = theme.mainText
            optionPickLabel.textColor = theme.underSelector
            optionSwitch.isEnabled = true
        } else {
            optionTextLabel.textColor = theme.placeholder
            optionPickLabel.textColor = theme.placeholder
            optionSwitch.isEnabled = false
        }
    }
    
    @IBAction func onSwitchToggle(_ sender: Any) {
        switchToggle?(optionSwitch.isOn)
    }
}
