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
