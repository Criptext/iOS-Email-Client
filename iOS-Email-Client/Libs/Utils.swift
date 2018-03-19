//
//  Utils.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class Utils{
    class func getLabelHeight(_ text: NSMutableAttributedString, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        
        label.textColor=UIColor.black
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = Font.regular.size(fontSize)
        label.numberOfLines = 0
        
        label.attributedText = text
        label.sizeToFit()
        return label.frame.height
    }
    
    class func getLabelHeight(_ text: String, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        
        label.textColor=UIColor.black
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = Font.regular.size(fontSize)
        label.numberOfLines = 0
        
        label.text = text
        label.sizeToFit()
        return label.frame.height
    }
    
    class func getNumberOfLines(_ text: String, width: CGFloat, fontSize: CGFloat) -> CGFloat {
        let label:UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        
        label.textColor=UIColor.black
        label.lineBreakMode = NSLineBreakMode.byWordWrapping
        label.font = Font.regular.size(fontSize)
        label.numberOfLines = 0
        
        label.text = text
        label.sizeToFit()
        return label.frame.height/label.font.pointSize
    }
}
