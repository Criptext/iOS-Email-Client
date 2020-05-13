
//
//  SettingsDeviceTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

protocol CustomDomainTableViewCellDelegate {
    func didPressDelete(_ cell: CustomDomainTableViewCell)
    func didPressVerify(_ cell: CustomDomainTableViewCell)
}

class CustomDomainTableViewCell: UITableViewCell {
    @IBOutlet weak var customDomainNameLabel: UILabel!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var validateButton: UIButton!
    var delegate: CustomDomainTableViewCellDelegate?
    private var longPressGesture:UILongPressGestureRecognizer?
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        validateButton.setTitle(String.localize("VERIFY"), for: .normal)
    }
    
    func applyTheme() {
        trashButton.tintColor = theme.secondText
        self.tintColor = theme.criptextBlue
        self.validateButton.setTitleColor(theme.criptextBlue, for: .normal)
        self.customDomainNameLabel.textColor = theme.mainText
        self.statusLabel.textColor = theme.secondText
        let selectedView = UIView()
        selectedView.backgroundColor = theme.cellHighlight
        self.selectedBackgroundView = selectedView
        backgroundColor = .clear
    }
    
    
    
    func setContent(customDomain: CustomDomain){
        customDomainNameLabel.text = customDomain.name
        if (customDomain.validated) {
            self.validateButton.isHidden = true
            statusLabel.text = "(\(String.localize("VERIFIED")))"
            statusLabel.textColor = UIColor(red: 97/255, green: 185/255, blue: 0, alpha: 1)
            
        } else {
            self.validateButton.isHidden = false
            statusLabel.text = "(\(String.localize("NOT_CONFIRMED")))"
            statusLabel.textColor = theme.alert
        }
    }
    
    @IBAction func onTrashPress(_ sender: Any) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.didPressDelete(self)
    }
    
    @IBAction func onVerifyPress(_ sender: Any) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.didPressVerify(self)
    }
}
