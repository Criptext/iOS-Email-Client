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
    
    enum Privacy: String {
        case pincode = "Use PIN Code"
        case changePin = "Change PIN Code"
        case autoLock = "Auto-Lock"
        case preview = "Notification Preview"
        case receipts = "Read Receipts"
        case biometric = ""
    }
    
    var options = [PrivacyOption]()
    var defaults = CriptextDefaults()
    var generalData: GeneralSettingsData!
    var myAccount: Account!
    
    override func viewDidLoad() {
        navigationItem.title = "PRIVACY AND SECURITY"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        
        tableView.estimatedRowHeight = UITableViewAutomaticDimension
        initializeOptions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.toggleOptions()
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    func initializeOptions(){
        let pinCode = PrivacyOption(label: .pincode, pick: nil, isOn: true, hasFlow: false, detail: "If you forget your PIN code you'll have to sign out and sign back in again.\n\nWarning: 10 failed attempts will result in all data to be erased from the app for security purposes.", isEnabled: true)
        let changePin = PrivacyOption(label: .changePin, pick: nil, isOn: nil, hasFlow: true, detail: nil, isEnabled: true)
        let autolock = PrivacyOption(label: .autoLock, pick: "1 minute", isOn: nil, hasFlow: false, detail: nil, isEnabled: true)
        let preview = PrivacyOption(label: .preview, pick: nil, isOn: true, hasFlow: false, detail: "Preview the content of emails in Push notifications.", isEnabled: true)
        let receipts = PrivacyOption(label: .receipts, pick: nil, isOn: true, hasFlow: false, detail: "If disabled, you won't be able to know when others read your emails.", isEnabled: true)
        options.append(pinCode)
        options.append(changePin)
        options.append(autolock)
        if (biometricType != .none) {
            let biometrics = PrivacyOption(label: .biometric, pick: nil, isOn: true, hasFlow: false, detail: nil, isEnabled: true)
            options.append(biometrics)
        }
        options.append(preview)
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
            case .preview:
                newOption.isOn = !defaults.previewDisable
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
        case .preview:
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.switchToggle = { [weak self] (isOn) in
                self?.defaults.previewDisable = !isOn
                self?.toggleOptions()
            }
        case .receipts:
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.switchToggle = { [weak self] (isOn) in
                self?.setReadReceipts(enable: isOn, sender: cell.optionSwitch)
            }
        case .biometric:
            cell.optionTextLabel.text = biometricType == .faceID ? "Unlock with FaceID" : "Unlock with Fingerprint"
            cell.selectionStyle = UITableViewCellSelectionStyle.none
            cell.switchToggle = { [weak self] (isOn) in
                guard let weakSelf = self else {
                    return
                }
                switch(weakSelf.biometricType) {
                case .none:
                    break
                case .touchID:
                    weakSelf.defaults.faceUnlock = isOn
                case .faceID:
                    weakSelf.defaults.fingerprintUnlock = isOn
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
        APIManager.setReadReceipts(enable: enable, token: myAccount.jwt) { (responseData) in
            sender?.isEnabled = true
            guard case .Success = responseData else {
                self.showAlert(String.localize("Something went wrong"), message: "\(String.localize("Unable to")) \(enable ? String.localize("enable") : String.localize("disable")) \(String.localize("two pass. Please try again"))", style: .alert)
                self.generalData.hasEmailReceipts = initialValue
                self.toggleOptions()
                return
            }
        }
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

