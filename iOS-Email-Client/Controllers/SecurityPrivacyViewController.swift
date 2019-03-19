//
//  SecurityPrivacyViewController.swift
//  iOS-Email-Client
//
//  Created by Allisson on 12/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import LocalAuthentication
import PasscodeLock

class SecurityPrivacyViewController: UITableViewController {

    struct PrivacyOption {
        var label: Privacy
        var pick: String?
        var isOn: Bool?
        var hasFlow: Bool
        var detail: String?
        var isEnabled = true
    }
    
    enum Privacy {
        case pincode
        case changePin
        case autoLock
        case biometric
        case twoFactor
        case receipts
        
        var description: String {
            switch(self) {
            case .pincode:
                return String.localize("USE_PIN")
            case .changePin:
                return String.localize("CHANGE_PIN")
            case .autoLock:
                return String.localize("AUTO_LOCK")
            case .twoFactor:
                return String.localize("TWO_FACTOR")
            case .receipts:
                return String.localize("READ_RECEIPTS")
            case .biometric:
                return ""
            }
        }
    }
    
    var isPinControl = false
    var options = [PrivacyOption]()
    var defaults = CriptextDefaults()
    var generalData: GeneralSettingsData!
    var myAccount: Account!
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("PRIVACY_AND_SECURITY")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        tableView.estimatedRowHeight = UITableViewAutomaticDimension
        if isPinControl {
            initializePinOptions()
        } else {
            initializePrivacyOptions()
        }
        applyTheme()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.toggleOptions()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        tableView.backgroundColor = .clear
        self.view.backgroundColor = theme.overallBackground
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    func initializePinOptions() {
        let pinCode = PrivacyOption(label: .pincode, pick: nil, isOn: true, hasFlow: false, detail: String.localize("PIN_DETAIL"), isEnabled: true)
        let changePin = PrivacyOption(label: .changePin, pick: nil, isOn: nil, hasFlow: true, detail: nil, isEnabled: true)
        let autolock = PrivacyOption(label: .autoLock, pick: "1 minute", isOn: nil, hasFlow: false, detail: nil, isEnabled: true)
        options.append(pinCode)
        options.append(changePin)
        options.append(autolock)
        if (biometricType != .none) {
            let biometrics = PrivacyOption(label: .biometric, pick: nil, isOn: true, hasFlow: false, detail: nil, isEnabled: true)
            options.append(biometrics)
        }
        toggleOptions()
    }
    
    func initializePrivacyOptions() {
        let twoFactor = PrivacyOption(label: .twoFactor, pick: nil, isOn: true, hasFlow: false, detail: String.localize("PREVIEW_DETAIL"), isEnabled: true)
        let receipts = PrivacyOption(label: .receipts, pick: nil, isOn: true, hasFlow: false, detail: String.localize("RECEIPTS_DETAIL"), isEnabled: true)
        options.append(twoFactor)
        options.append(receipts)
        toggleOptions()
    }
    
