//
//  GenericDualAnswerUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/18/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol LinkDeviceDelegate {
    func onAcceptLinkDevice()
}

class GenericDualAnswerUIPopover: BaseUIPopover {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var okButton: UIButton!
    var initialTitle = ""
    var initialMessage = ""
    var onOk: (() -> Void)?
    
    init(){
        super.init("GenericDualAnswerUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.text = initialMessage
        titleLabel.text = initialTitle
    }
    
    @IBAction func onOkPress(_ sender: Any) {
        self.dismiss(animated: true) {
            self.onOk?()
        }
    }
}
