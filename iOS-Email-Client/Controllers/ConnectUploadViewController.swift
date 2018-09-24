//
//  ConnectUploadViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftWebSocket

class ConnectUploadViewController: UIViewController{
    
    let keyData     = AESCipher.generateRandomBytes()
    let ivData      = AESCipher.generateRandomBytes()
    
    @IBOutlet var connectUIView: ConnectUIView!
    var linkData: LinkData!
    var myAccount: Account!
    var socket : SingleWebSocket?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        socket = SingleWebSocket()
        socket?.delegate = self
        socket?.connect(jwt: myAccount.jwt)
        connectUIView.initialLoad(email: "\(myAccount.username)\(Constants.domain)")
        APIManager.linkAccept(randomId: linkData.randomId, token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            self.createDBFile()
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        socket?.close()
    }
    
    func createDBFile(){
        CreateCustomJSONFileAsyncTask().start { (error, url) in
            guard let myUrl = url else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            
            let outputPath = AESCipher.streamEncrypt(path: myUrl.path, outputName: "secure-db", keyData: self.keyData, ivData: self.ivData, operation: kCCEncrypt)
            self.connectUIView.handleSuccess()
        }
    }
}

extension ConnectUploadViewController: SingleSocketDelegate {
    func newMessage(cmd: Int, params: [String : Any]?) {
        switch(cmd){
        case 203:
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: {
                self.dismiss(animated: true, completion: nil)
            })
        default:
            break
        }
    }
}
