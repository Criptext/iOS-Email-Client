//
//  AccountOptionsInterface.swift
//  iOS-Email-Client
//
//  Created by Pedro Iñiguez on 8/28/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol AccountOptionsInterfaceDelegate: class {
    func accountSelected(account: Account)
    func onClose()
}

class AccountOptionsInterface: MoreOptionsViewInterface {
    
    var optionsCount: Int
    var options: [Account]
    var delegate: AccountOptionsInterfaceDelegate?
    
    init(accounts: [Account]) {
        options = accounts
        optionsCount = accounts.count
    }
    
    func handleOptionCell(cell: AccountFromCell, index: Int) {
        if index > optionsCount - 1 {
            return
        }
        let account = options[index]
        cell.emailLabel.text = account.email
    }
    
    func handleOptionSelected(index: Int) {
        if index > optionsCount - 1 {
            return
        }
        let account = options[index]
        delegate?.accountSelected(account: account)
    }
    
    func onClose() {
        delegate?.onClose()
    }
    
    func changeOptions(label: Int) {
        
    }
}
