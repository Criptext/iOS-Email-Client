//
//  APIManager.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 2/16/17.
//  Copyright © 2017 Criptext, Inc. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import RealmSwift

protocol ProgressDelegate {
    func updateProgress(_ percent:Double, for id:String)
    func chunkUpdateProgress(_ percent: Double, for token: String, part: Int)
}

class APIManager: SharedAPI {
    static let fileServiceUrl = "https://services.criptext.com"
    
    class func postKeybundle(params: [String : Any], token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/keybundle"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func getKeybundle(deviceId: Int32, account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/keybundle/\(deviceId)"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.getKeybundle(deviceId: deviceId, account: account, completion: completion)
            }
        }
    }
    
    class func getKeysRequest(_ params: [String : Any], account: Account, queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/keybundle/find"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let accountRef = SharedDB.getReference(account)
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { response in
            guard let refdAccount = SharedDB.getObject(accountRef) as? Account else {
                completion(ResponseData.Error(CriptextError(code: .unreferencedAccount)))
                return
            }
            let responseData = handleResponse(response)
            let accountRef = SharedDB.getReference(refdAccount)
            self.authorizationRequest(responseData: responseData, account: refdAccount, queue: queue) { (refreshResponseData) in
                guard let refdAccount = SharedDB.getObject(accountRef) as? Account else {
                    completion(ResponseData.Error(CriptextError(code: .unreferencedAccount)))
                    return
                }
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.getKeysRequest(params, account: refdAccount, queue: queue, completion: completion)
            }
        }
    }
    
    class func postMailRequest(_ params: [String : Any], account: Account, queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/email"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let accountRef = SharedDB.getReference(account)
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { response in
            guard let refdAccount = SharedDB.getObject(accountRef) as? Account else {
                completion(ResponseData.Error(CriptextError(code: .unreferencedAccount)))
                return
            }
            let responseData = handleResponse(response)
            let accountRef = SharedDB.getReference(refdAccount)
            self.authorizationRequest(responseData: responseData, account: refdAccount) { (refreshResponseData) in
                guard let refdAccount = SharedDB.getObject(accountRef) as? Account else {
                    completion(ResponseData.Error(CriptextError(code: .unreferencedAccount)))
                    return
                }
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.postMailRequest(params, account: refdAccount, queue: queue, completion: completion)
            }
        }
    }
    
    class func postPeerEvent(_ params: [String : Any], account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/event/peers"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.postPeerEvent(params, account: account, completion: completion)
            }
        }
    }
    
    class func acknowledgeEvents(eventIds: [Int32], token: String){
        let parameters = ["ids": eventIds] as [String : Any]
        let url = "\(self.baseUrl)/event/ack"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
    }
    
    class func notifyOpen(keys: [Int], account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/event/open"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "metadataKeys": keys
        ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.notifyOpen(keys: keys, account: account, completion: completion)
            }
        }
    }
    
    class func unsendEmail(key: Int, recipients: [String], account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/email/unsend"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "metadataKey": key,
            "recipients": recipients
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.unsendEmail(key: key, recipients: recipients, account: account, completion: completion)
            }
        }
    }
    
    class func registerToken(fcmToken: String, token: String){
        let url = "\(self.baseUrl)/keybundle/pushtoken"
        let params = [
            "devicePushToken": fcmToken
        ]
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers)
    }
    
    class func updateName(name: String, account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/name"
        let params = [
            "name": name
        ]
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.updateName(name: name, account: account, completion: completion)
            }
        }
    }

    class func getSettings(account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/settings"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON {
            (response) in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.getSettings(account: account, completion: completion)
            }
        }
    }
    
    class func removeDevice(deviceId: Int, password: String, account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/device"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "deviceId": deviceId,
            "password": password
        ] as [String: Any]
        Alamofire.request(url, method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.removeDevice(deviceId: deviceId, password: password, account: account, completion: completion)
            }
        }
    }
    
    class func changeRecoveryEmail(email: String, password: String, account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/recovery/change"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "email": email,
            "password": password
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.changeRecoveryEmail(email: email, password: password, account: account, completion: completion)
            }
        }
    }
    
    class func resendConfirmationEmail(account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/recovery/resend"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString {
            (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.resendConfirmationEmail(account: account, completion: completion)
            }
        }
    }
    
    class func setTwoFactor(isOn: Bool, account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/2fa"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "enable": isOn
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.setTwoFactor(isOn: isOn, account: account, completion: completion)
            }
        }
    }
    
    class func setReadReceipts(enable: Bool, account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/readtracking"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "enable": enable
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.setReadReceipts(enable: enable, account: account, completion: completion)
            }
        }
    }

    class func changePassword(oldPassword: String, newPassword: String, account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/password/change"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "oldPassword": oldPassword,
            "newPassword": newPassword
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.changePassword(oldPassword: oldPassword, newPassword: newPassword, account: account, completion: completion)
            }
        }
    }
    
    class func unlockDevice(password: String, account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/device/unlock"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "password": password
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.unlockDevice(password: password, account: account, completion: completion)
            }
        }
    }
    
    class func logout(account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/logout"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.logout(account: account, completion: completion)
            }
        }
    }
    
    class func deleteAccount(password: String, account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "password": password
            ] as [String: Any]
        Alamofire.request(url, method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.deleteAccount(password: password, account: account, completion: completion)
            }
        }
    }
    
    class func syncBegin(account: Account, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/sync/begin"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = ["version": Env.linkVersion.description] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.syncBegin(account: account, completion: completion)
            }
        }
    }
    
    class func syncStatus(account: Account, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/sync/status"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.syncStatus(account: account, completion: completion)
            }
        }
    }
    
    class func syncAccept(randomId: String, account: Account, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/sync/accept"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "randomId": randomId,
            "version": Env.linkVersion.description
        ] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.syncAccept(randomId: randomId, account: account, completion: completion)
            }
        }
    }
    
    class func syncDeny(randomId: String, account: Account, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/sync/deny"
        let headers = [
            "Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = ["randomId": randomId] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.linkDeny(randomId: randomId, account: account, completion: completion)
            }
        }
    }
    
    class func getNews(code: Int32, completion: @escaping ((ResponseData) -> Void)) {
        let url = "https://news.criptext.com/news/\(NSLocale.preferredLanguages.first!)/\(code)"
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
}

