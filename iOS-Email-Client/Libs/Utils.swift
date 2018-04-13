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
        if let data = text.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
    }
}
