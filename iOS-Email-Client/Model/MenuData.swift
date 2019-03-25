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
    
    init(){
        labels.append(contentsOf: DBManager.getLabels(notIn: SystemLabel.idsArray))
    }
    
    func reloadLabels(){
        labels.removeAll()
        labels.append(contentsOf: DBManager.getActiveCustomLabels())
    }
    
}
