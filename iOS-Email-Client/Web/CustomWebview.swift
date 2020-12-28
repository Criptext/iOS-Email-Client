//
//  CustomWebview.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 12/28/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class CustomWebview: WKWebView {
    var accessoryView: UIView!
    
    override var inputAccessoryView: UIView? {
        get {
            if accessoryView == nil {
                let customView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 44))
                customView.backgroundColor = UIColor.red
                accessoryView = customView
            }
            return accessoryView
        }
        set {
            accessoryView = newValue
        }
    }
}
