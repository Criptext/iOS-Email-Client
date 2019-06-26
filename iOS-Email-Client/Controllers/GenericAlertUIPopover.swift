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
    var canDismiss: Bool = true
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
        shouldDismiss = canDismiss
        if let attributedMessage = myAttributedMessage {
            messageLabel.attributedText = attributedMessage
        } else {
            messageLabel.text = myMessage
        }
        applyTheme()
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        titleLabel.textColor = theme.mainText
        messageLabel.textColor = theme.mainText
        okButton.backgroundColor = theme.popoverButton
        okButton.setTitleColor(theme.mainText, for: .normal)
    }
    
    @IBAction func okPress(_ sender: Any) {
        self.dismiss(animated: true) { [weak self] in
            self?.onOkPress?()
        }
    }
}
