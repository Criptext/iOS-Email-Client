//
//  ImportOptionsViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/28/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class ImportOptionsViewController: UIViewController {
    @IBOutlet weak var skipButton: UIButton!
    
    var myAccount: Account!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFields()
        applyTheme()
    }
    
    func applyTheme() {
        
    }
    
    func setupFields() {
        
    }
    
    @IBAction func onSkipPress(_ sender: UIButton) {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        if delegate.getInboxVC() != nil {
            delegate.swapAccount(account: myAccount, showRestore: false)
            return
        }
        
        let mailboxVC = delegate.initMailboxRootVC(nil, myAccount, showRestore: false)
        var options = UIWindow.TransitionOptions()
        options.direction = .toTop
        options.duration = 0.4
        options.style = .easeOut
        UIApplication.shared.keyWindow?.setRootViewController(mailboxVC, options: options)
    }
}
