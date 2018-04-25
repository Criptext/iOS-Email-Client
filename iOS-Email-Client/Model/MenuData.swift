//
//  MenuData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/9/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class MenuData {
    var expandedLabels = false
    var labels : [Label] = []
    
    init(){
        let allLabels = DBManager.getLabels()
        for label in allLabels {
            if(SystemLabel(rawValue: label.id) == nil){
                labels.append(label)
            }
        }
    }
    
}
