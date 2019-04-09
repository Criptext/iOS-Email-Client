//
//  RestoreViewController.swift
//  iOS-Email-Client
//
//  Created by Allisson on 4/9/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class RestoreViewController: UIViewController {
    var contentView: RestoreUIView {
        return self.view as! RestoreUIView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.delegate = self
    }
}

extension RestoreViewController: RestoreDelegate {
    func cancelRestore() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func retryRestore() {
        
    }
    
    func restore() {
        
    }
}