    func toggleOptions() {
        self.options = options.map { (option) -> PrivacyOption in
            var newOption = option
            switch(option.label) {
            case .pincode:
                newOption.isOn = defaults.hasPIN
            case .changePin:
                newOption.isEnabled = defaults.hasPIN
            case .autoLock:
                newOption.isEnabled = defaults.hasPIN
                newOption.pick = defaults.lockTimer
            case .twoFactor:
                newOption.isOn = generalData.isTwoFactor
            case .receipts:
                newOption.isOn = generalData.hasEmailReceipts
            case .biometric:
                newOption.isEnabled = defaults.hasPIN && biometricType != .none
                newOption.isOn = defaults.hasFaceID || defaults.hasFingerPrint
            }
            return newOption
        }
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "privacycell") as! PrivacyUIViewCell
        let option = options[indexPath.row]
        cell.fillFields(option: option)
        switch(option.label) {
        case .pincode:
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.switchToggle = { [weak self] (isOn) in
                guard isOn else {
                    self?.defaults.removePasscode()
                    self?.toggleOptions()
                    return
                }
                self?.presentPasscodeController(state: .set)
            }
        case .twoFactor:
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.switchToggle = { [weak self] (isOn) in
                self?.setTwoFactor(enable: isOn, sender: cell.optionSwitch)
            }
        case .receipts:
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.switchToggle = { [weak self] (isOn) in
                self?.setReadReceipts(enable: isOn, sender: cell.optionSwitch)
            }
        case .biometric:
            cell.optionTextLabel.text = biometricType == .faceID ? String.localize("UNLOCK_FACE") : String.localize("UNLOCK_TOUCH")
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.switchToggle = { [weak self] (isOn) in
                guard let weakSelf = self else {
                    return
                }
                switch(weakSelf.biometricType) {
                case .none:
                    break
                case .touchID:
                    weakSelf.defaults.fingerprintUnlock = isOn
                case .faceID:
                    weakSelf.defaults.faceUnlock = isOn
                }
                weakSelf.toggleOptions()
            }
        case .changePin:
            cell.selectionStyle = UITableViewCellSelectionStyle.gray
            cell.didTap = { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                weakSelf.tableView(weakSelf.tableView, didSelectRowAt: indexPath)
            }
        case .autoLock:
            cell.selectionStyle = UITableViewCellSelectionStyle.gray
            cell.didTap = { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
                weakSelf.tableView(weakSelf.tableView, didSelectRowAt: indexPath)
            }
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]
        guard option.isEnabled else {
            return
        }
        switch(option.label) {
        case .changePin:
            self.presentPasscodeController(state: .change)
        case .autoLock:
            self.openPicker()
        default:
            break
        }
        
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
    }
    
    func presentPasscodeController(state: PasscodeLockViewController.LockState) {
        let configuration = PasscodeConfig()
        let passcodeVC = CustomPasscodeViewController(state: state, configuration: configuration, animateOnDismiss: true)
        self.navigationController?.pushViewController(passcodeVC, animated: true)
    }
    
    func openPicker(){
        let pickerPopover = OptionsPickerUIPopover()
        pickerPopover.options = [
            PIN.time.immediately.rawValue,
            PIN.time.oneminute.rawValue,
            PIN.time.fiveminutes.rawValue,
            PIN.time.fifteenminutes.rawValue,
            PIN.time.onehour.rawValue,
            PIN.time.oneday.rawValue
        ]
        pickerPopover.onComplete = { [weak self] option in
            if let stringValue = option {
                self?.defaults.lockTimer = stringValue
                self?.defaults.lockTimer = stringValue
                self?.toggleOptions()
            }
        }
        self.presentPopover(popover: pickerPopover, height: 295)
    }
    
    func setReadReceipts(enable: Bool, sender: UISwitch?){
        let initialValue = self.generalData.hasEmailReceipts
        self.generalData.hasEmailReceipts = enable
        self.toggleOptions()
        APIManager.setReadReceipts(enable: enable, account: myAccount) { (responseData) in
            sender?.isEnabled = true
            guard case .Success = responseData else {
                self.showAlert(String.localize("SOMETHING_WRONG"), message: String.localize("UNABLE_RECEIPTS"), style: .alert)
                self.generalData.hasEmailReceipts = initialValue
                self.toggleOptions()
                return
            }
        }
    }
    
    func setTwoFactor(enable: Bool, sender: UISwitch?){
        guard !enable || generalData.recoveryEmailStatus == .verified else {
            presentRecoveryPopover()
            return
        }
        let initialValue = self.generalData.isTwoFactor
        self.generalData.isTwoFactor = enable
        APIManager.setTwoFactor(isOn: enable, account: myAccount) { (responseData) in
            if case .Conflicts = responseData {
                self.presentRecoveryPopover()
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("SOMETHING_WRONG"), message: "\(String.localize("UNABLE_TO")) \(enable ? String.localize("ENABLE") : String.localize("DISABLE")) \(String.localize("TWO_FACTOR_RETRY"))", style: .alert)
                self.generalData.isTwoFactor = initialValue
                self.toggleOptions()
                return
            }
            if (self.generalData.isTwoFactor) {
                self.presentTwoFactorPopover()
            }
        }
    }
    
    func presentRecoveryPopover() {
        let popover = GenericAlertUIPopover()
        let attributedRegular = NSMutableAttributedString(string: String.localize("TO_ENABLE_2FA_1"), attributes: [NSAttributedStringKey.font: Font.regular.size(15)!])
        let attributedSemibold = NSAttributedString(string: String.localize("TO_ENABLE_2FA_2"), attributes: [NSAttributedStringKey.font: Font.semibold.size(15)!])
        attributedRegular.append(attributedSemibold)
        popover.myTitle = String.localize("RECOVERY_NOT_SET")
        popover.myAttributedMessage = attributedRegular
        popover.myButton = String.localize("GOT_IT")
        self.presentPopover(popover: popover, height: 310)
    }
    
    func presentTwoFactorPopover() {
        let popover = GenericAlertUIPopover()
        popover.myTitle = String.localize("2FA_ENABLED")
        popover.myMessage = String.localize("NEXT_TIME_2FA")
        popover.myButton = String.localize("GOT_IT")
        self.presentPopover(popover: popover, height: 263)
    }
    
    enum BiometricType {
        case none
        case touchID
        case faceID
    }
    
    var biometricType: BiometricType {
        get {
            let context = LAContext()
            var error: NSError?
            
            guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
                print(error?.localizedDescription ?? "")
                return .none
            }
            
            if #available(iOS 11.0, *) {
                switch context.biometryType {
                case .none:
                    return .none
                case .touchID:
                    return .touchID
                case .faceID:
                    return .faceID
                }
            } else {
                return  .touchID
            }
        }
    }
}

extension SecurityPrivacyViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}
