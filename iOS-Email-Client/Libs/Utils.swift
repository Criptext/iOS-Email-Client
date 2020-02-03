//
//  Utils.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class Utils: SharedUtils {
    
    static let defaultDomains = [
        /* Criptext Domains*/
        Env.plainDomain: true,
        /* Default domains included */
        "aol.com": false, "att.net": false, "comcast.net": false, "facebook.com": false, "gmail.com": false, "gmx.com": false, "googlemail.com": false,
        "google.com": false, "hotmail.com": false, "hotmail.co.uk": false, "mac.com": false, "me.com": false, "mail.com": false, "msn.com": false,
        "live.com": false, "sbcglobal.net": false, "verizon.net": false, "yahoo.com": false, "yahoo.co.uk": false,
        
        /* Other global domains */
        "email.com": false, "fastmail.fm": false, "games.com": false, "gmx.net": false, "hush.com": false, "hushmail.com": false, "icloud.com": false,
        "iname.com": false, "inbox.com": false, "lavabit.com": false, "love.com": false, "outlook.com": false, "pobox.com": false, "protonmail.ch": false, "protonmail.com": false, "tutanota.de": false, "tutanota.com": false, "tutamail.com": false, "tuta.io": false,
        "keemail.me": false, "rocketmail.com": false, "safe-mail.net": false, "wow.com": false, "ygm.com": false,
        "ymail.com": false, "zoho.com": false, "yandex.com": false,
        
        /* United States ISP domains */
        "bellsouth.net": false, "charter.net": false, "cox.net": false, "earthlink.net": false, "juno.com": false,
        
        /* British ISP domains */
        "btinternet.com": false, "virginmedia.com": false, "blueyonder.co.uk": false, "freeserve.co.uk": false, "live.co.uk": false,
        "ntlworld.com": false, "o2.co.uk": false, "orange.net": false, "sky.com": false, "talktalk.co.uk": false, "tiscali.co.uk": false,
        "virgin.net": false, "wanadoo.co.uk": false, "bt.com": false,
        
        /* Domains used in Asia */
        "sina.com": false, "sina.cn": false, "qq.com": false, "naver.com": false, "hanmail.net": false, "daum.net": false, "nate.com": false, "yahoo.co.jp": false, "yahoo.co.kr": false, "yahoo.co.id": false, "yahoo.co.in": false, "yahoo.com.sg": false, "yahoo.com.ph": false, "163.com": false, "yeah.net": false, "126.com": false, "21cn.com": false, "aliyun.com": false, "foxmail.com": false,
        
        /* French ISP domains */
        "hotmail.fr": false, "live.fr": false, "laposte.net": false, "yahoo.fr": false, "wanadoo.fr": false, "orange.fr": false, "gmx.fr": false, "sfr.fr": false, "neuf.fr": false, "free.fr": false,
        
        /* German ISP domains */
        "gmx.de": false, "hotmail.de": false, "live.de": false, "online.de": false, "t-online.de": false, "web.de": false, "yahoo.de": false,
        
        /* Italian ISP domains */
        "libero.it": false, "virgilio.it": false, "hotmail.it": false, "aol.it": false, "tiscali.it": false, "alice.it": false, "live.it": false, "yahoo.it": false, "email.it": false, "tin.it": false, "poste.it": false, "teletu.it": false,
        
        /* Russian ISP domains */
        "mail.ru": false, "rambler.ru": false, "yandex.ru": false, "ya.ru": false, "list.ru": false,
        
        /* Belgian ISP domains */
        "hotmail.be": false, "live.be": false, "skynet.be": false, "voo.be": false, "tvcablenet.be": false, "telenet.be": false,
        
        /* Argentinian ISP domains */
        "hotmail.com.ar": false, "live.com.ar": false, "yahoo.com.ar": false, "fibertel.com.ar": false, "speedy.com.ar": false, "arnet.com.ar": false,
        
        /* Domains used in Mexico */
        "yahoo.com.mx": false, "live.com.mx": false, "hotmail.es": false, "hotmail.com.mx": false, "prodigy.net.mx": false,
        
        /* Domains used in Brazil */
        "yahoo.com.br": false, "hotmail.com.br": false, "outlook.com.br": false, "uol.com.br": false, "bol.com.br": false, "terra.com.br": false, "ig.com.br": false, "itelefonica.com.br": false, "r7.com": false, "zipmail.com.br": false, "globo.com": false, "globomail.com": false, "oi.com.br": false
    ]

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
        let emailRegEx = "(?=^([a-z0-9]([._-]{0,2}[a-z0-9])+)$)(?:^.{3,64}$)$"
        
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
