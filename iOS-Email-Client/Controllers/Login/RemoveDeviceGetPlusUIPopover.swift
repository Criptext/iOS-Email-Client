//
//  RemoveDeviceGetPlusUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 4/21/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class RemoveDeviceGetPlusUIPopover: BaseUIPopover {
    
    var domains: [String]!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var plusImage: UIImageView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    var maxDevices = 2
    var upToDevices = 5
    var onResponse: ((Bool) -> Void)?
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    init(){
        super.init("RemoveDeviceGetPlusUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        shouldDismiss = false
        applyTheme()
        applyLocalization()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        titleLabel.textColor = theme.criptextBlue
        messageLabel.textColor = theme.mainText
        
        confirmButton.backgroundColor = theme.popoverButton
        cancelButton.backgroundColor = theme.popoverButton
        confirmButton.setTitleColor(theme.criptextBlue, for: .normal)
        cancelButton.setTitleColor(theme.mainText, for: .normal)
    }
    
    func applyLocalization() {
        titleLabel.text = String.localize("DEVICE_LIMIT_REACHED")
        messageLabel.text = String.localize("DEVICE_LIMIT_PLUS", arguments: maxDevices, upToDevices)
        confirmButton.setTitle(String.localize("GET_PLUS"), for: .normal)
        cancelButton.setTitle(String.localize("MAYBE_LATER"), for: .normal)
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
