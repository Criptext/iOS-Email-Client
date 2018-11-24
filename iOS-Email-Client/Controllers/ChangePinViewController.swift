//
//  ChangePinViewController.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import PasscodeLock
import LocalAuthentication

class ChangePinViewController: UIViewController {
    
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var lockSwitch: UISwitch!
    @IBOutlet weak var unlockSwitch: UISwitch!
    @IBOutlet weak var unlockButton: UIButton!
    @IBOutlet weak var unlockSeparator: UIView!
    @IBOutlet weak var autoLockButton: UIButton!
    @IBOutlet weak var autoLockLabel: UILabel!
    weak var myAccount: Account!
    
    var locked: Bool {
        let defaults = UserDefaults.standard
        return defaults.string(forKey: "lock") != nil
    }
    var useFingerprint: Bool {
        get {
            let defaults = UserDefaults.standard
            return defaults.bool(forKey: "fingerprintUnlock")
        }
        set (value) {
            let defaults = UserDefaults.standard
            defaults.set(value, forKey: "fingerprintUnlock")
        }
    }
    var useFaceId: Bool {
        get {
            let defaults = UserDefaults.standard
            return defaults.bool(forKey: "faceUnlock")
        }
        set (value) {
            let defaults = UserDefaults.standard
            defaults.set(value, forKey: "faceUnlock")
        }
    }
    var timerStringValue: String {
        get {
            let defaults = UserDefaults.standard
            guard let value = defaults.string(forKey: "lockTimer") else {
                return "Not Set"
            }
            return value
        }
        set (value) {
            let defaults = UserDefaults.standard
            defaults.set(value, forKey: "lockTimer")
        }
    }
    
    override func viewDidLoad() {
        lockSwitch.isOn = locked
        changeButton.isEnabled = locked
        autoLockLabel.text = timerStringValue
        unlockButton.isEnabled = false
        navigationItem.title = "PIN Lock"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        
        if biometricType != .touchID {
            unlockButton.isHidden = true
            unlockSwitch.isHidden = true
            unlockSeparator.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lockSwitch.isOn = locked
        changeButton.isEnabled = locked
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onChangePinPress(_ sender: Any) {
        presentPasscodeController(state: .change)
    }
    
    @IBAction func onLockToggle(_ sender: Any) {
        changeButton.isEnabled = lockSwitch.isOn
        autoLockButton.isEnabled = lockSwitch.isOn
        unlockSwitch.isEnabled = lockSwitch.isOn
        guard lockSwitch.isOn else {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "lock")
            return
        }
        presentPasscodeController(state: .set)
    }
    
    func presentPasscodeController(state: PasscodeLockViewController.LockState) {
        let configuration = PasscodeConfig()
        let passcodeVC = PasscodeLockViewController(state: state, configuration: configuration, animateOnDismiss: true)
        self.navigationController?.pushViewController(passcodeVC, animated: true)
    }
    
    @IBAction func onUnlockToggle(_ sender: Any) {
        useFingerprint = unlockSwitch.isOn
    }
    
    @IBAction func onAutoLockPress(_ sender: Any) {
        let pickerPopover = OptionsPickerUIPopover()
        pickerPopover.options = ["Immediately", "1 minute", "5 minutes", "15 minutes", "1 hour", "24 hours"]
        pickerPopover.onComplete = { [weak self] option in
            if let stringValue = option {
                self?.timerStringValue = stringValue
                self?.autoLockLabel.text = stringValue
            }
        }
        self.presentPopover(popover: pickerPopover, height: 295)
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