extension APIManager {
    class func registerFile(parameters: [String: Any], token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.fileServiceUrl)/file/upload"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func uploadChunk(chunk: Data, params: [String: Any], token: String, progressDelegate: ProgressDelegate, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.fileServiceUrl)/file/chunk"
        let headers = ["Authorization": "Bearer \(token)"]
        let filetoken = params["filetoken"] as! String
        let part = params["part"] as! Int
        let filename = params["filename"] as! String
        let mimeType = params["mimeType"] as! String
        Alamofire.upload(multipartFormData: { (multipartForm) in
            for (key, value) in params {
                multipartForm.append("\(value)".data(using: .utf8)!, withName: key)
            }
            multipartForm.append(chunk, withName: "chunk", fileName: filename, mimeType: mimeType)
        }, usingThreshold: UInt64.init(), to: url, method: .post, headers: headers) { (result) in
            switch(result){
            case .success(let request, _, _):
                request.uploadProgress(closure: { (progress) in
                    progressDelegate.chunkUpdateProgress(progress.fractionCompleted, for: filetoken, part: part)
                })
                request.responseJSON(completionHandler: { (response) in
                    let responseData = handleResponse(response, satisfy: .success)
                    completion(responseData)
                })
            case .failure(_):
                completion(ResponseData.Error(CriptextError(message: "Unable to handle request")))
            }
        }
    }
    
    class func getFileMetadata(filetoken: String, token: String, completion: @escaping ((Error?, [String: Any]?) -> Void)){
        let url = "\(self.fileServiceUrl)/file/\(filetoken)"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON{
            (response) in
            guard response.response?.statusCode == 200,
                let responseData = response.result.value as? [String: Any] else {
                    let criptextError = CriptextError(code: .noValidResponse)
                    completion(criptextError, nil)
                    return
            }
            completion(nil, responseData)
        }
    }
    
    class func duplicateFiles(filetokens: [String], token: String, queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.fileServiceUrl)/file/duplicate"
        let headers = ["Authorization": "Bearer \(token)"]
        let params = [
            "files": filetokens
        ]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) {
            (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func downloadChunk(filetoken: String, part: Int, token: String, progressDelegate: ProgressDelegate, completion: @escaping ((Error?, String?) -> Void)){
        let url = "\(self.fileServiceUrl)/file/\(filetoken)/chunk/\(part)"
        let headers = ["Authorization": "Bearer \(token)"]
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("\(filetoken).part\(part)")
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileURL, [.removePreviousFile])
        }
        Alamofire.download(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers, to: destination).downloadProgress { (progress) in
            progressDelegate.chunkUpdateProgress(progress.fractionCompleted, for: filetoken, part: part)
            }.response { (response) in
                if let error = response.error {
                    completion(error, nil)
                    return
                }
                guard response.response?.statusCode == 200 else {
                    let criptextError = CriptextError(code: .noValidResponse)
                    completion(criptextError, nil)
                    return
                }
                completion(nil, fileURL.path)
        }
    }
    
    class func commitFile(filetoken: String, token: String, completion: @escaping ((Error?) -> Void)){
        let url = "\(self.fileServiceUrl)/file/save"
        let headers = ["Authorization": "Bearer \(token)"]
        let params = ["files" : [
            ["token": filetoken]
            ]]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            completion(response.error)
        }
    }
}

