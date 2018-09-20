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
    var socket : SingleWebSocket?
    @IBOutlet weak var waitingDeviceView: UIView!
    @IBOutlet weak var failureDeviceView: UIView!
    @IBOutlet weak var hourglassImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.failureDeviceView.isHidden = true
        self.waitingDeviceView.isHidden = false
        self.hourglassImage.transform = CGAffineTransform(rotationAngle: (20.0 * .pi) / 180.0)
        
        guard let jwt = loginData.jwt else {
            self.navigationController?.popViewController(animated: true)
            print("NANAI")
            return
        }
        
        socket = SingleWebSocket()
        socket?.delegate = self
        socket?.connect(jwt: jwt)
        self.sendLinkAuthRequest()
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func onResendPress(_ sender: Any) {
        onFailure()
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
        let controller = storyboard.instantiateViewController(withIdentifier: "resetdeviceview")  as! ResetDeviceViewController
        controller.loginData = self.loginData
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func onFailure(){
        failureDeviceView.isHidden = false
        waitingDeviceView.isHidden = true
    }
    
    func jumpToConnectDevice(deviceId: Int){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "connectdeviceview")  as! ConnectDeviceViewController
        let signupData = SignUpData(username: loginData.username, password: "no password", fullname: "Linked Device", optionalEmail: nil)
        signupData.deviceId = deviceId
        signupData.token = loginData.jwt
        controller.signupData = signupData
        present(controller, animated: true, completion: nil)
    }
    
    func sendLinkAuthRequest(){
        guard let jwt = loginData.jwt else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        let deviceInfo = Device.createActiveDevice(deviceId: 0).toDictionary(recipientId: loginData.username)
        APIManager.linkAuth(deviceInfo: deviceInfo, token: jwt) { (responseData) in
            guard case .Success = responseData else {
                self.onFailure()
                return
            }
        }
    }
}

extension LoginDeviceViewController: SingleSocketDelegate {
    func newMessage(cmd: Int, params: [String : Any]?) {
        switch(cmd){
        case 202:
            guard let deviceId = params?["deviceId"] as? Int else {
                break
            }
            self.jumpToConnectDevice(deviceId: deviceId)
        default:
            break
        }
    }
}
