//
//  LogoutPopoverViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/1/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class LogoutPopoverViewController: BaseUIPopover {
    var onTrigger: ((Bool) -> Void)?
    
    init(){
        super.init("LogoutUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func onLogoutPress(_ sender: Any) {
        onTrigger?(true)
        self.dismiss(animated: true)
    }
    @IBAction func onCancelPress(_ sender: Any) {
        onTrigger?(false)
        self.dismiss(animated: true)
    }
}
