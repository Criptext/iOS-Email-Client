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
    func handleResult(account: Account)
    func throwError(message: String)
}

class LoginManager {
    let loginData: LoginParams
    weak var delegate: LoginManagerDelegate?
    
    init(loginData: LoginParams) {
        self.loginData = loginData
    }
    
    func createAccount() {
        let account = loginData.createAccount()
        let bundle = CRBundle(account: account)
        let keys = bundle.generateKeys()
        DBManager.store(account)
        if let myAddresses = loginData.addresses {
            LoginParams.parseAddresses(addresses: myAddresses, account: account)
        }
        submitKeybundle(keys: keys, bundle: bundle, account: account)
    }
    
    func submitKeybundle(keys: [String: Any], bundle: CRBundle, account: Account) {
        APIManager.postKeybundle(params: keys, token: loginData.jwt){ (responseData) in
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.clearAccount(account: account)
                self.delegate?.throwError(message: error.description)
                return
            }
            guard case let .SuccessDictionary(tokens) = responseData,
                let jwt = tokens["token"] as? String,
                let refreshToken = tokens["refreshToken"] as? String else {
                self.clearAccount(account: account)
                self.delegate?.throwError(message: "Wrong Params")
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
            self.delegate?.handleResult(account: account)
        }
    }
    
    func clearAccount(account: Account) {
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
