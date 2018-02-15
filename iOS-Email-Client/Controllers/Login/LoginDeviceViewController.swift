//
//  LoginDeviceViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/15/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class LoginDeviceViewController: UIViewController{
    
    var loginData: LoginData!
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onCantLoginPress(_ sender: Any) {
        let alert = UIAlertController(title: "Can't Log In?", message: "If you lost your device or can't seem to log in, you will be asked to enter your password to enable this device, but without all the data you previously had", preferredStyle: .alert)
        let proceedAction = UIAlertAction(title: "Continue", style: .default){ (alert : UIAlertAction!) -> Void in
            self.jumpToResetDevice()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(proceedAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func jumpToResetDevice(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "resetdeviceview")
        (controller as! ResetDeviceViewController).loginData = self.loginData
        navigationController?.pushViewController(controller, animated: true)
    }
}
