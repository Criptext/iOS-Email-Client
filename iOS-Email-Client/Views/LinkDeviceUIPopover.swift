//
//  GenericDualAnswerUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/18/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData, account: Account)
    func onCancelLinkDevice(linkData: LinkData, account: Account)
}

class LinkDeviceUIPopover: BaseUIPopover {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var accountEmailLabel: UILabel!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    var initialTitle = ""
    var initialMessage = ""
    var attributedMessage: NSAttributedString?
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
        if let message = attributedMessage {
            messageLabel.attributedText = message
        } else {
            messageLabel.text = initialMessage
        }
        titleLabel.text = initialTitle
        rightButton.setTitle(rightOption, for: .normal)
        leftButton.setTitle(leftOption, for: .normal)
        applyTheme()
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        titleLabel.textColor = theme.mainText
        subtitleLabel.textColor = theme.mainText
        deviceNameLabel.textColor = theme.secondText
        accountEmailLabel.textColor = theme.secondText
        messageLabel.textColor = theme.mainText
        rightButton.backgroundColor = theme.popoverButton
        leftButton.backgroundColor = theme.popoverButton
        rightButton.setTitleColor(theme.mainText, for: .normal)
        leftButton.setTitleColor(theme.mainText, for: .normal)
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
