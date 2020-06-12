//
//  EnableAutoBackupUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 6/10/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class EnableAutoBackupUIPopover: BaseUIPopover {
    @IBOutlet weak var firstTitleLabel: UILabel!
    @IBOutlet weak var firstDescriptionLabel: UILabel!
    @IBOutlet weak var firstNotNowButton: UIButton!
    @IBOutlet weak var turnOnAutoBackupButton: UIButton!
    
    @IBOutlet weak var secondTitleLabel: UILabel!
    @IBOutlet weak var secondDescriptionLabel: UILabel!
    @IBOutlet weak var secondNotNowButton: UIButton!
    @IBOutlet weak var activateAutoBackupButton: UIButton!
    
    @IBOutlet weak var enableBackupView: UIView!
    @IBOutlet weak var warningView: UIView!
    
    var onEnableAutoBackup: ((Bool) -> Void)?
    
    init() {
        super.init("EnableAutoBackupUIPopover")
        shouldDismiss = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        shouldDismiss = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableBackupView.isHidden = false
        warningView.isHidden = true
        
        applyTheme()
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        
        view.backgroundColor = theme.background
        
        enableBackupView.backgroundColor = .clear
        warningView.backgroundColor = .clear
        
        firstTitleLabel.textColor = theme.mainText
        firstDescriptionLabel.textColor = theme.mainText
        firstNotNowButton.setTitleColor(theme.mainText, for: .normal)
        turnOnAutoBackupButton.backgroundColor = theme.popoverButton
        
        secondTitleLabel.textColor = theme.mainText
        secondDescriptionLabel.textColor = theme.mainText
        secondNotNowButton.setTitleColor(theme.mainText, for: .normal)
        activateAutoBackupButton.backgroundColor = theme.popoverButton
        
        let underlineString = NSMutableAttributedString(string: firstNotNowButton.title(for: .normal)!, attributes: [.foregroundColor: theme.mainText, .font: Font.regular.size(15.0)!])
        underlineString.addAttribute(.underlineStyle, value: 1, range:
        NSRange.init(location: 0, length: underlineString.length));
        firstNotNowButton.setAttributedTitle(underlineString, for: .normal)
        
        let underlineString2 = NSMutableAttributedString(string: secondNotNowButton.title(for: .normal)!, attributes: [.foregroundColor: theme.mainText, .font: Font.regular.size(15.0)!])
        underlineString2.addAttribute(.underlineStyle, value: 1, range:
        NSRange.init(location: 0, length: underlineString2.length));
        secondNotNowButton.setAttributedTitle(underlineString2, for: .normal)
    }
    
    @IBAction func onFirstNotNowPress(_ sender: Any) {
        enableBackupView.isHidden = true
        warningView.isHidden = false
        self.preferredContentSize = CGSize(width: Constants.popoverWidth, height: 300)
    }
    
    @IBAction func onSecondNotNowPress(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.onEnableAutoBackup?(false)
        })
    }
    
    @IBAction func onEnablePress(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.onEnableAutoBackup?(true)
        })
    }
}
