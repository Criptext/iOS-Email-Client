//
//  GenericDualAnswerUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/18/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData)
    func onCancelLinkDevice(linkData: LinkData)
}

class GenericDualAnswerUIPopover: BaseUIPopover {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    var initialTitle = ""
    var initialMessage = ""
    var rightOption = "Yes"
    var leftOption = "No"
    var onResponse: ((Bool) -> Void)?
    
    init(){
        super.init("GenericDualAnswerUIPopover")
        self.shouldDismiss = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        messageLabel.text = initialMessage
        titleLabel.text = initialTitle
        rightButton.setTitle(rightOption, for: .normal)
        leftButton.setTitle(leftOption, for: .normal)
    }
    
    @IBAction func onOkPress(_ sender: Any) {
        self.dismiss(animated: true) {
            self.onResponse?(true)
        }
    }
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true) {
            self.onResponse?(false)
        }
    }
    
}
