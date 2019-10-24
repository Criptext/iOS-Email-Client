//
//  GenericSingleInputPopover.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 10/24/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class GenericSingleInputPopover: BaseUIPopover {
    
    var answerShouldDismiss = true
    var canDismiss = true
    var onOkPress: ((String) -> (Void))?
    var onCancelPress: (() -> (Void))?
    var initialTitle: String?
    var titleTextColor: UIColor?
    var rightOption: String?
    var leftOption: String?
    var buttonTextColor: UIColor?
    var initialAttrMessage: NSAttributedString?
    var initialMessage: String?
    var keyboardType: UIKeyboardType = UIKeyboardType.default
    @IBOutlet weak var titleHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var inputTextField: TextField!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    init(){
        super.init("GenericSingleInputPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shouldDismiss = canDismiss
        let _ = inputTextField.becomeFirstResponder()
        inputTextField.keyboardType = keyboardType
        if let title = initialTitle {
            titleLabel.text = title
        }
        if let attrMessage = initialAttrMessage {
            messageLabel.attributedText = attrMessage
            let height = UIUtils.getLabelHeight(attrMessage.string, width: messageLabel.frame.width, fontSize: 14)
            messageHeightConstraint.constant = height
            if let title = initialTitle {
                titleHeightConstraint.constant = UIUtils.getLabelHeight(title, width: messageLabel.frame.width, fontSize: 16) + 30
            }
        } else if let message = initialMessage {
            messageLabel.text = message
        } else {
            messageHeightConstraint.constant = 0
        }
        
        if let bText = rightOption {
            okButton.setTitle(bText, for: .normal)
        }
        
        showLoader(false)
        applyTheme()
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        titleLabel.textColor = titleTextColor ?? theme.mainText
        messageLabel.textColor = theme.mainText
        inputTextField.detailColor = theme.alert
        inputTextField.textColor = theme.mainText
        inputTextField.placeholderLabel.textColor = theme.mainText
        inputTextField.attributedPlaceholder = NSAttributedString(string: String.localize("RECOVERY_CODE_DIALOG_TITLE"), attributes: [NSAttributedString.Key.foregroundColor: theme.placeholder])
        okButton.backgroundColor = theme.popoverButton
        cancelButton.backgroundColor = theme.popoverButton
        okButton.setTitleColor(buttonTextColor ?? theme.mainText, for: .normal)
        cancelButton.setTitleColor(theme.mainText, for: .normal)
        loader.color = theme.loader
    }
    
    
    @IBAction func okPress(_ sender: Any) {
        guard let password = inputTextField.text else {
            return
        }
        self.showLoader(true)
        inputTextField.resignFirstResponder()
        guard answerShouldDismiss else {
            self.onOkPress?(password)
            return
        }
        self.dismiss(animated: true, completion: { [weak self] in
            self?.onOkPress?(password)
        })
    }
    
    func showLoader(_ show: Bool){
        self.okButton.isEnabled = !show
        self.cancelButton.isEnabled = !show
        self.inputTextField.isEnabled = !show
        self.loader.isHidden = !show
        guard show else {
            loader.stopAnimating()
            return
        }
        loader.startAnimating()
    }
    
    @IBAction func cancelPress(_ sender: Any) {
        self.dismiss(animated: true, completion: { [weak self] in
            self?.onCancelPress?()
        })
    }
}
