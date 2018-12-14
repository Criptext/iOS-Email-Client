//
//  SharedAPI.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/7/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

import Foundation
import SwiftyJSON
import Alamofire
import RealmSwift

class SharedAPI {
    static let baseUrl = Env.apiURL
    static let apiVersion = "4.0.0"
    static let versionHeader = "criptext-api-version"
    
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
        case entityTooLarge = 413
        case serverError = 500
    }
    
    static let reachabilityManager = Alamofire.NetworkReachabilityManager()!
    
    open class func handleResponse<T>(_ responseRequest: DataResponse<T>, satisfy: code? = nil) -> ResponseData {
        let response = responseRequest.response
        let error = responseRequest.error
        print("ALAMOFIRE REQUEST : \(response?.url?.description ?? "NONE") -- \(response?.statusCode ?? 0)")
        
        if error?._code == NSURLErrorTimedOut {
            return ResponseData.Error(CriptextError(code: .timeout))
        } else if error?._code == NSURLErrorNotConnectedToInternet || error?._code == NSURLErrorNetworkConnectionLost  {
            return ResponseData.Error(CriptextError(code: .offline))
        }
        guard let status = response?.statusCode else {
            return .Error(CriptextError(message: "Unable to get a valid response"))
        }
        
        switch(code.init(rawValue: status) ?? .none){
        case satisfy:
            return .Success
        case .unauthorized:
            return .Unauthorized
        case .forbidden:
            return .Forbidden
        case .missing:
            return .Missing
        case .badRequest:
            return .BadRequest
        case .authDenied:
            return .AuthDenied
        case .authPending:
            return .AuthPending
        case .tooManyRequests:
            let waitingTime = Int64(response?.allHeaderFields["retry-after"] as? String ?? "-1") ?? -1
            return .TooManyRequests(waitingTime)
        case .tooManyDevices:
            return .TooManyDevices
        case .entityTooLarge:
            let maxSize = Int64(response?.allHeaderFields["max-size"] as? String ?? "-1") ?? -1
            return .EntityTooLarge(maxSize)
        case .conflicts:
            return .Conflicts
        case .success, .successAccepted, .successNoContent, .notModified:
            break
        default:
            guard status < code.serverError.rawValue else {
                return .ServerError
            }
            return .Error(CriptextError(message: responseRequest.result.description))
        }
        
        switch (responseRequest.result.value){
        case let result as Int:
            return .SuccessInt(result)
        case let result as [[String: Any]]:
            return .SuccessArray(result)
        case let result as [String: Any]:
            return .SuccessDictionary(result)
        case let result as String:
            return .SuccessString(result)
        default:
            return .Success
        }
    }
    
    class func authorizationRequest(responseData: ResponseData, account: Account, queue: DispatchQueue? = nil, completionHandler: @escaping ((ResponseData?) -> Void)) {
        guard case .Unauthorized = responseData else {
            completionHandler(responseData)
            return
        }
        guard let refreshToken = account.refreshToken else {
            return
        }
        let url = "\(self.baseUrl)/user/refreshtoken"
        let headers = ["Authorization": "Bearer \(refreshToken)",
            versionHeader: apiVersion]
        let accountRef = SharedDB.getReference(account)
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString(queue: queue) { (response) in
            guard let refdAccount = SharedDB.getObject(accountRef) as? Account else {
                completionHandler(ResponseData.Error(CriptextError(code: .unreferencedAccount)))
                return
            }
            let refreshResponseData = handleResponse(response)
            guard case let .SuccessString(newJwt) = refreshResponseData else {
                completionHandler(refreshResponseData)
                return
            }
            SharedDB.update(refdAccount, jwt: newJwt)
            completionHandler(nil)
        }
    }
    
    class func getEvents(account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/event"
        let headers = ["Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON { response in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.getEvents(account: account, completion: completion)
            }
        }
    }
    
    class func getEmailBody(metadataKey: Int, account: Account, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/email/body/\(metadataKey)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let headers = ["Authorization": "Bearer \(account.jwt)",
            versionHeader: apiVersion]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, account: account) { (refreshResponseData) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.getEmailBody(metadataKey: metadataKey, account: account, completion: completion)
            }
        }
    }
}

extension SharedAPI {
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

