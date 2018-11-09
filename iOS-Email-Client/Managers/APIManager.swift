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
    static let linkUrl = "https://transfer.criptext.com"
    
    class func postKeybundle(params: [String : Any], token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/keybundle"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func getKeybundle(deviceId: Int32, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/keybundle/\(deviceId)"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func getKeysRequest(_ params: [String : Any], token: String, queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/keybundle/find"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { response in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func postMailRequest(_ params: [String : Any], token: String, queue: DispatchQueue, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/email"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { response in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func postPeerEvent(_ params: [String : Any], token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/event/peers"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func acknowledgeEvents(eventIds: [Int32], token: String){
        let parameters = ["ids": eventIds] as [String : Any]
        let url = "\(self.baseUrl)/event/ack"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
    }
    
    class func notifyOpen(keys: [Int], token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/event/open"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "metadataKeys": keys
        ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func unsendEmail(key: Int, recipients: [String], token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/email/unsend"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "metadataKey": key,
            "recipients": recipients
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func registerToken(fcmToken: String, token: String, completion: ((ResponseData) -> Void)? = nil){
        let url = "\(self.baseUrl)/keybundle/pushtoken"
        let params = [
            "devicePushToken": fcmToken
        ]
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion?(responseData)
        }
    }
    
    class func updateName(name: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/name"
        let params = [
            "name": name
        ]
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }

    class func getSettings(token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/settings"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON {
            (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func removeDevice(deviceId: Int, password: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/device"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "deviceId": deviceId,
            "password": password
        ] as [String: Any]
        Alamofire.request(url, method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func changeRecoveryEmail(email: String, password: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/recovery/change"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "email": email,
            "password": password
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func resendConfirmationEmail(token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/recovery/resend"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString {
            (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func setTwoFactor(isOn: Bool, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/2fa"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "enable": isOn
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }

    class func changePassword(oldPassword: String, newPassword: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/password/change"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "oldPassword": oldPassword,
            "newPassword": newPassword
            ] as [String: Any]
        Alamofire.request(url, method: .put, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func unlockDevice(password: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/device/unlock"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = [
            "password": password
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func logout(token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/user/logout"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func registerFile(parameters: [String: Any], token: String, completion: @escaping ((Error?, Any?) -> Void)){
        let url = "\(self.fileServiceUrl)/file/upload"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            guard let value = response.result.value else {
                completion(response.error, nil)
                return
            }
            completion(nil, value)
        }
    }
    
    class func uploadChunk(chunk: Data, params: [String: Any], token: String, progressDelegate: ProgressDelegate, completion: @escaping ((Error?) -> Void)){
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
                    if let error = response.error {
                        completion(error)
                        return
                    }
                    guard response.response?.statusCode == 200 else {
                        let criptextError = CriptextError(code: .noValidResponse)
                        completion(criptextError)
                        return
                    }
                    completion(nil)
                })
            case .failure(_):
                let error = CriptextError(code: .noValidResponse)
                completion(error)
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
        let headers = ["Authorization": "Basic \(token)"]
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
    
    class func linkAccept(randomId: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/accept"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = ["randomId": randomId] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    class func linkDeny(randomId: String, token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/deny"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        let params = ["randomId": randomId] as [String : Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
        }
    }
    
    class func linkDataAddress(params: [String: Any], token: String, completion: @escaping ((ResponseData) -> Void)) {
        let url = "\(self.baseUrl)/link/data/ready"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            let responseData = handleResponse(response, satisfy: .success)
            completion(responseData)
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
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString{
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
        let url = "\(self.linkUrl)/userdata"
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
        let url = "\(self.linkUrl)/userdata?id=\(address)"
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
