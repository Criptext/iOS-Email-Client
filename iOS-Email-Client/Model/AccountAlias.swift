//
//  AccountAlias.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 3/24/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class AccountAlias {
    let account: Account
    let alias: Alias?
    
    init(account: Account, alias: Alias? = nil) {
        self.account = account
        self.alias = alias
    }
}
