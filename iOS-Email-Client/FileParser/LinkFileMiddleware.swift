//
//  LinkFileMiddleware.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 5/11/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

protocol LinkFileInterface: class {
    func handleLinkFileRow(realm: Realm, row: [String: Any], maps: inout LinkDBMaps, accountId: String)
}

struct LinkDBMaps {
    var emails: [Int: Int]
    var contacts: [Int: String]
}

class LinkFileMiddleware {
    
    let linkFileInterface: LinkFileInterface
    
    init(version: Int) throws {
        switch(version) {
            case 6:
                linkFileInterface = LinkFileHandlerVersion6()
                break
            default:
                throw CriptextError.init(code: .fileVersionTooOld)
        }
    }
    
    func insertBatchRows(rows: [[String: Any]], maps: inout LinkDBMaps, accountId: String){
        let realm = try! Realm()
        try! realm.write {
            for row in rows {
                linkFileInterface.handleLinkFileRow(realm: realm, row: row, maps: &maps, accountId: accountId)
            }
        }
    }
}
