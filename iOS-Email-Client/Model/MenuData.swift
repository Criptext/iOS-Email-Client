//
//  MenuData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/9/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class MenuData {
    var expandedLabels = false
    var labels : [Label] = []
    var accounts : Results<Account>!
    var accountBadge = [String: Int]()
    
    func reloadLabels(account: Account){
        labels.removeAll()
        labels.append(contentsOf: DBManager.getUserLabels(account: account))
    }
    
}
