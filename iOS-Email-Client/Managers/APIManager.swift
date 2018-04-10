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
}

class APIManager {
    static let baseUrl = "http://54.245.42.9:8000"
    
    static let CODE_SUCESS = 0
    static let CODE_JWT_INVALID = 101
    static let CODE_SESSION_INVALID = 102
    static let CODE_FILE_SIZE_EXCEEDED = 413
    static let CODE_REQUEST_CANCELLED = -999
    
    static let reachabilityManager = Alamofire.NetworkReachabilityManager()!
    
    class func singUpRequest(_ params: [String : Any], completion: @escaping ((Error?, String?) -> Void)){
        let url = "\(self.baseUrl)/user"
        
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default).responseString{
            (response) in
            guard let value = response.result.value else {
                completion(response.result.error, nil)
                return
            }
            completion(nil, value)
        }
    }
    
    class func loginRequest(_ username: String, _ password: String, completion: @escaping ((Error?, String?) -> Void)){
        let parameters = ["username": username,
                          "password": password,
                          "deviceId": 1] as [String : Any]
        let url = "\(self.baseUrl)/user/auth"
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default).responseString{
            (response) in
            guard let value = response.result.value else {
                completion(response.result.error, nil)
                return
            }
            completion(nil, value)
        }
    }
    
    class func sendKeysRequest(_ params: [String : Any], token: String, completion: @escaping ((Error?) -> Void)){
        let url = "\(self.baseUrl)/keybundle"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            response.result.ifFailure {
                completion(response.result.error)
                return
            }
            completion(nil)
        }
    }
    
    class func getKeysRequest(_ params: [String : Any], token: String, completion: @escaping ((Error?, Any?) -> Void)){
        let url = "\(self.baseUrl)/keybundle"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            
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
    
    class func postMailRequest(_ params: [String : Any], token: String, completion: @escaping ((Error?) -> Void)){
        let url = "\(self.baseUrl)/email"
        let headers = ["Authorization": "Bearer \(token)"]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            response.result.ifFailure {
                completion(response.result.error)
                return
            }
            completion(nil)
        }
    }
    
    class func request(url:String, method:HTTPMethod, parameters:Parameters?, headers:HTTPHeaders?, completion:@escaping (DataResponse<String>) -> Void){
        
        if let parameters = parameters {
            //try the request
            Alamofire.request(url, method: method, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
                
                
                if let value = response.result.value,
                    let dataFromString = value.data(using: .utf8, allowLossyConversion: false) {
                    let jsonVar = try! JSON(data: dataFromString)
                    
                    let errorCode = jsonVar["error"].intValue
                    
                    //check if it failed due to jwt expired or wrong session
                    if errorCode == CODE_JWT_INVALID || errorCode == CODE_SESSION_INVALID {
                        //auth request
                        
                        completion(response)
                        return
                    }
                }
                
                //return success to original request
                completion(response)
            }
            return
        }
        
        //try the request
        Alamofire.request(url, method: method, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            
            if let value = response.result.value,
                let dataFromString = value.data(using: .utf8, allowLossyConversion: false) {
                let jsonVar = try! JSON(data: dataFromString)
                
                let errorCode = jsonVar["error"].intValue
                //check if it failed due to jwt expired or wrong session
                if errorCode == CODE_JWT_INVALID || errorCode == CODE_SESSION_INVALID {
                    
                    completion(response)
                    return
                }
            }
            
            
            //return to original request
            completion(response)
        }
    }
    
    class func parseDisplayString(_ value:String) -> String{
        var toDisplayEmail = ""
        for tag in value.components(separatedBy: ",") {
            var copyTag = tag
            
            if let match = copyTag.range(of: " <[^ ]+", options: .regularExpression){
                
                copyTag.removeSubrange(match)
                
                if(toDisplayEmail == "") {
                    toDisplayEmail = copyTag
                }else{
                    toDisplayEmail = toDisplayEmail + "," + copyTag
                }
            }else {
                if(toDisplayEmail == "") {
                    toDisplayEmail = copyTag
                }else{
                    toDisplayEmail = toDisplayEmail + "," + copyTag
                }
            }
        }
        
        return toDisplayEmail
    }

}

extension APIManager {

//    class func upload(_ file:Data, id:String, fileName:String, mimeType:String, from user:User, delegate:ProgressDelegate?, completion: @escaping ((Error?, String?) -> Void)){
//        let url = "\(self.baseUrl)/v2.0/attachment/upload"
//
//        let headers = ["Authorization": "Basic \(user.auth)", "fileid": id]
//
//        let parameters = ["userid":String(user.id)]
//
//        Alamofire.upload(multipartFormData: { (multipartFormData) in
//            for (key, value) in parameters {
//                multipartFormData.append(value.data(using: String.Encoding.utf8)!, withName: key)
//            }
//            multipartFormData.append(file, withName: "files", fileName: fileName, mimeType: mimeType)
//        }, to: url, method: .post, headers: headers) { (result) in
//            switch result {
//            case .success(let upload, _, _):
//
//                upload.uploadProgress(closure: { (Progress) in
//                    print("Upload Progress: \(Progress.fractionCompleted)")
//                    if let delegate = delegate {
//                        delegate.updateProgress(Progress.fractionCompleted, for: id)
//                    }
//                })
//
//                upload.responseJSON { responseObject in
//
//                    guard responseObject.response?.statusCode == 200,
//                        let value = responseObject.result.value else {
//                            //check if request was cancelled
//
//                            if responseObject.result.isFailure,
//                                let error = responseObject.result.error as NSError?,
//                                error.code == CODE_REQUEST_CANCELLED {
//                                //do nothing
//                                return
//                            }
//
//                            var code = -1
//                            var userInfo = ["error": ["title":"Network Error", "description":"Please try again later"]]
//
//                            //check if error is due to file size
//                            if let response = responseObject.response, response.statusCode == CODE_FILE_SIZE_EXCEEDED {
//                                print("===== error file size")
//                                print(response.statusCode)
//                                code = response.statusCode
//
//                                userInfo["error"]!["title"] = nil
//
//                                userInfo["error"]!["description"] = "File size " + (user.isPro() ? "100 MB" : "5 MB") + " limit exceeded"
//                            }
//
//                            completion(NSError(domain: "com.criptext.com", code: code, userInfo: userInfo), nil)
//                            return
//                    }
//
//                    let jsonVar = JSON(value)
//
//                    let errorCode = jsonVar["error"].intValue
//
//                    guard errorCode == self.CODE_SUCESS else {
//                        completion(NSError(domain: "com.criptext.com", code: errorCode, userInfo: nil), nil)
//                        return
//                    }
//
//                    let token = jsonVar["tokenfile"].stringValue
//
//                    completion(nil, token)
//
//                    print("JSON: \(jsonVar)")
//                }
//
//            case .failure(let encodingError):
//                //self.delegate?.showFailAlert()
//                print(encodingError)
//                completion(NSError(domain: "com.criptext.com", code: -1, userInfo: ["error": ["title":"Network Error", "description":"Please try again later"]]), nil)
//            }
//        }
//    }
    
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
