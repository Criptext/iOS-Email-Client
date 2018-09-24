//
//  ConnectDeviceViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ConnectDeviceViewController: UIViewController{
    
    @IBOutlet var connectUIView: ConnectUIView!
    var signupData: SignUpData!
    var socket : SingleWebSocket?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        socket = SingleWebSocket()
        socket?.delegate = self
        connectUIView.initialLoad(email: "\(signupData.username)\(Constants.domain)")
        DBManager.destroy()
        sendKeysRequest()
    }
    
    func sendKeysRequest(){
        let keyBundle = signupData.buildDataForRequest()["keybundle"] as! [String: Any]
        APIManager.postKeybundle(params: keyBundle, token: signupData.token!){ (responseData) in
            if case let .Error(error) = responseData,
                error.code != .custom {
                return
            }
            guard case let .SuccessString(jwt) = responseData else {
                return
            }
            self.signupData.token = jwt
            self.socket?.connect(jwt: jwt)
        }
    }
}

extension ConnectDeviceViewController: SingleSocketDelegate {
    func newMessage(cmd: Int32, params: [String : Any]?) {
        switch(cmd){
        case Event.Link.success.rawValue:
            guard let address = params?["dataAddress"] as? String else {
                break
            }
        default:
            break
        }
    }
}
