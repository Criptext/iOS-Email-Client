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
    var myAttributedMessage: NSAttributedString?
    var myButton: String = "Ok"
    var onOkPress: (() -> (Void))?
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var okButton: UIButton!
    
    
    init(){
        super.init("GenericAlertUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = myTitle
        okButton.setTitle(myButton, for: .normal)
        if let attributedMessage = myAttributedMessage {
            messageLabel.attributedText = attributedMessage
        } else {
            messageLabel.text = myMessage
        }
    }
    
    @IBAction func okPress(_ sender: Any) {
        self.dismiss(animated: true) { [weak self] in
            self?.onOkPress?()
        }
    }
}
