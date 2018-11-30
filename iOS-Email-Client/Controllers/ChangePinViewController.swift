//
//  ChangePinViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import PasscodeLock
import LocalAuthentication

class ChangePinViewController: UIViewController {
    
    let textColor = UIColor.mainUI
    let disableColor = UIColor(red: 55/255, green: 58/255, blue: 69/255, alpha: 0.34)
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
        return defaults.string(forKey: PIN.lock.rawValue) != nil
    }
    var useFingerprint: Bool {
        get {
            let defaults = UserDefaults.standard
            return defaults.bool(forKey: PIN.fingerprint.rawValue)
        }
        set (value) {
            let defaults = UserDefaults.standard
            defaults.set(value, forKey: PIN.fingerprint.rawValue)
        }
    }
    var useFaceId: Bool {
        get {
            let defaults = UserDefaults.standard
            return defaults.bool(forKey: PIN.faceid.rawValue)
        }
        set (value) {
            let defaults = UserDefaults.standard
            defaults.set(value, forKey: PIN.faceid.rawValue)
        }
    }
    var timerStringValue: String {
        get {
            let defaults = UserDefaults.standard
            guard let value = defaults.string(forKey: PIN.lockTimer.rawValue) else {
                return PIN.time.immediately.rawValue
            }
            return value
        }
        set (value) {
            let defaults = UserDefaults.standard
            defaults.set(value, forKey: PIN.lockTimer.rawValue)
        }
    }
    
    override func viewDidLoad() {
        self.toggleActions()
        navigationItem.title = "PIN Lock"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        
        if biometricType != .none {
            unlockButton.isHidden = false
            unlockSwitch.isHidden = false
            unlockSwitch.isOn = useFaceId || useFingerprint
            unlockSeparator.isHidden = false
            unlockButton.setTitle(biometricType == .touchID ? "Unlock with fingerprint" : "Unlock with FaceID", for: .normal)
        } else {
            unlockButton.isHidden = true
            unlockSwitch.isHidden = true
            unlockSeparator.isHidden = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.toggleActions()
    }
    
    func toggleActions() {
        lockSwitch.isOn = locked
        changeButton.isEnabled = locked
        autoLockLabel.text = timerStringValue
        autoLockButton.isEnabled = locked
        autoLockLabel.textColor = locked ? textColor : disableColor
        unlockButton.isEnabled = locked
        unlockSwitch.isEnabled = locked
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onChangePinPress(_ sender: Any) {
        presentPasscodeController(state: .change)
    }
    
    @IBAction func onLockToggle(_ sender: Any) {
        guard lockSwitch.isOn else {
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: PIN.lock.rawValue)
            self.toggleActions()
            return
        }
        presentPasscodeController(state: .set)
    }
    
    func presentPasscodeController(state: PasscodeLockViewController.LockState) {
        let configuration = PasscodeConfig()
        let passcodeVC = CustomPasscodeViewController(state: state, configuration: configuration, animateOnDismiss: true)
        self.navigationController?.pushViewController(passcodeVC, animated: true)
    }
    
    @IBAction func onUnlockToggle(_ sender: Any) {
        useFingerprint = unlockSwitch.isOn
    }
    
    @IBAction func onAutoLockPress(_ sender: Any) {
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

enum PIN: String {
    case lock = "lock"
    case fingerprint = "fingerprintUnlock"
    case faceid = "faceUnlock"
    case lockTimer = "lockTimer"
    case goneTimestamp = "goneTimestamp"
    
    enum time: String {
        case immediately = "Immediately"
        case oneminute = "1 minute"
        case fiveminutes = "5 minutes"
        case fifteenminutes = "15 minutes"
        case onehour = "1 hour"
        case oneday = "24 hours"
    }
}
