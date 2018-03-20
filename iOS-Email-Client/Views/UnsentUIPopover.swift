//
//  UnsentUIPop.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class UnsentUIPopover: BaseUIPopover{
    @IBOutlet weak var dateLabel: UILabel!
    
    init() {
        super.init("UnsentUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
