//
//  ComposerVerifyRecoveryUIPopup.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 6/16/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class ComposerVerifyRecoveryUIPopup: BaseUIPopover {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var notNowButton: UIButton!
    @IBOutlet weak var validateButton: UIButton!
    
    var onValidate: ((Bool) -> Void)?
    
    init() {
        super.init("ComposerVerifyRecoveryUIPopup")
        shouldDismiss = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        shouldDismiss = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        
        view.backgroundColor = theme.background
        
        titleLabel.textColor = theme.mainText
        messageLabel.textColor = theme.mainText
        notNowButton.setTitleColor(theme.mainText, for: .normal)
        validateButton.backgroundColor = theme.popoverButton
    }
    
    @IBAction func onNotNowPress(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.onValidate?(false)
        })
    }
    
    @IBAction func onValidatePress(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.onValidate?(true)
        })
    }
}
