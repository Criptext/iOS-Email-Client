//
//  SharedExtensions.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/8/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit
import CommonCrypto

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
    
    func toColorString(hex: String)->UIColor {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        return UIColor.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
    
    func colorByName(name: String) -> UIColor{
        var color = "0091ff"
        let md5Data = Data.init().MD5(string: name)
        let md5 =  md5Data.map { String(format: "%02hhx", $0) }.joined()
        if(md5.count >= 7){
            let start = md5.index(md5.startIndex, offsetBy: 1)
            let end = md5.index(md5.startIndex, offsetBy: 7)
            let range = start..<end
            color = String(md5[range])
        }
        return toColorString(hex: color)
    }
}

extension String {
    static func localize(_ text: String) -> String {
        return NSLocalizedString(text, comment: "")
    }
    
    static func localize(_ text: String, arguments: CVarArg...) -> String {
        return String(format: String.localize(text), arguments: arguments)
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
                return UIImage(named: "icon-down")
            case .up:
                return UIImage(named: "icon-up")
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
    static let darkUI = UIColor(red: 55/255, green: 155/255, blue: 255/255, alpha: 1)
    static let alert = UIColor(red: 221/255, green: 64/255, blue: 64/255, alpha: 1)
    static let alertText = UIColor(red: 238/255, green: 163/255, blue: 163/255, alpha: 1)
    static let itemSelected = UIColor(red: 242/255, green: 248/255, blue: 255/255, alpha: 1)
    static let charcoal = UIColor(red: 55/255, green: 58/255, blue: 69/255, alpha: 1)
    static let disable = UIColor(red: 157/255, green: 157/255, blue: 157/255, alpha: 1)
    static let bright = UIColor(red: 106/255, green: 112/255, blue: 127/255, alpha: 1)
    static let defaultSecondary = UIColor(red: 106/255, green: 112/255, blue: 126/255, alpha: 1)
    static let darkSecondary = UIColor(red: 120/255, green: 128/255, blue: 148/255, alpha: 1)
    static let lightIcon = UIColor(red: 220/255, green: 221/255, blue: 224/255, alpha: 1)
    static let disableIcon = UIColor(red: 211/255, green: 211/255, blue: 211/255, alpha: 1)
    static let attachmentCell = UIColor(red: 250/255, green: 250/255, blue: 250/255, alpha: 1)
    static let attachmentBorder = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1)
    static let composeButton =  UIColor(red: 21/255, green: 33/255, blue: 46/255, alpha: 1)
    static let strongOpaque = UIColor(red: 248/255, green: 248/255, blue: 248/255, alpha: 1)
    static let opaque = UIColor(red: 244/255, green: 244/255, blue: 244/255, alpha: 1)
    static let placeholderLight = UIColor(red: 0, green: 0, blue: 0.0980392, alpha: 0.22)
    static let placeholderDark = UIColor(red:1.00, green:1.00, blue:1.00, alpha: 0.22)
    static let popoverButton = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1.0)
    static let separator = UIColor(red: 231/255, green: 231/255, blue: 231/255, alpha: 1)
    static let darkSeparator = UIColor(red: 64/255, green: 65/255, blue: 68/255, alpha: 1)
    static let darkBG = UIColor(red: 30/255, green: 34/255, blue: 40/255, alpha: 1)
    static let darkOpaque = UIColor(red: 41/255, green: 45/255, blue: 51/255, alpha: 1)
    static let darkGroupBorder = UIColor(red: 135/255, green: 136/255, blue: 143/255, alpha: 1)
    static let darkGroupTxt = UIColor(red: 213/255, green: 213/255, blue: 213/255, alpha: 1)
    static let cellHighlight = UIColor(red:253/255, green:251/255, blue:235/255, alpha:1.0)
    static let darkCellHighlight = UIColor(red: 33/255, green: 52/255, blue: 66/255, alpha: 1)
    static let darkBadge = UIColor(red: 89/255, green: 91/255, blue: 103/255, alpha: 1)
    static let darkSelected = UIColor(red: 52/255, green: 54/255, blue: 60/255, alpha: 1)
    static let strongText = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1)
    static let threadBadge = UIColor(red: 206/255, green: 206/255, blue: 206/255, alpha: 1)
    static let darkDetail = UIColor(red: 19/255, green: 24/255, blue: 30/255, alpha: 1)
    static let emailBorder = UIColor(red: 212/255, green: 204/255, blue: 204/255, alpha: 1)
    static let darkEmailBorder = UIColor(red: 69/255, green: 70/255, blue: 72/255, alpha: 1)
    static let bgBubble = UIColor(red: 0.94, green:0.94, blue: 0.94, alpha: 1.0)
    static let bgBubbleCriptext = UIColor(red: 0.90, green:0.96, blue: 1.0, alpha: 1.0)
    static let emailBubble = UIColor(red: 0.13, green:0.13, blue: 0.13, alpha: 1.0)
    static let darkBgBubble = UIColor(red: 52/255, green:54/255, blue:60/255, alpha: 1.0)
    static let darkBgBubbleCriptext = UIColor(red: 0, green: 52/255, blue: 111/255, alpha: 1.0)
    static let darkEmailBubble = UIColor(red: 102/255, green:187/255, blue: 1, alpha: 1.0)
    static let darkMenuText = UIColor(red: 180/255, green:181/255, blue: 190/255, alpha: 1.0)
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
    
    func MD5(string: String) -> Data {
        let messageData = string.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        return digestData
    }
}
