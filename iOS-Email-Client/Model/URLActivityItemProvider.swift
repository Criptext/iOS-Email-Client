//
//  URLActivityItemProvider.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/30/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

class URLActivityItemProvider: UIActivityItemProvider {
    var urlInvite:URL!
    
    override var item: Any{
        get {
            return self.urlInvite
        }
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any? {
        return self.urlInvite
    }
    
    override func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return self.urlInvite
    }
}
