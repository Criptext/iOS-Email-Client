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
    var scheduleWorker = ScheduleWorker(interval: 5.0, maxRetries: 12)
    @IBOutlet weak var waitingDeviceView: UIView!
    @IBOutlet weak var failureDeviceView: UIView!
    @IBOutlet weak var hourglassImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.failureDeviceView.isHidden = true
        self.waitingDeviceView.isHidden = false
        self.hourglassImage.transform = CGAffineTransform(rotationAngle: (20.0 * .pi) / 180.0)
        
        guard let jwt = loginData.jwt else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        socket = SingleWebSocket()
        socket?.delegate = self
        socket?.connect(jwt: jwt)
        scheduleWorker.delegate = self
        guard loginData.isTwoFactor else {
            self.sendLinkAuthRequest()
            return
        }
        self.scheduleWorker.start()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        socket?.close()
        scheduleWorker.cancel()
    }
    
    @IBAction func backButtonPress(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func onResendPress(_ sender: Any) {
        let resendButton = sender as? UIButton
        resendButton?.isEnabled = false
        resendButton?.alpha = 0.6
        sendLinkAuthRequest()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            resendButton?.alpha = 1
            resendButton?.isEnabled = true
        }
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
        titleLabel.text = "Sign In Rejected"
    }
    
    func jumpToConnectDevice(name: String, deviceId: Int){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "connectdeviceview")  as! ConnectDeviceViewController
        let signupData = SignUpData(username: loginData.username, password: "no password", fullname: name, optionalEmail: nil)
        signupData.deviceId = deviceId
        signupData.token = loginData.jwt
        controller.signupData = signupData
        present(controller, animated: true, completion: {
            self.navigationController?.popViewController(animated: false)
        })
    }
    
    func sendLinkAuthRequest(){
        guard let jwt = loginData.jwt else {
            self.navigationController?.popViewController(animated: true)
            return
        }
        var deviceInfo = Device.createActiveDevice(deviceId: 0).toDictionary(recipientId: loginData.username)
        if loginData.isTwoFactor,
            let password = loginData.password {
            deviceInfo["password"] = password
        }
        APIManager.linkAuth(deviceInfo: deviceInfo, token: jwt) { (responseData) in
            guard case .Success = responseData else {
                self.onFailure()
                return
            }
            self.scheduleWorker.start()
        }
    }
}

extension LoginDeviceViewController: ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void) {
        guard let jwt = loginData.jwt else {
            self.navigationController?.popViewController(animated: true)
            completion(true)
            return
        }
        APIManager.linkStatus(token: jwt) { (responseData) in
            if case .AuthDenied = responseData {
                completion(true)
                self.newMessage(cmd: Event.Link.deny.rawValue, params: nil)
            }
            guard case let .SuccessDictionary(params) = responseData else {
                completion(false)
                return
            }
            completion(true)
            self.newMessage(cmd: Event.Link.accept.rawValue, params: params)
        }
    }
    
    func dangled(){
        let retryPopup = GenericDualAnswerUIPopover()
        retryPopup.initialMessage = "Something has happened that is delaying this process. Do want to continue waiting?"
        retryPopup.initialTitle = "Well, that’s odd…"
        retryPopup.onResponse = { accept in
            guard accept else {
                self.navigationController?.popViewController(animated: true)
                return
            }
            self.scheduleWorker.start()
        }
        self.presentPopover(popover: retryPopup, height: 205)
    }
}

extension LoginDeviceViewController: SingleSocketDelegate {
    func newMessage(cmd: Int32, params: [String : Any]?) {
        switch(cmd){
        case Event.Link.accept.rawValue:
            guard let deviceId = params?["deviceId"] as? Int,
                let name = params?["name"] as? String else {
                break
            }
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            self.scheduleWorker.cancel()
            self.socket?.close()
            self.jumpToConnectDevice(name: name, deviceId: deviceId)
        case Event.Link.deny.rawValue:
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            self.scheduleWorker.cancel()
            self.socket?.close()
            self.onFailure()
        default:
            break
        }
    }
}
