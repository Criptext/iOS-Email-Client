//
//  ChangePinViewController.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import PasscodeLock

class ChangePinViewController: UIViewController {
    
    @IBOutlet weak var changeButton: UIButton!
    @IBOutlet weak var lockSwitch: UISwitch!
    weak var myAccount: Account!
    
    var locked: Bool {
        let groupDefaults = UserDefaults.standard
        return groupDefaults.string(forKey: "lock") != nil
    }
    
    override func viewDidLoad() {
        lockSwitch.isOn = locked
        changeButton.isEnabled = locked
        
        navigationItem.title = "PIN Lock"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
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
        presentPasscodeController(state: lockSwitch.isOn ? .set : .remove)
    }
    
    func presentPasscodeController(state: PasscodeLockViewController.LockState) {
        let configuration = PasscodeConfig()
        let passcodeVC = PasscodeLockViewController(state: state, configuration: configuration, animateOnDismiss: true)
        self.navigationController?.pushViewController(passcodeVC, animated: true)
    }
    
}
