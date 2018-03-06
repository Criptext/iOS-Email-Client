//
//  RawSessionRecord.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class RawSessionRecord: Object{
    @objc dynamic var contactId = ""
    @objc dynamic var deviceId = 0
    @objc dynamic var sessionRecord = ""
}
