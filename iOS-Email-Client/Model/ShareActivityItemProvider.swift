//
//  ShareActivityItemProvider.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/30/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

class ShareActivityItemProvider: UIActivityItemProvider {
    var invitationText:String?
    var invitationTextMail:String?
    var subject:String?
    var otherappsText:String?
    
    override var item: Any {
        get {
            return ""
        }
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType?) -> Any? {
        
        var finalString = self.invitationText
        
        if activityType == .mail {
            finalString = self.invitationTextMail
        }
        
        return finalString
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
        return self.subject ?? ""
    }
    
    override func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return ""
    }
}
