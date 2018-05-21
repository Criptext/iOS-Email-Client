//
//  Utils.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class Utils{
    
    class func createLabelWithDynamicHeight(_ width: CGFloat, _ fontSize: CGFloat) -> UILabel {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        
        label.textColor=UIColor.black
        label.lineBreakMode = .byWordWrapping
        label.font = Font.regular.size(fontSize)
        label.numberOfLines = 0
        
        return label
    }
    
    class func getLabelHeight(_ text: Any, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        let label = createLabelWithDynamicHeight(width, fontSize)
        if text is NSMutableAttributedString {
            label.attributedText = text as! NSMutableAttributedString
        } else {
            label.text = text as? String
        }
        
        label.sizeToFit()
        return label.frame.height
    }
    
    class func getNumberOfLines(_ text: String, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        let label = createLabelWithDynamicHeight(width, fontSize)
        label.text = text
        label.sizeToFit()
        return label.frame.height/label.font.pointSize
    }
    
    class func generateRandomColor() -> UIColor {
        let hue : CGFloat = CGFloat(arc4random() % 256) / 256
        let saturation : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        let brightness : CGFloat = CGFloat(arc4random() % 128) / 256 + 0.5
        
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }
    
    class func convertToDictionary(text: String) -> [String: Any]? {
        guard let data = text.data(using: .utf8) else {
            return nil
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
        } catch {
            print(error.localizedDescription)
        }
        return nil
    }
    
    class func getUsernameFromEmailFormat(_ emailFormat: String) -> String? {
        let email = NSString(string: emailFormat)
        let pattern = "(?<=\\<).*(?=@)"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: emailFormat, options: [], range: NSRange(location: 0, length: email.length))
        guard let range = matches.first?.range else {
            return nil
        }
        return email.substring(with: range)
    }
    
    class func getImageByFileType(_ type: String) -> UIImage {
        switch type {
        case "application/pdf":
            return #imageLiteral(resourceName: "attachment_pdf")
        case _ where type.contains("application/msword") ||
            type.contains("application/vnd.openxmlformats-officedocument.wordprocessingml") ||
            type.contains("application/vnd.ms-word"):
            return #imageLiteral(resourceName: "attachment_word")
        case "image/png", "image/jpeg":
            return #imageLiteral(resourceName: "attachment_image")
        case _ where type.contains("application/vnd.ms-powerpoint") ||
            type.contains("application/vnd.openxmlformats-officedocument.presentationml"):
            return #imageLiteral(resourceName: "attachment_ppt")
        case _ where type.contains("application/vnd.ms-excel") ||
            type.contains("application/vnd.openxmlformats-officedocument.spreadsheetml"):
            return #imageLiteral(resourceName: "attachment_excel")
        default:
            return #imageLiteral(resourceName: "attachment_generic")
        }
    }
}
