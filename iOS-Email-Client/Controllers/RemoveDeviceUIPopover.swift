//
//  RemoveDeviceUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//
import Foundation
import Material

class RemoveDeviceUIPopover: BaseUIPopover {
    
    var device: Device!
    var myAccount: Account!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var continueTitleLabel: UILabel!
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    var onSuccess: ((Int) -> Void)?
    
    init(){
        super.init("RemoveDeviceUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        passwordTextField.isVisibilityIconButtonEnabled = true
        showLoader(false)
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let _ = passwordTextField.becomeFirstResponder()
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        titleLabel.textColor = theme.mainText
        subTitleLabel.textColor = theme.mainText
        continueTitleLabel.textColor = theme.mainText
        passwordTextField.detailColor = theme.alert
        passwordTextField.textColor = theme.mainText
        passwordTextField.placeholderLabel.textColor = theme.mainText
        passwordTextField.visibilityIconButton?.tintColor = theme.mainText
        passwordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("PASSWORD"), attributes: [NSAttributedString.Key.foregroundColor: theme.placeholder])
        confirmButton.backgroundColor = theme.popoverButton
        cancelButton.backgroundColor = theme.popoverButton
        confirmButton.setTitleColor(theme.mainText, for: .normal)
        cancelButton.setTitleColor(theme.mainText, for: .normal)
        loader.color = theme.loader
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onConfirmPress(_ sender: Any) {
        passwordTextField.detail = ""
        guard let password = passwordTextField.text,
            password.count > 7 else {
            passwordTextField.detail = String.localize("PASSWORD_LENGTH")
            return
        }
        let deviceId = device.id
        showLoader(true)
        APIManager.removeDevice(deviceId: deviceId, password: password.sha256()!, token: myAccount.jwt) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout(account: self.myAccount, manually: true)
                return
            }
            if case .Missing = responseData {
                self.showLoader(false)
                self.passwordTextField.detail = String.localize("WRONG_PASS_RETRY")
                return
            }
            guard case .Success = responseData else {
                self.showLoader(false)
                self.passwordTextField.detail = String.localize("UNABLE_REMOVE_DEVICE", arguments: self.device.friendlyName)
                return
            }
            self.onSuccess?(deviceId)
            self.dismiss(animated: true)
        }
    }
    
    func showLoader(_ show: Bool){
        self.shouldDismiss = !show
        passwordTextField.isEnabled = !show
        confirmButton.isEnabled = !show
        cancelButton.isEnabled = !show
        cancelButton.setTitle(show ? "" : String.localize("CANCEL"), for: .normal)
        confirmButton.setTitle(show ? "" : String.localize("CONFIRM"), for: .normal)
        loader.isHidden = !show
        guard show else {
            loader.stopAnimating()
            return
        }
        loader.startAnimating()
    }
    
}
