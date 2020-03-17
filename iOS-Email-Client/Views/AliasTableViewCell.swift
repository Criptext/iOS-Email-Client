//
//  AliasTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/5/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

protocol AliasTableViewCellDelegate {
    func tableViewCellDidLongPress(_ cell: AliasTableViewCell)
}

class AliasTableViewCell: UITableViewCell {
    @IBOutlet weak var aliasNameLabel: UILabel!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var activeSwitch: UISwitch!
    var delegate: AliasTableViewCellDelegate?
    private var longPressGesture:UILongPressGestureRecognizer?
    var switchToggle: ((Bool) -> Void)?
    
    @IBAction func onSwitchToggle(_ sender: Any) {
        switchToggle?(activeSwitch.isOn)
    }
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
    }
    
    func applyTheme() {
        trashButton.tintColor = theme.secondText
        aliasNameLabel.textColor = theme.mainText
        self.tintColor = theme.criptextBlue
        let selectedView = UIView()
        selectedView.backgroundColor = theme.cellHighlight
        self.selectedBackgroundView = selectedView
        backgroundColor = .clear
    }
    
    func setContent(alias: Alias){
        aliasNameLabel.text = alias.name
        if(alias.domainName == nil){
            self.trashButton.isHidden = true
        }
        activeSwitch.isOn = alias.active
    }
    
    @IBAction func onTrashPress(_ sender: Any) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidLongPress(self)
    }
}
