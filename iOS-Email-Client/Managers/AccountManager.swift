//
//  AccountManager.swift
//  iOS-Email-Client
//
//  Created by Allisson on 3/6/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol AccountDelegate: class {
    func swapAccount(_ account: Account)
}

final class AccountManager: NSObject {
    static let shared = AccountManager()
    var account: Account?
    private var delegates = [String: AccountDelegate]()
    
    private override init() {
        let defaults = CriptextDefaults()
        if let username = defaults.activeAccount {
            self.account = DBManager.getAccountByUsername(username)
        }
        if self.account == nil {
            self.account = DBManager.getFirstAccount()
            defaults.activeAccount = account?.username
        }
        super.init()
    }
    
    func swapTheme(account: Account) {
        for (_, delegate) in delegates {
            delegate.swapAccount(account)
        }
    }
    
    func addListener(id: String, delegate: AccountDelegate) {
        delegates[id] = delegate
    }
    
    func removeListener(id: String) {
        delegates[id] = nil
    }
}
