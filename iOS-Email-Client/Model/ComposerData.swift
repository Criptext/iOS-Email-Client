//
//  ComposerData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/2/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ComposerData {
    var initAlias: Alias? = nil
    var attachmentArray = [File]()
    var contactArray = [Contact]()
    var initToContacts = [Contact]()
    var initCcContacts = [Contact]()
    var initSubject = ""
    var initContent = ""
    var emailDraft: Email?
    var threadId: String?
    var blockFrom = false
}
