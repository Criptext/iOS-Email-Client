//
//  ComposerModelView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/1/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST

class ComposerModelView{
    var currentUser:User!
    var currentService: GTLRService!
    var replyingEmail: Email?
    var replyBody: String?
    
    var thumbUpdated = false
    var isEdited = false
    //draft
    var isDraft = false
    var emailDraft: Email?
    
    var emailSignature: String{
        return currentUser.emailSignature;
    }
}
