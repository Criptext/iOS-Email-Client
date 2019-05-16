//
//  UIUtils.swift
//  iOS-Email-Client
//
//  Created by Allisson on 2/27/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit
import UIImageView_Letters
import SDWebImage

class UIUtils {
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
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk()
    }
    
    class func getNumberOfLines(_ text: String, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        let label = createLabelWithDynamicHeight(width, fontSize)
        label.text = text
        label.sizeToFit()
        return label.frame.height/label.font.pointSize
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
    
    class func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
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
    
    class func createLeftBackButton(target: Any?, action: Selector) -> UIBarButtonItem {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 31, height: 31))
        button.layer.cornerRadius = 15
        button.backgroundColor = UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 0.13)
        button.setImage(#imageLiteral(resourceName: "arrow-back").tint(with: .white), for: .normal)
        button.addTarget(target, action: action, for: .touchUpInside)
        return UIBarButtonItem(customView: button)
    }
}
