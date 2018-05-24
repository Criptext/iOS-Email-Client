//
//  NavTabsController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/24/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class CustomTabsController: TabsController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Settings"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: <#T##UIImage?#>, style: <#T##UIBarButtonItemStyle#>, target: <#T##Any?#>, action: <#T##Selector?#>)
        
    }
    
}
