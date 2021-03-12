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
    static let apiVersion = "12.0.0"
    static let versionHeader = "criptext-api-version"
    static let language = "accept-language"
    
    enum code: Int {
        case none = 0
        case success = 200
        case successAndRepeat = 201
        case successNoContent = 204
        case successAccepted = 202
        case notModified = 304
        case badRequest = 400
        case unauthorized = 401
        case forbidden = 403
        case missing = 404
        case conflicts = 405
        case conflict = 409
        case removed = 419
        case authPending = 491
        case authDenied = 493
        case tooManyDevices = 439
        case preConditionRequired = 428
        case tooManyRequests = 429
        case versionNotSupported = 430
        case preConditionFail = 412
        case entityTooLarge = 413
        case enterpriseSuspended = 451
        case serverError = 500
    }
    
    static let reachabilityManager = Alamofire.NetworkReachabilityManager()!
    
    open class func handleResponse<T>(_ responseRequest: DataResponse<T>, satisfy: code? = nil, alwaysReturnJSON: Bool = false) -> ResponseData {
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
            if alwaysReturnJSON,
               let resultObj = responseRequest.result.value as? [String: Any] {
                return .BadRequestDictionary(resultObj)
            }
            return .BadRequest
        case .authDenied:
            return .AuthDenied
        case .authPending:
            return .AuthPending
        case .removed:
            return .Removed
        case .tooManyRequests:
            let waitingTime = Int64(response?.allHeaderFields["retry-after"] as? String ?? "-1") ?? -1
            return .TooManyRequests(waitingTime)
        case .tooManyDevices:
            return .TooManyDevices
        case .entityTooLarge:
            let maxSize = Int64(response?.allHeaderFields["max-size"] as? String ?? "-1") ?? -1
            return .EntityTooLarge(maxSize)
        case .conflict:
            return .Conflict
        case .conflicts:
            if let resultObj = responseRequest.result.value as? [String: Any],
                let errorInt = resultObj["error"] as? Int {
                if let data = resultObj["data"] as? [String: Any] {
                    return .ConflictsData(errorInt, data)
                } else {
                    return .ConflictsInt(errorInt)
                }
            }
            return .Conflicts
        case .success, .successAndRepeat, .successAccepted, .successNoContent, .notModified:
            break
        case .preConditionRequired:
            guard let resultObj = responseRequest.result.value as? [String: Any],
                let daysLeft = resultObj["daysLeft"] as? Int else {
                return .Error(CriptextError(message: responseRequest.result.description))
            }
            return .PreConditionRequired(daysLeft)
        case .preConditionFail:
            return .PreConditionFail
        case .enterpriseSuspended:
            return .EnterpriseSuspended
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
            if status == code.successAndRepeat.rawValue {
                return .SuccessAndRepeat(result)
            }
            return .SuccessArray(result)
        case let result as [String: Any]:
            return .SuccessDictionary(result)
        case let result as String:
            return .SuccessString(result)
        default:
            return .Success
        }
    }
    
    class func authorizationRequest(responseData: ResponseData, token: String, queue: DispatchQueue? = nil, completionHandler: @escaping ((ResponseData?, String) -> Void)) {
        guard case .Unauthorized = responseData else {
            completionHandler(responseData, token)
            return
        }
        guard let account = SharedDB.getAccount(token: token) else {
            completionHandler(ResponseData.Error(CriptextError(code: .unreferencedAccount)), token)
            return
        }
        guard let refreshToken = account.refreshToken else {
            updgrateToRefreshToken(responseData: responseData, token: token, queue: queue, completionHandler: completionHandler)
            return
        }
        
        let url = "\(self.baseUrl)/user/refreshtoken"
        let headers = [
            "Authorization": "Bearer \(refreshToken)",
            language: Env.language,
            versionHeader: apiVersion
        ]
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseString(queue: queue) { (response) in
            let refreshResponseData = handleResponse(response)
            switch (refreshResponseData) {
                case .SuccessString(let data):
                    if let jsonData = Utils.convertToDictionary(text: data) {
                        let newJwt = jsonData["token"] as! String
                        let newRefreshToken = jsonData["refreshToken"] as! String
                        SharedDB.update(oldJwt: token, jwt: newJwt, refreshToken: newRefreshToken)
                        SharedDB.refresh()
                        completionHandler(nil, newJwt)
                    } else {
                        SharedDB.update(oldJwt: token, jwt: data)
                        SharedDB.refresh()
                        completionHandler(nil, data)
                    }
                    break
                default:
                    completionHandler(refreshResponseData, token)
                
            }
        }
    }
    
    class func updgrateToRefreshToken(responseData: ResponseData, token: String, queue: DispatchQueue? = nil, completionHandler: @escaping ((ResponseData?, String) -> Void)) {
        let url = "\(self.baseUrl)/user/refreshtoken/upgrade"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { (response) in
            let refreshResponseData = handleResponse(response)
            guard case let .SuccessDictionary(data) = refreshResponseData,
                let newToken = data["token"] as? String,
                let newRefreshToken = data["refreshToken"] as? String else {
                completionHandler(refreshResponseData, token)
                return
            }
            SharedDB.update(oldJwt: token, refreshToken: newRefreshToken, jwt: newToken)
            SharedDB.refresh()
            completionHandler(nil, newToken)
        }
    }
    
    class func getEvents(token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/event"
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
                self.getEvents(token: newToken, completion: completion)
            }
        }
    }
    
    class func getEmailBody(metadataKey: Int, token: String, queue: DispatchQueue? = .main, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/email/body/\(metadataKey)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { response in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.getEmailBody(metadataKey: metadataKey, token: newToken, completion: completion)
            }
        }
    }
    
    class func reEncryptEmail(metadataKey: Int, eventId: Any, token: String, queue: DispatchQueue? = .main, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/email/reencrypt"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        let params = [
        "metadataKey": metadataKey,
        "eventid": eventId,
        ] as [String: Any]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseJSON(queue: queue) { response in
            let responseData = handleResponse(response)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.reEncryptEmail(metadataKey: metadataKey, eventId: eventId, token: newToken, completion: completion)
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
    class func postReportContact(emails: [String], type: ContactUtils.ReportType, data: String?, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.baseUrl)/contact/report"
        let headers = [
            "Authorization": "Bearer \(token)",
            versionHeader: apiVersion,
            language: Env.language
        ]
        var params = [
        "emails": emails,
        "type": type.rawValue,
        ] as [String: Any]
        if(data != nil){
            params["headers"] = data
        }
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { response in
            let responseData = handleResponse(response, satisfy: .success)
            self.authorizationRequest(responseData: responseData, token: token) { (refreshResponseData, newToken) in
                if let refreshData = refreshResponseData {
                    completion(refreshData)
                    return
                }
                self.postReportContact(emails: emails, type: type, data: data, token: newToken, completion: completion)
            }
        }
    }
}

