//
//  File.swift
//  iOS-Email-Client
//
//  Created by Daniel Tigse on 4/4/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift
import MobileCoreServices

class File : Object {
    
    @objc dynamic var token = ""
    @objc dynamic var name = ""
    @objc dynamic var size = 0
    @objc dynamic var status = 1
    @objc dynamic var date = Date()
    @objc dynamic var readOnly = 0 //bool
    @objc dynamic var emailId = 0
    @objc dynamic var mimeType = ""
    @objc dynamic var shouldDuplicate = false
    @objc dynamic var originalToken: String?
    @objc dynamic var fileKey:String = ""
    @objc dynamic var cid:String?
    var filePath = ""
    var progress = -1
    var filepath = ""
    var chunksProgress = [Int]()
    var requestType: RequestType = .upload
    var requestStatus: uploadStatus = .none

    override static func primaryKey() -> String? {
        return "token"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["progress", "filepath", "chunksProgress", "requestStatus", "requestType"]
    }
    
    func prettyPrintSize() -> String {
        return File.prettyPrintSize(size: self.size)
    }
    
    class func prettyPrintSize(size: Int) -> String {
        let formatter = ByteCountFormatter()
        return formatter.string(fromByteCount: Int64(size))
    }
    
    enum uploadStatus {
        case none
        case pending
        case processing
        case finish
        case failed
    }
    
    enum RequestType {
        case upload
        case download
    }
    
    class func getKeyAndIv(key: String) -> (Data, Data){
        let keys = key.split(separator: ":")
        return (Data(base64Encoded: String(keys[0]), options: .ignoreUnknownCharacters)!, Data(base64Encoded: String(keys[1]), options: .ignoreUnknownCharacters)!)
    }
    
    class func getKeyCodedString(key: Data, iv: Data) -> String{
        return "\(key.base64EncodedString()):\(iv.base64EncodedString())"
    }
}

extension File{
    func toDictionary(id: Int, emailId: Int) -> [String: Any] {
        let dateString = DateUtils().date(toServerString: date)!
        var object = [
            "id": id,
            "token": token,
            "name": name,
            "size": size,
            "status": status,
            "date": dateString,
            "readOnly": readOnly == 0 ? false : true,
            "emailId": emailId,
            "mimeType": mimeType.isEmpty ? File.mimeTypeForPath(path: name) : mimeType
        ] as [String: Any]
        if(cid != nil && cid != ""){
            object["cid"] = cid
        }
        if (!fileKey.isEmpty && fileKey != "null:null") {
            object["key"] = String(fileKey.split(separator: ":").first!)
            object["iv"] = String(fileKey.split(separator: ":").last!)
        }
        return [
            "table": "file",
            "object": object
        ]
    }
    
    class func mimeTypeForPath(path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        
        if let pathExtension = url.pathExtension,
            let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue(),
            let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue(){
            return mimetype as String
        }
        return "application/octet-stream"
    }
    
    func duplicate() -> File {
        let newFile = File()
        newFile.token = "\(self.token):\(Date().timeIntervalSince1970)"
        newFile.name = self.name
        newFile.size = self.size
        newFile.status = self.status
        newFile.date = self.date
        newFile.readOnly = self.readOnly
        newFile.mimeType = self.mimeType
        newFile.cid = self.cid
        newFile.shouldDuplicate = true
        newFile.originalToken = self.token
        newFile.fileKey = self.fileKey
        return newFile
    }
}
