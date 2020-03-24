//
//  AccountOptionsInterface.swift
//  iOS-Email-Client
//
//  Created by Pedro Iñiguez on 8/28/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol AccountOptionsInterfaceDelegate: class {
    func accountSelected(account: Account, alias: Alias?)
    func onClose()
}

class AccountOptionsInterface: MoreOptionsViewInterface {
    
    var optionsCount: Int
    var options: [AccountAlias]
    var delegate: AccountOptionsInterfaceDelegate?
    
    init(accounts: [AccountAlias]) {
        options = accounts
        optionsCount = accounts.count
    }
    
    func handleOptionCell(cell: AccountFromCell, index: Int) {
        if index > optionsCount - 1 {
            return
        }
        let accountAlias = options[index]
        if let alias = accountAlias.alias,
            !alias.isInvalidated {
            let theme = ThemeManager.shared.theme
            let attributedEmail = NSMutableAttributedString(string: alias.email, attributes: [.font: Font.regular.size(15)!])
            let attributedOrigin = NSAttributedString(string: " (\(accountAlias.account.email))", attributes: [.font: Font.regular.size(15)!, .foregroundColor: theme.secondText])
            attributedEmail.append(attributedOrigin)
            cell.emailLabel.attributedText = attributedEmail
        } else {
            cell.emailLabel.attributedText = nil
            cell.emailLabel.text = accountAlias.account.email
        }
        
    }
    
    func handleOptionSelected(index: Int) {
        if index > optionsCount - 1 {
            return
        }
        let accountAlias = options[index]
        delegate?.accountSelected(account: accountAlias.account, alias: accountAlias.alias)
    }
    
    func onClose() {
        delegate?.onClose()
    }
    
    func changeOptions(label: Int) {
        
    }
}
