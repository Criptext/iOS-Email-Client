//
//  InboxHeaderUITableCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class InboxHeaderUITableCell: UITableViewHeaderFooterView {
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!
     @IBOutlet weak var view: UIView!
    var onEmptyPress: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        messageLabel.textColor = theme.mainText
        actionButton.setTitleColor(theme.criptextBlue, for: .normal)
        backgroundColor = theme.settingsDetail
        contentView.backgroundColor = theme.settingsDetail
        view.backgroundColor = theme.settingsDetail
    }
    
    @IBAction func onEmptyTrashPress(_ sender: Any) {
        onEmptyPress?()
    }
    
}
