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

class APIManager {
    static let baseUrl = "https://stage.mail.criptext.com"
    static let fileServiceUrl = "https://services.criptext.com"
    
    static let CODE_SUCESS = 0
    static let CODE_JWT_INVALID = 101
    static let CODE_SESSION_INVALID = 102
    static let CODE_FILE_SIZE_EXCEEDED = 413
    static let CODE_REQUEST_CANCELLED = -999
    
    static let reachabilityManager = Alamofire.NetworkReachabilityManager()!
    
    class func checkAvailableUsername(_ username: String, completion: @escaping ((Error?) -> Void)) -> DataRequest{
        let url = "\(self.baseUrl)/user/available?username=\(username)"

        return Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default).responseString{
            (response) in
            guard response.result.isSuccess else {
                return
            }
            guard response.response?.statusCode == 200 else {
                let criptextError = CriptextError(code: .invalidUsername)
                completion(criptextError)
                return
            }
            completion(nil)
        }
    }
    
    class func singUpRequest(_ params: [String : Any], completion: @escaping ((Error?, String?) -> Void)){
        let url = "\(self.baseUrl)/user"
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default).responseString{
            (response) in
            guard response.response?.statusCode == 200 else {
                let error = CriptextError(code: .accountNotCreated)
                completion(error, nil)
                return
            }
            guard let value = response.result.value else {
                completion(response.result.error, nil)
                return
            }
            completion(nil, value)
        }
    }
    
    class func loginRequest(_ username: String, _ password: String, completion: @escaping ((Error?, [String: Any]?) -> Void)){
        let parameters = ["username": username,
                          "password": password] as [String : Any]
        let url = "\(self.baseUrl)/user/auth"
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseString{
            (response) in
            
            guard let value = response.result.value else {
                completion(response.result.error, nil)
                return
            }
            let data = Utils.convertToDictionary(text: value)
            completion(nil, data)
        }
    }
    
    class func postKeybundle(params: [String : Any], token: String, completion: @escaping ((Error?, String?) -> Void)){
        let url = "\(self.baseUrl)/keybundle"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            guard response.response?.statusCode == 200,
                let value = response.result.value else {
                let error = CriptextError(code: .accountNotCreated)
                completion(error, nil)
                return
            }
            completion(nil, value)
        }
    }
    
    class func getKeysRequest(_ params: [String : Any], token: String, queue: DispatchQueue, completion: @escaping ((Error?, Any?) -> Void)){
        let url = "\(self.baseUrl)/keybundle/find"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { response in
            switch(response.result) {
                case .success(let value):
                    completion(nil, value)
                    break
                case .failure(let error):
                    completion(error, nil)
                    break;
            }
        }
    }
    
    class func postMailRequest(_ params: [String : Any], token: String, queue: DispatchQueue, completion: @escaping ((Error?, Any?) -> Void)){
        let url = "\(self.baseUrl)/email"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { response in
            guard let value = response.result.value else {
                completion(response.error, nil)
                return
            }
            completion(nil, value)
        }
    }
    
    class func postPeerEvent(_ params: [String : Any], token: String, completion: @escaping ((Error?) -> Void)){
        let url = "\(self.baseUrl)/event/peers"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).response{ response in
            guard response.response?.statusCode == 200 else {
                let error = CriptextError(code: .noValidResponse)
                completion(error)
                return
            }
            completion(nil)
        }
    }
    
    class func getEvents(token: String, completion: @escaping ((Error?, Any?) -> Void)){
        let url = "\(self.baseUrl)/event"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            guard let value = response.result.value else {
                completion(response.error, nil)
                return
            }
            completion(nil, value)
        }
    }
    
    class func getEmailBody(metadataKey: Int, token: String, completion: @escaping ((Any?, Any?) -> Void)){
        let url = "\(self.baseUrl)/email/body/\(metadataKey)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { response in
            if response.response?.statusCode == 404 {
                completion(CriptextError(code: .bodyUnsent), nil)
                return
            }
            guard let value = response.result.value else {
                completion(response.error, nil)
                return
            }
            completion(nil, value)
        }
    }
    
    class func acknowledgeEvents(eventIds: [Int32], token: String){
        let parameters = ["ids": eventIds] as [String : Any]
        let url = "\(self.baseUrl)/event/ack"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
    }
    
    class func notifyOpen(keys: [Int], token: String){
        let url = "\(self.baseUrl)/event/open"
        let headers = ["Authorization": "Bearer \(token)"]
        let params = [
            "metadataKeys": keys
        ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
    }
    
    class func unsendEmail(key: Int, recipients: [String], token: String, completion: @escaping ((Error?) -> Void)){
        let url = "\(self.baseUrl)/email/unsend"
        let headers = ["Authorization": "Bearer \(token)"]
        let params = [
            "metadataKey": key,
            "recipients": recipients
            ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).response { response in
            guard response.response?.statusCode == 200 else {
                    let error = CriptextError(code: .noValidResponse)
                    completion(error)
                    return
            }
            completion(nil)
        }
    }
    
    class func registerFile(parameters: [String: Any], token: String, completion: @escaping ((Error?, Any?) -> Void)){
        let url = "\(self.fileServiceUrl)/file/upload"
        let headers = ["Authorization": "Basic \(token)"]
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
        let headers = ["Authorization": "Basic \(token)"]
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
        let headers = ["Authorization": "Basic \(token)"]
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
        let headers = ["Authorization": "Basic \(token)"]
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
    class func isValidEmail(text:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: text)
    }
    
    class func cancelUpload(_ id:String) {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (_, uploadDataArray, _) in
            for upload in uploadDataArray {
                guard let request = upload.originalRequest else {
                    continue
                }
                
                if let fileId = request.value(forHTTPHeaderField: "fileid"), fileId == id {
                    upload.cancel()
                    break
                }
            }
        }
    }
    
    class func cancelAllRequests(){
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataArray, uploadDataArray, downloadDataArray) in
            sessionDataArray.forEach { $0.cancel() }
            uploadDataArray.forEach { $0.cancel() }
            downloadDataArray.forEach { $0.cancel() }
        }
    }
    
    class func cancelAllUploads(){
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (_, uploadDataArray, _) in
            uploadDataArray.forEach { $0.cancel() }
        }
    }
}
