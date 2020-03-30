//
//  AliasTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/5/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

protocol AddAliasTableViewCellDelegate {
    func tableViewCellDidLongPress(_ cell: AddAliasTableViewCell)
}

class AddAliasTableViewCell: UITableViewCell {
    @IBOutlet weak var addButton: UIButton!
    var delegate: AddAliasTableViewCellDelegate?
    private var longPressGesture:UILongPressGestureRecognizer?
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addButton.setTitle(String.localize("ADD_ALIAS"), for: .normal)
        applyTheme()
    }
    
    func applyTheme() {
        self.tintColor = theme.criptextBlue
        let selectedView = UIView()
        selectedView.backgroundColor = theme.cellHighlight
        self.selectedBackgroundView = selectedView
        backgroundColor = .clear
    }
    
    @IBAction func onAddPress(_ sender: Any) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidLongPress(self)
    }
}
