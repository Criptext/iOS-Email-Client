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

    class func convertToJSONString(dictionary: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    class func getUsernameFromEmailFormat(_ emailFormat: String) -> String? {
        let email = NSString(string: emailFormat)
        let pattern = "(?<=\\<).*(?=@)"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: emailFormat, options: [], range: NSRange(location: 0, length: email.length))
        guard let range = matches.first?.range else {
            return String(emailFormat.split(separator: "@")[0])
        }
        return email.substring(with: range)
    }
    
    class func getImageByFileType(_ type: String) -> UIImage {
        switch type {
        case "application/pdf":
            return #imageLiteral(resourceName: "attachment_pdf")
        case _ where type.contains("word"):
            return #imageLiteral(resourceName: "attachment_word")
        case "image/png", "image/jpeg":
            return #imageLiteral(resourceName: "attachment_image")
        case _ where type.contains("powerpoint") ||
            type.contains("presentation"):
            return #imageLiteral(resourceName: "attachment_ppt")
        case _ where type.contains("excel") ||
            type.contains("spreadsheet"):
            return #imageLiteral(resourceName: "attachment_excel")
        case _ where type.contains("audio"):
            return #imageLiteral(resourceName: "attachment_audio")
        case _ where type.contains("video"):
            return #imageLiteral(resourceName: "attachment_video")
        case _ where type.contains("zip"):
            return #imageLiteral(resourceName: "attachment_zip")
        default:
            return #imageLiteral(resourceName: "attachment_generic")
        }
    }
    
    class func getExternalImage(_ type: String) -> String {
        switch type {
        case "application/pdf":
            return "filepdf"
        case _ where type.contains("word"):
            return "fileword"
        case "image/png", "image/jpeg":
            return "fileimage"
        case _ where type.contains("powerpoint") ||
            type.contains("presentation"):
            return "fileppt"
        case _ where type.contains("excel") ||
            type.contains("spreadsheet"):
            return "fileexcel"
        case _ where type.contains("audio"):
            return "fileaudio"
        case _ where type.contains("video"):
            return "filevideo"
        case _ where type.contains("zip"):
            return "filezip"
        default:
            return "filedefault"
        }
    }
    
    class func getLocalDate(from date: String) -> Date{
        let dateFormatter = DateFormatter()
        let timeZone = NSTimeZone(abbreviation: "UTC")
        dateFormatter.timeZone = timeZone as TimeZone?
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.date(from: date) ?? Date()
    }
    
    class func verifyUrl(urlString: String) -> Bool {
        let regEx = "^(http://www.|https://www.|http://|https://)?[a-z0-9]+([-.]{1}[a-z0-9]+)*.[a-z]{2,5}(:[0-9]{1,5})?(/.*)?$"
        let predicate = NSPredicate(format:"SELF MATCHES %@", argumentArray:[regEx])
        return predicate.evaluate(with: urlString)
    }
    
    class func validateEmail(_ testStr:String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
    }
}
