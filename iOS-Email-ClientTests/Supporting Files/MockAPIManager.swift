//
//  MockAPIManager.swift
//  iOS-Email-ClientTests
//
//  Created by Pedro Aim on 6/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Alamofire
@testable import iOS_Email_Client

class MockAPIManager: APIManager {
    
    override class func getEmailBody(metadataKey: Int, token: String, queue: DispatchQueue? = .main, completion: @escaping ((ResponseData) -> Void)){
        completion(ResponseData.SuccessDictionary(["body": "ytw8v0ntriuhtkirglsdfnakncbdjshndls"]))
    }
    
    override class func acknowledgeEvents(eventIds: [Any], token: String){
        return
    }
    
    override class func commitFile(filetoken: String, token: String, completion: @escaping ((Error?) -> Void)){
        let url = "\(self.fileServiceUrl)/file/save"
        let headers = ["Authorization": "Bearer \(token)"]
        let params = ["files" : [
            ["token": filetoken]
            ]]
        Alamofire.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers).responseString { (response) in
            completion(response.error)
        }
    }
    
    override class func registerFile(token: String, parameters: [String: Any], completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.fileServiceUrl)/file/upload"
        let headers = ["Authorization": "Basic \(token)"]
        Alamofire.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers).responseJSON { (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    override class func uploadChunk(chunk: Data, params: [String: Any], token: String, progressDelegate: ProgressDelegate, completion: @escaping ((ResponseData) -> Void)){
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
                    let responseData = handleResponse(response, satisfy: .success)
                    completion(responseData)
                })
            case .failure(_):
                completion(ResponseData.Error(CriptextError(message: "Unable to handle request")))
            }
        }
    }
    
    override class func getFileMetadata(filetoken: String, token: String, completion: @escaping ((ResponseData) -> Void)){
        let url = "\(self.fileServiceUrl)/file/\(filetoken)"
        let headers = ["Authorization": "Basic \(token)"]
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON{
            (response) in
            let responseData = handleResponse(response)
            completion(responseData)
        }
    }
    
    override class func downloadChunk(filetoken: String, part: Int, token: String, progressDelegate: ProgressDelegate, completion: @escaping ((ResponseData) -> Void)){
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
                guard response.response?.statusCode != 200 else {
                    completion(ResponseData.SuccessString(fileURL.path))
                    return
                }
                completion(ResponseData.Error(CriptextError(code: .noValidResponse)))
        }
    }
}
