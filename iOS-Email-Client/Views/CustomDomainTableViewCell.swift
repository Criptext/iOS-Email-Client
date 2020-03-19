
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
    func tableViewCellDidLongPress(_ cell: CustomDomainTableViewCell)
}

class CustomDomainTableViewCell: UITableViewCell {
    @IBOutlet weak var customDomainNameLabel: UILabel!
    @IBOutlet weak var trashButton: UIButton!
    var delegate: CustomDomainTableViewCellDelegate?
    private var longPressGesture:UILongPressGestureRecognizer?
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        longPressGestureSetup()
        applyTheme()
    }
    
    func applyTheme() {
        trashButton.tintColor = theme.secondText
        self.tintColor = theme.criptextBlue
        let selectedView = UIView()
        selectedView.backgroundColor = theme.cellHighlight
        self.selectedBackgroundView = selectedView
        backgroundColor = .clear
    }
    
    func longPressGestureSetup(){
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.onCellLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0
        self.longPressGesture = longPressGesture
    }
    
    func setContent(customDomain: CustomDomain){
        customDomainNameLabel.text = customDomain.name
    }
    
    @objc func onCellLongPress(_ sender: Any){
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidLongPress(self)
    }
    
    @IBAction func onTrashPress(_ sender: Any) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidLongPress(self)
    }
}
