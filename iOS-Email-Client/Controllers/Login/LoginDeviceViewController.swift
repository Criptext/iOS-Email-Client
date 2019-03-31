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
    var multipleAccount = false
    var socket : SingleWebSocket?
    var scheduleWorker = ScheduleWorker(interval: 5.0, maxRetries: 12)
    @IBOutlet weak var waitingDeviceView: UIView!
    @IBOutlet weak var failureDeviceView: UIView!
    @IBOutlet weak var hourglassImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var signWithPasswordButton: UIButton!
    
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
        signWithPasswordButton.isHidden = true
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
        self.presentLoginPasswordPopover()
    }
    
    func presentLoginPasswordPopover() {
        let popover = GenericDualAnswerUIPopover()
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("YES")
        popover.initialTitle = String.localize("WARNING")
        let regularAttrs = [NSAttributedString.Key.font: Font.regular.size(14)!]
        let boldAttrs = [NSAttributedString.Key.font: Font.bold.size(14)!]
        let attrText = NSMutableAttributedString(string: String.localize("IF_YOU_SIGN_IN"), attributes: regularAttrs)
        let attrBold = NSAttributedString(string: String.localize("MAILBOX_HISTORY"), attributes: boldAttrs)
        let attrText2 = NSMutableAttributedString(string: String.localize("ON_THIS_DEVICE"), attributes: regularAttrs)
        attrText.append(attrBold)
        attrText.append(attrText2)
        popover.attributedMessage = attrText
        popover.onResponse = { [weak self] ok in
            guard ok,
                let weakSelf = self else {
                    return
            }
            weakSelf.jumpToResetDevice()
        }
        presentPopover(popover: popover, height: 205)
    }
    
    func jumpToResetDevice(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "resetdeviceview")  as! ResetDeviceViewController
        controller.loginData = self.loginData
        controller.multipleAccount = self.multipleAccount
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func onFailure(){
        failureDeviceView.isHidden = false
        waitingDeviceView.isHidden = true
        titleLabel.text = String.localize("SIGN_REJECTED")
    }
    
    func jumpToConnectDevice(data: LinkAccept){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "connectdeviceview")  as! ConnectDeviceViewController
        let signupData = SignUpData(username: loginData.username, password: "no password", fullname: data.name, optionalEmail: nil)
        signupData.deviceId = data.deviceId
        signupData.token = loginData.jwt
        controller.signupData = signupData
        controller.linkData = data
        controller.multipleAccount = self.multipleAccount
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
        retryPopup.initialMessage = String.localize("DELAYED_PROCESS_RETRY")
        retryPopup.initialTitle = String.localize("ODD")
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
                let name = params?["name"] as? String,
                let authorizerId = params?["authorizerId"] as? Int32,
                let authorizerName = params?["authorizerName"] as? String,
                let authorizerType = params?["authorizerType"] as? Int else {
                break
            }
            let linkAcceptData = LinkAccept(deviceId: deviceId, name: name, authorizerId: authorizerId, authorizerName: authorizerName, authorizerType: authorizerType)
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            self.scheduleWorker.cancel()
            self.socket?.close()
            self.jumpToConnectDevice(data: linkAcceptData)
        case Event.Link.deny.rawValue:
            self.presentedViewController?.dismiss(animated: true, completion: nil)
            self.scheduleWorker.cancel()
            self.socket?.close()
            self.onFailure()
        default:
            break
        }
    }
    
    struct LinkAccept {
        let deviceId: Int
        let name: String
        let authorizerId: Int32
        let authorizerName: String
        let authorizerType: Int
        
        init(deviceId: Int, name: String, authorizerId: Int32, authorizerName: String, authorizerType: Int) {
            self.deviceId = deviceId
            self.name = name
            self.authorizerId = authorizerId
            self.authorizerName = authorizerName
            self.authorizerType = authorizerType
        }
    }
}
