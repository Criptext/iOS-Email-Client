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
    
    class func getKeybundle(deviceId: Int32, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/keybundle/\(deviceId)"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.getKeybundle(deviceId: deviceId, token: newToken, completion: completion)
            }
        }
    }
    
    class func getKeysRequest(_ params: [String : Any], token: String, queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/keybundle/find"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { response in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, token: token, queue: queue) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.getKeysRequest(params, token: newToken, queue: queue, completion: completion)
            }
        }
    }
    
    class func postMailRequest(_ params: [String : Any], token: String, queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/email"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { response in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.postMailRequest(params, token: newToken, queue: queue, completion: completion)
            }
        }
    }
    
    class func postKeys(_ keys: [[String: Any]], token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/keybundle/prekeys"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "preKeys": keys
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.postKeys(keys, token: newToken, completion: completion)
            }
        }
    }
    
    class func postPeerEvent(_ params: [String : Any], token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/event/peers"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.postPeerEvent(params, token: newToken, completion: completion)
            }
        }
    }
    
    class func postUserEvent(event: Int, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/event"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "event": event
        ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.postPeerEvent(params, token: newToken, completion: completion)
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
    
    class func notifyOpen(keys: [Int], token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/event/open"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "metadataKeys": keys
        ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.notifyOpen(keys: keys, token: newToken, completion: completion)
            }
        }
    }
    
    class func unsendEmail(key: Int, recipients: [String], token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/email/unsend"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "metadataKey": key,
            "recipients": recipients
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.unsendEmail(key: key, recipients: recipients, token: newToken, completion: completion)
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
    
    class func updateName(name: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/name"
        let params = [
            "name": name
        ]
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.updateName(name: name, token: newToken, completion: completion)
            }
        }
    }
    
    class func updateReplyTo(email: String, enable: Bool, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/replyto"
        var params: [String:Any] = [
            "address": email,
            "enable": enable
            ]
        if (!enable){
            params.removeValue(forKey: "address")
        }
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.updateReplyTo(email: email, enable: enable, token: newToken, completion: completion)
            }
        }
    }

    class func getSettings(token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/settings"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON {
            (response) in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.getSettings(token: newToken, completion: completion)
            }
        }
    }
    
    class func removeDevice(deviceId: Int, password: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/device"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "deviceId": deviceId,
            "password": password
        ] as [String: Any]
        Alamofire.request(url, method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.removeDevice(deviceId: deviceId, password: password, token: newToken, completion: completion)
            }
        }
    }
    
    class func changeRecoveryEmail(email: String, password: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/recovery/change"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "email": email,
            "password": password
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.changeRecoveryEmail(email: email, password: password, token: newToken, completion: completion)
            }
        }
    }
    
    class func resendConfirmationEmail(token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/recovery/resend"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString {
            (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.resendConfirmationEmail(token: newToken, completion: completion)
            }
        }
    }
    
    class func setTwoFactor(isOn: Bool, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/2fa"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "enable": isOn
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.setTwoFactor(isOn: isOn, token: newToken, completion: completion)
            }
        }
    }
    
    class func setReadReceipts(enable: Bool, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/readtracking"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "enable": enable
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.setReadReceipts(enable: enable, token: newToken, completion: completion)
            }
        }
    }

    class func changePassword(oldPassword: String, newPassword: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/password/change"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "oldPassword": oldPassword,
            "newPassword": newPassword
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.changePassword(oldPassword: oldPassword, newPassword: newPassword, token: newToken, completion: completion)
            }
        }
    }
    
    class func unlockDevice(password: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/device/unlock"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "password": password
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.unlockDevice(password: password, token: newToken, completion: completion)
            }
        }
    }
    
    class func logout(token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/logout"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.logout(token: newToken, completion: completion)
            }
        }
    }
    
    class func deleteAccount(password: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "password": password
            ] as [String: Any]
        Alamofire.request(url, method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.deleteAccount(password: password, token: newToken, completion: completion)
            }
        }
    }
    
    class func syncBegin(token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/sync/begin"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = ["version": Env.linkVersion.description] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.syncBegin(token: newToken, completion: completion)
            }
        }
    }
    
    class func syncStatus(token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/sync/status"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.syncStatus(token: newToken, completion: completion)
            }
        }
    }
    
    class func syncAccept(randomId: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/sync/accept"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "randomId": randomId,
            "version": Env.linkVersion.description
        ] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.syncAccept(randomId: randomId, token: newToken, completion: completion)
            }
        }
    }
    
    class func syncDeny(randomId: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/sync/deny"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = ["randomId": randomId] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.syncDeny(randomId: randomId, token: newToken, completion: completion)
            }
        }
    }
    
    class func linkCancel(token: String, recipientId: String, domain: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/cancel"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
            "recipientId": recipientId,
            "domain": domain
            ] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func syncCancel(token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/sync/cancel"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func getNews(code: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "https://news.criptext.com/news/\(NSLocale.preferredLanguages.first!)/\(code)"
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }

    class func uploadProfilePicture(inputStream: InputStream, params: [String: Any], token: String, progressCallback: @escaping ((Double) -> Void), completion: @escaping ((ResponseData) -> Void)){
        let url = "\(Env.apiURL)/user/avatar/"
        let mimeType = params["mimeType"] as! String
        let size = params["size"] as! Int
        let headers = [
            "Authorization": "Bearer \(token)",
            "Content-Type": "\(mimeType)",
            "Content-Length": "\(size)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.upload(inputStream, to: url, method: .put, headers: headers).uploadProgress { (progress) in
            progressCallback(progress.fractionCompleted)
            }.responseString { (responseString) in
                let responseData = handleResponse(responseString, satisfy: .success)
                completion(responseData)
        }
    }
    
    class func deleteProfilePicture(token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(Env.apiURL)/user/avatar/"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.deleteProfilePicture(token: newToken, completion: completion)
            }
        }
    }

    class func registerFile(token: String, parameters: [String: Any], completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.fileServiceUrl)/file/upload"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.registerFile(token: newToken, parameters: parameters, completion: completion)
            }
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
                    self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                        if let refreshData = refreshResponseData {
                            completion(refreshData)
                            return
                        }
                        self.getFileMetadata(filetoken: filetoken, token: newToken, completion: completion)
                    }
                })
            case .failure(_):
                completion(ResponseData.Error(CriptextError(message: "Unable to handle request")))
            }
        }
    }
    
    class func getFileMetadata(filetoken: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.fileServiceUrl)/file/\(filetoken)"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON{
            (response) in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.getFileMetadata(filetoken: filetoken, token: newToken, completion: completion)
            }
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
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.duplicateFiles(filetokens: filetokens, token: newToken, queue: queue, completion: completion)
            }
        }
    }
    
    class func downloadChunk(filetoken: String, part: Int, token: String, progressDelegate: ProgressDelegate, completion: @escaping ((ResponseData) -> Void)){
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
                guard response.response?.statusCode != 200 else {
                    completion(ResponseData.SuccessString(fileURL.path))
                    return
                }
                guard response.response?.statusCode == 401 else {
                    completion(ResponseData.Error(CriptextError(code: .noValidResponse)))
                    return
                }
                
                self.authorizationRequest(responseData: ResponseData.AuthPending, token: token) { (refreshResponseData, newToken) in
                    if let refreshData = refreshResponseData {
                        completion(refreshData)
                        return
                    }
                    self.downloadChunk(filetoken: filetoken, part: part, token: newToken, progressDelegate: progressDelegate, completion: completion)
                }
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

    class func linkBegin(username: String, domain: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/begin"
        let headers = [versionHeader: apiVersion]
        let params = [
            "targetUsername": username,
            "domain": domain,
            "version": Env.linkVersion.description
        ] as [String : Any]
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
    
    class func linkAccept(randomId: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/accept"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "randomId": randomId,
            "version": Env.linkVersion] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.linkAccept(randomId: randomId, token: newToken, completion: completion)
            }
        }
    }
    
    class func linkDeny(randomId: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/deny"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = ["randomId": randomId] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.linkDeny(randomId: randomId, token: newToken, completion: completion)
            }
        }
    }
    
    class func linkDataAddress(params: [String: Any], token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/data/ready"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.linkDataAddress(params: params, token: newToken, completion: completion)
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
    
    class func checkLogin(username: String, domain: String, completion: @escaping((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/user/canlogin?username=\(username)&domain=\(domain)"
        let headers = [versionHeader: apiVersion]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }

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
    
    class func loginRequest(username: String, domain: String, password: String, completion: @escaping ((ResponseData) -> Void)){
        let parameters = ["username": username,
                          "domain": domain,
                          "password": password] as [String : Any]
        let url = "\(self.baseUrl)/user/auth"
        let headers = [versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseString {
            (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func findDevices(username: String, domain: String, password: String, completion: @escaping ((ResponseData) -> Void)){
        let parameters = ["recipientId": username,
                          "domain": domain,
                          "password": password] as [String : Any]
        let url = "\(self.baseUrl)/device/find"
        let headers = [versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON {
            (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func deleteDevices(username: String, domain: String, token: String, deviceIds: [Int], completion: @escaping ((ResponseData) -> Void)){
        let url = "\(Env.apiURL)/device/\(username)/\(domain)/\(token)?\(deviceIds.map {"deviceId=\($0)"}.joined(separator: "&"))"
        let headers = [
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .delete, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.deleteDevices(username: username, domain: domain, token: token, deviceIds: deviceIds, completion: completion)
            }
        }
    }
    
    class func loginChangePasswordRequest(username: String, domain: String, password: String, newPassword: String, completion: @escaping ((ResponseData) -> Void)){
        let parameters = ["username": username,
                          "domain": domain,
                          "oldPassword": password,
                          "newPassword": newPassword] as [String : Any]
        let url = "\(self.baseUrl)/user/auth/first"
        let headers = [versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseString {
            (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func resetPassword(username: String, domain: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/password/reset"
        let params = [
            "recipientId": username,
            "domain": domain
            ] as [String: Any]
        let headers = [versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }

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
    
    class func getDomainCheck(domains: [String], token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/domain?\(domains.map { "domain=\($0)" }.joined(separator: "&"))"
        let headers = [versionHeader: apiVersion, "Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func generateRecoveryCode(recipientId: String, domain: String,token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/user/2fa/generatecode"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "recipientId": recipientId,
            "domain": domain
        ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func validateRecoveryCode(recipientId: String, domain: String, code: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/user/2fa/validatecode"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "code": code,
            "recipientId": recipientId,
            "domain": domain
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func createAlias(alias: String, domain: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/user/address"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "addressName": alias,
            "addressDomain": domain
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func activateAlias(rowId: Int, activate: Bool, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/user/address/activate"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "addressId": rowId,
            "activate": activate
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func deleteAlias(rowId: Int, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/user/address"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "addressId": rowId
            ] as [String: Any]
        Alamofire.request(url, method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func checkCustomDomainAvailability(customDomainName: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/domain/exist"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let customDomain = [ "name": customDomainName ] as [String:String]
        let params = [
            "domain": customDomain
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func registerCustomDomainAvailability(customDomainName: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/user/customdomain"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "customDomain": customDomainName
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func getMXCustomDomain(customDomainName: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/domain/mx/\(customDomainName)"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func validateMXCustomDomain(customDomainName: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/domain/validate/mx"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "customDomain": customDomainName
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func deleteCustomDomain(customDomain: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/user/customdomain"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "customDomain": customDomain
            ] as [String: Any]
        Alamofire.request(url, method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
}
