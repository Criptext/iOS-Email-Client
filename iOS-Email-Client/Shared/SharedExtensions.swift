//
//  SharedExtensions.swift
//  iOS-Email-Client
//
//  Created by Allisson on 11/8/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"%06x", rgb)
    }
}

extension String {
    static func localize(_ text: String) -> String {
        return NSLocalizedString(text, comment: "")
    }
    
    func hideMidChars() -> String {
        return String(self.enumerated().map { index, char in
            return [0, self.count - 1].contains(index) ? char : "*"
        })
    }
}

extension Array {
    func appending(_ newElement: Element) -> Array {
        var a = Array(self)
        a.append(newElement)
        return a
    }
}

enum Icon {
    case activated
    case enabled
    case disabled
    
    enum arrow {
        case up
        case down
        
        var image: UIImage? {
            switch self {
            case .down:
                return UIImage(named: "arrow-down")
            case .up:
                return UIImage(named: "arrow-up")
            }
        }
    }
    
    enum new_arrow {
        case up
        case down
        
        var image: UIImage? {
            switch self {
            case .down:
                return UIImage(named: "new-arrow-down")
            case .up:
                return UIImage(named: "new-arrow-up")
            }
        }
    }
    
    case camera
    case library
    case icloud
    case lock
    case lock_open
    case not_open
    case not_timer
    case unsend
    case activity
    case btn_unsend
    case btn_unsent
    case my_account
    case send
    case send_secure
    case upgrade
    case system
    case reply
    case forward
    case compose
    
    enum attachment {
        case vertical
        case regular
        case secure
        case image
        case expired
        case generic
        case word
        case ppt
        case pdf
        case excel
        case zip
        case audio
        case video
        
        var image: UIImage? {
            switch self {
            case .vertical:
                return UIImage(named: "attachment")
            case .regular:
                return UIImage(named: "attachment_regular")
            case .secure:
                return UIImage(named: "attachment_inbox")
            case .image:
                return UIImage(named: "attachment_image")
            case .expired:
                return UIImage(named: "attachment_expired")
            case .generic:
                return UIImage(named: "attachment_generic")
            case .word:
                return UIImage(named: "attachment_word")
            case .ppt:
                return UIImage(named: "attachment_ppt")
            case .pdf:
                return UIImage(named: "attachment_pdf")
            case .excel:
                return UIImage(named: "attachment_excel")
            case .zip:
                return UIImage(named: "attachment_zip")
            case .audio:
                return UIImage(named: "attachment_audio")
            case .video:
                return UIImage(named: "attachment_video")
            }
            
        }
    }
    
    var color: UIColor {
        switch self {
        case .activated:
            return UIColor(red:0.00, green:0.56, blue:1.00, alpha:1.0)
        case .disabled:
            return UIColor(red:0.59, green:0.59, blue:0.59, alpha:1.0)
        case .system:
            return UIColor(red:0.00, green:0.48, blue:1.00, alpha:1.0)
        case .enabled:
            fallthrough
        default:
            return UIColor(red:0.50, green:0.50, blue:0.50, alpha:1.0)
        }
    }
    
    var image: UIImage? {
        switch self {
        case .compose:
            return UIImage(named: "composer")
        case .camera:
            return UIImage(named: "attachment_camera")
        case .library:
            return UIImage(named: "attachment_photolibrary")
        case .icloud:
            return UIImage(named: "attachment_docproviders")
        case .lock:
            return UIImage(named: "switch_locked_on")
        case .lock_open:
            return UIImage(named: "switch_locked_off")
        case .not_open:
            return UIImage(named: "not-open")
        case .not_timer:
            return UIImage(named: "not-timer")
        case .unsend:
            return UIImage(named: "unsend")
        case .activity:
            return UIImage(named: "activity")
        case .btn_unsend:
            return UIImage(named: "unsend_btn")
        case .btn_unsent:
            return UIImage(named: "unsent_btn")
        case .my_account:
            return UIImage(named: "my_account")
        case .send:
            return UIImage(named: "send")
        case .send_secure:
            return UIImage(named: "send_secure")
        case .upgrade:
            return UIImage(named: "slider_upgrade")
        case .forward:
            return UIImage(named: "inbox-forward-icon")
        case .reply:
            return UIImage(named: "inbox-reply-icon")
        default:
            return UIImage()
        }
    }
}

extension UIColor {
    
    static let mainUI = UIColor(red: 0, green: 145/255, blue: 255/255, alpha: 1)
    static let mainUILight = UIColor(red: 0, green: 145/255, blue: 255/255, alpha: 0.63)
    static let neutral = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1)
    static let alert = UIColor(red: 221/255, green: 64/255, blue: 64/255, alpha: 1)
    static let alertLight = UIColor(red: 227/255, green: 102/255, blue: 102/255, alpha: 1)
    static let alertText = UIColor(red: 238/255, green: 163/255, blue: 163/255, alpha: 1)
    static let itemSelected = UIColor(red: 242/255, green: 248/255, blue: 255/255, alpha: 1)
    static let lightText = UIColor(red: 55/255, green: 58/255, blue: 69/255, alpha: 1)
    static let bright = UIColor(red: 157/255, green: 157/255, blue: 157/255, alpha: 1)
    static let charcoal = UIColor(red: 106/255, green: 112/255, blue: 127/255, alpha: 1)
    static let lightIcon = UIColor(red: 220/255, green: 221/255, blue: 224/255, alpha: 1)
    
}

enum Font {
    case regular
    case bold
    case semibold
    case italic
    
    func size(_ size:CGFloat) -> UIFont?{
        switch self {
        case .bold:
            return UIFont(name: "NunitoSans-Bold", size: size)
        case .semibold:
            return UIFont(name: "NunitoSans-SemiBold", size: size)
        case .italic:
            return UIFont(name: "NunitoSans-Italic", size: size)
        default:
            return UIFont(name: "NunitoSans-Regular", size: size)
        }
    }
    
    func attributedString(_ text:String, size:CGFloat) -> NSMutableAttributedString{
        switch self {
        case .bold:
            let font = UIFont(name: "NunitoSans-Bold", size: size)!
            let attrs = [NSAttributedString.Key.font : font]
            return NSMutableAttributedString(string:text, attributes:attrs)
        case .semibold:
            let font = UIFont(name: "NunitoSans-SemiBold", size: size)!
            let attrs = [NSAttributedString.Key.font : font]
            return NSMutableAttributedString(string:text, attributes:attrs)
        case .italic:
            let font = UIFont(name: "NunitoSans-Italic", size: size)!
            let attrs = [NSAttributedString.Key.font : font]
            return NSMutableAttributedString(string:text, attributes:attrs)
        default:
            let font = UIFont(name: "NunitoSans-Regular", size: size)!
            let attrs = [NSAttributedString.Key.font : font]
            return NSMutableAttributedString(string:text, attributes:attrs)
        }
    }
}

var DJB_TYPE : UInt8 = 0x05;

extension Data {
    
    func prependByte() -> Data {
        guard self.count == 32 else {
            return self
        }
        let myData = NSMutableData(bytes: &DJB_TYPE, length: 1)
        myData.append(self)
        return myData as Data
    }
    
    func removeByte() -> Data {
        guard self.count == 33 else {
            return self
        }
        return self.suffix(from: 1)
    }
    
    func customBase64String() -> String {
        let dataPlus = self.prependByte()
        let customBase64String = dataPlus.base64EncodedString()
        return customBase64String
    }
    
    func plainBase64String() -> String {
        let customBase64String = self.base64EncodedString()
        return customBase64String
    }
}
