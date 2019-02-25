//
//  Utils.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit
import UIImageView_Letters
import SDWebImage

class Utils: SharedUtils {
    
    static let ONE_MINUTE: Double = 60
    static let FIVE_MINUTES: Double = 60 * 5
    static let FIFTEEN_MINUTES: Double = 60 * 15
    static let ONE_HOUR: Double = 60 * 60
    static let ONE_DAY: Double = 60 * 60 * 24
    
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
    
    class func deleteSDWebImageCache(){
        SDImageCache.shared().clearMemory()
        SDImageCache.shared().clearDisk()
    }
    
    class func getNumberOfLines(_ text: String, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        let label = createLabelWithDynamicHeight(width, fontSize)
        label.text = text
        label.sizeToFit()
        return label.frame.height/label.font.pointSize
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
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        var newSize: CGSize
        if(widthRatio > heightRatio) {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        }
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    class func setProfilePictureImage(imageView: UIImageView, contact: Contact) {
        let color = UIColor.init().colorByName(name: contact.displayName)
        imageView.setImageWith(contact.displayName, color: color, circular: true, fontName: "NunitoSans-Regular")
        imageView.layer.borderWidth = 0.0
        if contact.email.contains("\(Constants.domain)"){
            let username = ContactUtils.getUsernameFromEmailFormat(contact.email)!
            imageView.sd_setImage(with: URL(string: "\(Env.apiURL)/user/avatar/\(username)"), placeholderImage: imageView.image, options: [SDWebImageOptions.continueInBackground, SDWebImageOptions.lowPriority]) { (image, error, cacheType, url) in
                if error == nil {
                    imageView.contentMode = .scaleAspectFill
                    imageView.layer.masksToBounds = false
                    imageView.layer.cornerRadius = imageView.frame.size.width / 2
                    imageView.clipsToBounds = true
                }
            }
        }
    }
    
    class func setProfilePictureImage(imageView: UIImageView, contact: (String, String)) {
        let color = UIColor.init().colorByName(name: contact.1)
        imageView.setImageWith(contact.1, color: color, circular: true, fontName: "NunitoSans-Regular")
        imageView.layer.borderWidth = 0.0
        if contact.0.contains("\(Constants.domain)"){
            let username = ContactUtils.getUsernameFromEmailFormat(contact.0)!
            imageView.sd_setImage(with: URL(string: "\(Env.apiURL)/user/avatar/\(username)"), placeholderImage: imageView.image, options: [SDWebImageOptions.continueInBackground, SDWebImageOptions.lowPriority]) { (image, error, cacheType, url) in
                if error == nil {
                    imageView.contentMode = .scaleAspectFill
                    imageView.layer.masksToBounds = false
                    imageView.layer.cornerRadius = imageView.frame.size.width / 2
                    imageView.clipsToBounds = true
                }
            }
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
    
    class func maskEmailAddress(email: String) -> String {
        let emailSplit = email.split(separator: "@")
        let maskUsername = String(emailSplit[0]).hideMidChars()
        let domain = String(emailSplit[1])
        
        let domainSplit = domain.split(separator: ".")
        let stringArray = domainSplit.enumerated().map { (index, text) -> String in
            guard text != domainSplit.last else {
                return ".\(text)"
            }
            let beforeLast = domainSplit[domainSplit.count - 2]
            if text == domainSplit.first && text == beforeLast {
                return String(text).hideMidChars()
            }
            if text == domainSplit.first {
                return text.prefix(1) + String(repeating: "*", count: text.count - 1)
            }
            if text == beforeLast  {
                return "*\(String(repeating: "*", count: text.count - 1))\(text.suffix(1))"
            }
            return String(repeating: "*", count: text.count)
        }
        return "\(maskUsername)@\(stringArray.joined(separator: ""))"
    }
}
