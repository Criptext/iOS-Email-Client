//
//  Utils.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class Utils: SharedUtils {

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
    
    class func isValidUsername(_ testStr:String) -> Bool {
        let emailRegEx = "(?=^([a-z0-9]([._-]{0,2}[a-z0-9])+)$)(?:^.{3,16}$)$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: testStr)
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
