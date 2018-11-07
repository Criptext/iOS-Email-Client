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

class APIRequest {
    let baseUrl = "https://stage.mail.criptext.com"
    let apiVersion = "3.0.0"
    let versionHeader = "criptext-api-version"
    
    enum code: Int {
        case none = 0
        case success = 200
        case successNoContent = 204
        case successAccepted = 202
        case notModified = 304
        case badRequest = 400
        case unauthorized = 401
        case forbidden = 403
        case missing = 404
        case conflicts = 405
        case authPending = 491
        case authDenied = 493
        case tooManyDevices = 439
        case tooManyRequests = 429
        case serverError = 500
    }
    
    static let reachabilityManager = Alamofire.NetworkReachabilityManager()!
    
    private func handleResponse<T>(_ responseRequest: DataResponse<T>, satisfy: code? = nil) -> Any? {
        let response = responseRequest.response
        let error = responseRequest.error
        print("ALAMOFIRE SERVICE REQUEST : \(response?.url?.description ?? "NONE") -- \(response?.statusCode ?? 0)")
        
        if error?._code == NSURLErrorTimedOut || error?._code == NSURLErrorNotConnectedToInternet || error?._code == NSURLErrorNetworkConnectionLost {
            return nil
        }
        guard (response?.statusCode) != nil else {
            return nil
        }
        
        switch (responseRequest.result.value){
        case let result as [[String: Any]]:
            return result
        case let result as String:
            return result
        default:
            return nil
        }
    }
    
    func getEvents(token: String, completion: @escaping (([[String: Any]]?) -> Void)){
        let url = "\(self.baseUrl)/event"
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            guard let responseData = self.handleResponse(response) as? [[String: Any]] else {
                completion(nil)
                return
            }
            completion(responseData)
        }
    }
    
    func getEmailBody(metadataKey: Int, token: String, completion: @escaping ((String?) -> Void)){
        let url = "\(self.baseUrl)/email/body/\(metadataKey)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let headers = ["Authorization": "Bearer \(token)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { response in
            guard let responseData = self.handleResponse(response) as? String else {
                completion(nil)
                return
            }
            completion(responseData)
        }
    }
}


extension APIRequest {
    
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
