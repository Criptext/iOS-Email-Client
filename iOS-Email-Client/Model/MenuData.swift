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
        mockCustomLabels()
    }
    
    func mockCustomLabels(){
        labels.append(Label("Custom 1"))
        labels.append(Label("Custom 2"))
        labels.append(Label("Custom 3"))
    }
}
