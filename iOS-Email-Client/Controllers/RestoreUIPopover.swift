//
//  RestoreUIPopover.swift
//  iOS-Email-Client
//
//  Created by Allisson on 4/9/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class RestoreUIPopover: BaseUIPopover {
    
    var onRestore: (() -> Void)?
    
    
    init(){
        super.init("RestoreUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func didPressSkip(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressRestore(_ sender: Any) {
        self.dismiss(animated: true) {
            self.onRestore?()
        }
    }
    
}