extension APIManager {
    class func linkBegin(username: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/begin"
        let headers = [versionHeader: apiVersion]
        let params = ["targetUsername": username] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func linkAuth(deviceInfo: [String: Any], token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/auth"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: deviceInfo, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func linkStatus(token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/status"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func linkAccept(randomId: String, account: Account, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/accept"
        let headers = ["Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion]
        let params = ["randomId": randomId] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.linkAccept(randomId: randomId, account: account, completion: completion)
            }
        }
    }
    
    class func linkDeny(randomId: String, account: Account, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/deny"
        let headers = ["Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion]
        let params = ["randomId": randomId] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.linkDeny(randomId: randomId, account: account, completion: completion)
            }
        }
    }
    
    class func linkDataAddress(params: [String: Any], account: Account, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/data/ready"
        let headers = ["Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.linkDataAddress(params: params, account: account, completion: completion)
            }
        }
    }
    
    class func getLinkData(token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/link/data/ready"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
}

extension APIManager {
    
    @discardableResult class func checkAvailableUsername(_ username: String, completion: @escaping ((ResponseData) -> Void)) -> DataRequest{
        let url = "\(self.baseUrl)/user/available?username=\(username)"
        let headers = [versionHeader: apiVersion]
        return Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func signUpRequest(_ params: [String : Any], completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user"
        let headers = [versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON{
            (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func loginRequest(_ username: String, _ password: String, completion: @escaping ((ResponseData) -> Void)){
        let parameters = ["username": username,
                          "password": password] as [String : Any]
        let url = "\(self.baseUrl)/user/auth"
        let headers = [versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseString {
            (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func resetPassword(username: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/password/reset"
        let params = [
            "recipientId": username
            ] as [String: Any]
        let headers = [versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
}

extension APIManager {
    class func uploadLinkDBFile(dbFile: InputStream, randomId: String, size: Int, token: String, progressCallback: @escaping ((Double) -> Void), completion: @escaping ((ResponseData) -> Void)){
        let url = "\(Env.transferURL)/userdata"
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Length": size.description,
            "Random-ID": randomId
        ]
        Alamofire.upload(dbFile, to: url, method: .post, headers: headers).uploadProgress { (progress) in
            progressCallback(progress.fractionCompleted)
        }.responseString { (responseString) in
            let responseData = handleResponse(responseString, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func downloadLinkDBFile(address: String, token: String, progressCallback: @escaping ((Double) -> Void), completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(Env.transferURL)/userdata?id=\(address)"
        let headers = ["Authorization": "Bearer \(token)"]
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent("\(address).db")
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (fileURL, [.removePreviousFile])
        }
        Alamofire.download(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers, to: destination).downloadProgress{ (progress) in
            progressCallback(progress.fractionCompleted)
        }.response { (response) in
            guard response.response?.statusCode == 200 else {
                completion(.Error(CriptextError(code: .noValidResponse)))
                return
            }
            completion(.SuccessString(fileURL.path))
        }
    }
}
