//
//  LoginManager.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/28/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift
import FirebaseMessaging

protocol LoginManagerDelegate: class {
    func handleResult(accountId: String)
    func throwError(message: String)
}

class LoginManager {
    let loginData: LoginParams
    weak var delegate: LoginManagerDelegate?
    
    init(loginData: LoginParams) {
        self.loginData = loginData
    }
    
    func createAccount() {
        let queue = DispatchQueue(label: "com.criptext.mail.account", qos: .userInitiated, attributes: .concurrent)
        queue.async {
            let account = self.loginData.createAccount()
            let bundle = CRBundle(account: account)
            let keys = bundle.generateKeys()
            DBManager.store(account)
            if let myAddresses = self.loginData.addresses {
                LoginParams.parseAddresses(addresses: myAddresses, account: account)
            }
            self.submitKeybundle(keys: keys, bundle: bundle, queue: queue, accountId: account.compoundKey)
        }
    }
    
    func submitKeybundle(keys: [String: Any], bundle: CRBundle, queue: DispatchQueue, accountId: String) {
        APIManager.postKeybundle(params: keys, token: loginData.jwt, queue: queue){ (responseData) in
            guard let account = DBManager.getAccountById(accountId) else {
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.clearAccount(accountId: accountId)
                DispatchQueue.main.async {
                    self.delegate?.throwError(message: error.description)
                }
                return
            }
            guard case let .SuccessDictionary(tokens) = responseData,
                let jwt = tokens["token"] as? String,
                let refreshToken = tokens["refreshToken"] as? String else {
                self.clearAccount(accountId: accountId)
                DispatchQueue.main.async {
                    self.delegate?.throwError(message: "Wrong Params")
                }
                return
            }
            
            let identityB64 = bundle.store.identityKeyStore.getIdentityKeyPairB64()!
            let regId = bundle.store.identityKeyStore.getRegId()
            DBManager.update(account: account, jwt: jwt, refreshToken: refreshToken, regId: regId, identityB64: identityB64)
            DBManager.createSystemLabels()
            let myContact = Contact()
            myContact.displayName = self.loginData.name
            myContact.email = self.loginData.email
            DBManager.store([myContact], account: account)
            self.registerFirebaseToken(jwt: account.jwt)
            DispatchQueue.main.async {
                self.delegate?.handleResult(accountId: accountId)
            }
        }
    }
    
    func clearAccount(accountId: String) {
        guard let account = DBManager.getAccountById(accountId) else {
            return
        }
        DBManager.signout(account: account)
        DBManager.clearMailbox(account: account)
        DBManager.delete(account: account)
    }
    
    func registerFirebaseToken(jwt: String){
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return
        }
        APIManager.registerToken(fcmToken: fcmToken, token: jwt)
    }
}
