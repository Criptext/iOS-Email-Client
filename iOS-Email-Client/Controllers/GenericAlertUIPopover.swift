//
//  GenericAlertUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class GenericAlertUIPopover: BaseUIPopover {
    
    var myTitle: String?
    var myMessage: String?
    var onOkPress: (() -> (Void))?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    
    init(){
        super.init("GenericAlertUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = myTitle
        messageLabel.text = myMessage
    }
    
    @IBAction func okPress(_ sender: Any) {
        self.dismiss(animated: true) { [weak self] in
            self?.onOkPress?()
        }
    }
}
