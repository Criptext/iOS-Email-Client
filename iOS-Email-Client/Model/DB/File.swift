//
//  File.swift
//  iOS-Email-Client
//
//  Created by Daniel Tigse on 4/4/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class File : Object {
    
    @objc dynamic var id = 0
    @objc dynamic var token = ""
    @objc dynamic var name = ""
    @objc dynamic var size = 0
    @objc dynamic var status = 1
    @objc dynamic var date = Date()
    @objc dynamic var readOnly = 0 //bool
    @objc dynamic var emailId = 0
    @objc dynamic var mimeType = ""
    var filePath = ""
    var progress = -1
    var filepath = ""
    var chunksProgress = [Int]()
    var requestType: CriptextFileManager.RequestType = .upload
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
}

extension File{
    func toDictionary(emailId: Int) -> [String: Any] {
        let dateString = DateUtils().date(toServerString: date)!
        return [
            "table": "file",
            "object": [
                "id": id,
                "token": token,
                "name": name,
                "size": size,
                "status": status,
                "date": dateString,
                "readOnly": readOnly == 0 ? false : true,
                "emailId": emailId
            ]
        ]
    }
}
