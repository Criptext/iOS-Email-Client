//
//  Extensions.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/28/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import MobileCoreServices
import RichEditorView
import SignalProtocolFramework
import SafariServices

extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        scanner.scanLocation = 0
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        
        let r = (rgbValue & 0xff0000) >> 16
        let g = (rgbValue & 0xff00) >> 8
        let b = rgbValue & 0xff
        
        self.init(
            red: CGFloat(r) / 0xff,
            green: CGFloat(g) / 0xff,
            blue: CGFloat(b) / 0xff, alpha: 1
        )
    }
}

extension CALayer {
    func addGradientBorder(colors:[UIColor],width:CGFloat = 1) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame =  CGRect(origin: CGPoint.zero, size: self.bounds.size)
        gradientLayer.startPoint = CGPoint(x:0.0, y:0.0)
        gradientLayer.endPoint = CGPoint(x:1.0,y:1.0)
        gradientLayer.colors = colors.map({$0.cgColor})

        let shapeLayer = CAShapeLayer()
        shapeLayer.lineWidth = width
        shapeLayer.path = UIBezierPath(rect: self.bounds).cgPath
        shapeLayer.fillColor = nil
        shapeLayer.strokeColor = UIColor.red.cgColor
        gradientLayer.mask = shapeLayer

        self.addSublayer(gradientLayer)
    }
}

extension UIViewController {
    func goToUrl(url: String){
        let svc = SFSafariViewController(url: URL(string: url)!)
        self.present(svc, animated: true, completion: nil)
    }
    
    func getTopView() -> UIViewController {
        if let _ = self.presentedViewController as? BaseUIPopover {
            return self
        }
        if let overViewController = self.presentedViewController {
            return overViewController.getTopView()
        }
        if let overViewController = self.navigationController?.presentedViewController {
            return overViewController.getTopView()
        }
        if let topViewController = self.navigationController?.topViewController,
            topViewController != self {
            return topViewController.getTopView()
        }
        if let navController = self as? UINavigationController,
            let topViewController = navController.topViewController {
            return topViewController.getTopView()
        }
        return self
    }
    
    func logout(account: Account, manually: Bool = false, message: String = String.localize("REMOVED_REMOTELY")){
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.logout(account: account, manually: manually, message: message)
        }
    }
    
    func presentPasswordPopover(myAccount: Account){
        let passwordVC = PasswordUIPopover()
        passwordVC.myAccount = myAccount
        passwordVC.remotelyCheckPassword = true
        passwordVC.onLogoutPress = {
            self.logout(account: myAccount, manually: false)
        }
        self.presentPopover(popover: passwordVC, height: 225)
    }
    
    func presentAccountSuspendedPopover(myAccount: Account, accounts: [Account],
                                        onPressSwitch: ((Account) -> (Void))?,
                                        onPressLogin: (() -> (Void))?){
        let suspendedVC = GenericAlertUIPopover()
        suspendedVC.canDismiss = false
        suspendedVC.myTitle = String.localize("ACCOUNT_SUSPENDED_TITLE")
        suspendedVC.myMessage = String.localize("ACCOUNT_SUSPENDED_MESSAGE", arguments: myAccount.email)
        suspendedVC.myButton = accounts.count > 1 ? String.localize("ACCOUNT_SUSPENDED_BUTTON")
            : String.localize("SIGNIN")
        
        suspendedVC.onOkPress = {
            if(accounts.count > 1){
                let selectedAccountIndex = accounts.firstIndex(of: myAccount)
                if(selectedAccountIndex != nil){
                    if(selectedAccountIndex == accounts.count - 1){
                        onPressSwitch?(accounts[0])
                    } else {
                        onPressSwitch?(accounts[selectedAccountIndex! + 1])
                    }
                } else {
                    onPressLogin?()
                }
            }
        }
        self.presentPopover(popover: suspendedVC, height: 300)
    }
    
    func presentLinkDevicePopover(linkData: LinkData, account: Account){
        let linkDeviceVC = SignInVerificationUIPopover()
        linkDeviceVC.linkData = linkData
        linkDeviceVC.emailText = account.email
        linkDeviceVC.deviceType = Device.Kind(rawValue: linkData.deviceType) ?? .pc
        linkDeviceVC.onResponse = { [weak self] accept in
            guard let delegate = self?.getTopView() as? LinkDeviceDelegate else {
                return
            }
            guard accept else {
                delegate.onCancelLinkDevice(linkData: linkData, account: account)
                return
            }
            delegate.onAcceptLinkDevice(linkData: linkData, account: account)
        }
        guard self.getTopView() is LinkDeviceDelegate else {
            return
        }
        self.presentPopover(popover: linkDeviceVC, height: 215)
    }
}

func MD5(string: String) -> Data {
    let messageData = string.data(using:.utf8)!
    var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
    _ = digestData.withUnsafeMutableBytes {digestBytes in
        messageData.withUnsafeBytes {messageBytes in
            CC_MD5(messageBytes.baseAddress!, CC_LONG(messageData.count), digestBytes.bindMemory(to: UInt8.self).baseAddress)
        }
    }
    return digestData
}

func colorByName(name: String) -> UIColor{
    
    var color = "0091ff"
    let md5Data = MD5(string: name)
    let md5 =  md5Data.map { String(format: "%02hhx", $0) }.joined()
    if(md5.count >= 7){
        let start = md5.index(md5.startIndex, offsetBy: 1)
        let end = md5.index(md5.startIndex, offsetBy: 7)
        let range = start..<end
        color = String(md5[range])
    }
    return UIColor(hex: color)
    
}

func mimeTypeForPath(path: String) -> String {
    let url = NSURL(fileURLWithPath: path)
    
    if let pathExtension = url.pathExtension,
        let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue(),
        let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue(){
        return mimetype as String
    }
    return "application/octet-stream"
}

func systemIdentifier() -> String {
    var systemInfo = utsname()
    uname(&systemInfo)
    let machineMirror = Mirror(reflecting: systemInfo.machine)
    let identifier = machineMirror.children.reduce("") { identifier, element in
        guard let value = element.value as? Int8, value != 0 else { return identifier }
        return identifier + String(UnicodeScalar(UInt8(value)))
    }
    
    return identifier
}

extension UIDevice {
    static let modelName: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        func mapToDevice(identifier: String) -> String {
            #if os(iOS)
            switch identifier {
            case "iPod5,1":                                 return "iPod Touch 5"
            case "iPod7,1":                                 return "iPod Touch 6"
            case "iPhone3,1", "iPhone3,2", "iPhone3,3":     return "iPhone 4"
            case "iPhone4,1":                               return "iPhone 4s"
            case "iPhone5,1", "iPhone5,2":                  return "iPhone 5"
            case "iPhone5,3", "iPhone5,4":                  return "iPhone 5c"
            case "iPhone6,1", "iPhone6,2":                  return "iPhone 5s"
            case "iPhone7,2":                               return "iPhone 6"
            case "iPhone7,1":                               return "iPhone 6 Plus"
            case "iPhone8,1":                               return "iPhone 6s"
            case "iPhone8,2":                               return "iPhone 6s Plus"
            case "iPhone9,1", "iPhone9,3":                  return "iPhone 7"
            case "iPhone9,2", "iPhone9,4":                  return "iPhone 7 Plus"
            case "iPhone8,4":                               return "iPhone SE"
            case "iPhone10,1", "iPhone10,4":                return "iPhone 8"
            case "iPhone10,2", "iPhone10,5":                return "iPhone 8 Plus"
            case "iPhone10,3", "iPhone10,6":                return "iPhone X"
            case "iPhone11,2":                              return "iPhone XS"
            case "iPhone11,4", "iPhone11,6":                return "iPhone XS Max"
            case "iPhone11,8":                              return "iPhone XR"
            case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":return "iPad 2"
            case "iPad3,1", "iPad3,2", "iPad3,3":           return "iPad 3"
            case "iPad3,4", "iPad3,5", "iPad3,6":           return "iPad 4"
            case "iPad4,1", "iPad4,2", "iPad4,3":           return "iPad Air"
            case "iPad5,3", "iPad5,4":                      return "iPad Air 2"
            case "iPad6,11", "iPad6,12":                    return "iPad 5"
            case "iPad7,5", "iPad7,6":                      return "iPad 6"
            case "iPad2,5", "iPad2,6", "iPad2,7":           return "iPad Mini"
            case "iPad4,4", "iPad4,5", "iPad4,6":           return "iPad Mini 2"
            case "iPad4,7", "iPad4,8", "iPad4,9":           return "iPad Mini 3"
            case "iPad5,1", "iPad5,2":                      return "iPad Mini 4"
            case "iPad6,3", "iPad6,4":                      return "iPad Pro (9.7-inch)"
            case "iPad6,7", "iPad6,8":                      return "iPad Pro (12.9-inch)"
            case "iPad7,1", "iPad7,2":                      return "iPad Pro (12.9-inch) (2nd generation)"
            case "iPad7,3", "iPad7,4":                      return "iPad Pro (10.5-inch)"
            case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":return "iPad Pro (11-inch)"
            case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":return "iPad Pro (12.9-inch) (3rd generation)"
            case "AppleTV5,3":                              return "Apple TV"
            case "AppleTV6,2":                              return "Apple TV 4K"
            case "AudioAccessory1,1":                       return "HomePod"
            case "i386", "x86_64":                          return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "iOS"))"
            default:                                        return identifier
            }
            #elseif os(tvOS)
            switch identifier {
            case "AppleTV5,3": return "Apple TV 4"
            case "AppleTV6,2": return "Apple TV 4K"
            case "i386", "x86_64": return "Simulator \(mapToDevice(identifier: ProcessInfo().environment["SIMULATOR_MODEL_IDENTIFIER"] ?? "tvOS"))"
            default: return identifier
            }
            #endif
        }
        
        return mapToDevice(identifier: identifier)
    }()
}

extension UIViewController {
    func showAlert(_ title: String?, message: String?, style: UIAlertController.Style) {
        let popover = GenericAlertUIPopover()
        popover.myTitle = title
        popover.myMessage = message
        self.presentPopover(popover: popover, height: 210)
    }
    
    func showAlert(_ title: String?, message: String?, style: UIAlertController.Style, actions:[UIAlertAction]?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        let okButton = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        if let actions = actions {
            for action in actions {
                alert.addAction(action)
            }
        } else {
            alert.addAction(okButton)
        }
        
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showProAlert(_ title: String?, message: String?){
        var actions = [UIAlertAction]()
        
        let proAction = UIAlertAction(title: "Upgrate to Pro", style: .default, handler: { (action) in
            UIApplication.shared.open(URL(string: "https://criptext.com/mpricing")!)
        })
        let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        actions.append(proAction)
        actions.append(okAction)
        
        self.showAlert(title, message: message, style: .alert, actions: actions)
    }
    
    func showSnackbar(_ title:String, attributedText:NSAttributedString?, buttons:String, permanent:Bool){
        guard let snackbarVC = self.snackbarController as? CriptextSnackbarController else {
            return
        }
        
        if let attributedText = attributedText {
            snackbarVC.customSnackbar.attributedText = attributedText
        } else {
            snackbarVC.customSnackbar.text = title
        }
        
        snackbarVC.customSnackbar.backgroundColor = UIColor(red: 28/255, green: 29/255, blue: 34/255, alpha: 1.0)
        let _ = snackbarVC.animate(snackbar: .visible, delay: 0)
        
        if !permanent {
            let _ = snackbarVC.animate(snackbar: .hidden, delay: 2.5)
        }
    }
    
    func setSnackbar(_ title:String, attributedText:NSAttributedString?){
        guard let snackbarVC = self.snackbarController as? CriptextSnackbarController else {
            return
        }
        
        if let attributedText = attributedText {
            snackbarVC.customSnackbar.attributedText = attributedText
        } else {
            snackbarVC.customSnackbar.text = title
        }
    }
    
    func hideSnackbar(){
        guard let snackbarVC = self.snackbarController else {
            return
        }
        snackbarVC.animate(snackbar: .hidden, delay: 0.5)
    }
}

extension UIAlertController {
    
    func isValidEmail(_ email: String) -> Bool {
        return email.description.count > 0 && NSPredicate(format: "self matches %@", "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,64}").evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        return password.description.count > 4 && password.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
    
    @objc func textDidChangeInLoginAlert() {
        if let password = textFields?[0].text,
            let password2 = textFields?[1].text,
            let action = actions.last {
            action.isEnabled = isValidPassword(password) && isValidPassword(password2) && password == password2
        }
    }
}

extension RichEditorView {
    /// Reads a file from the application's bundle, and returns its contents as a string
    /// Returns nil if there was some error
    func readFile(name: String, type: String) -> String? {
        
        if let filePath = Bundle.main.path(forResource: name, ofType: type) {
            do {
                let file = try NSString(contentsOfFile: filePath, encoding: String.Encoding.utf8.rawValue) as String
                return file
            } catch let error {
                print("Error loading \(name).\(type): \(error)")
            }
        }
        return nil
    }
    
    func cleanStringForJS(_ string: String) -> String {
        let substitutions = [
            "\"": "\\\"",
            "'": "\\'",
            "\n": "\\\n",
            ]
        
        var output = string
        for (key, value) in substitutions {
            output = (output as NSString).replacingOccurrences(of: key, with: value)
        }
        
        return output
    }
    
    /// Creates a JS string that can be run in the WebView to apply the passed in CSS to it
    func addCSSString(style: String) -> String {
        let css = self.cleanStringForJS(style)
        let js = "var css = document.createElement('style'); css.type = 'text/css'; css.innerHTML = '\(css)'; document.body.appendChild(css);"
        return js
    }
    
    func replace(font:String, css:String){
        if var customCSS = self.readFile(name: css, type: "css") {
            /// Replace the font with the actual location of the font inside our bundle
            if let fontLocation = Bundle.main.path(forResource: font, ofType: "ttf") {
                customCSS = customCSS.replacingOccurrences(of: font, with: fontLocation)
            }
            let js = self.addCSSString(style: customCSS)
            self.runJS(js)
        }
    }
}

extension Notification.Name {
    
    public static let onNewEmail = Notification.Name(rawValue: "com.criptext.email.onnewemail")
    public static let onDeleteDraft = Notification.Name(rawValue: "com.criptext.email.ondeletedraft")
    
    public struct Activity {
        public static let onNewMessage = Notification.Name(rawValue: "com.criptext.email.onnewmessage")
        public static let onNewAttachment = Notification.Name(rawValue: "com.criptext.email.onnewattachment")
        public static let onEmailMute = Notification.Name(rawValue: "com.criptext.email.onemailmute")
        public static let onMsgNotificationChange = Notification.Name(rawValue: "com.criptext.email.onmsgnotification")
        public static let onFileNotificationChange = Notification.Name(rawValue: "com.criptext.email.onfilenotification")
    }
}

extension String {
    
    func sha256() -> String? {
        guard let data = self.data(using: String.Encoding.utf8),
            let shaData = AESCipher.sha256(data) else { return nil }
        let rc = shaData.base64EncodedString(options: [])
        return rc
    }
    
    init(htmlEncodedString: String) {
        self.init(htmlEncodedString)
    }
    
    func removeHtmlTags() -> String{
        return self.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression, range: nil)
    }
    
    static func random(length: Int = 20) -> String {
        let base = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        var randomString: String = ""
        
        for _ in 0..<length {
            let randomValue = arc4random_uniform(UInt32(base.count))
            randomString += "\(base[base.index(base.startIndex, offsetBy: Int(randomValue))])"
        }
        return randomString
    }
    
}

enum StaticFile {
    case encryptedDB
    case gzippedDB
    case emailDB
    case unzippedDB
    case decryptedDB
    
    case backupDB
    case backupZip
    case backupRSA
    
    case shareDB
    case shareZip
    case shareRSA
    
    var name: String {
        switch self {
        case .encryptedDB:
            return "secure.db"
        case .gzippedDB:
            return "compressed.db"
        case .emailDB:
            return "emails.db"
        case .unzippedDB:
            return "decompressed.db"
        case .decryptedDB:
            return "decrypted.db"
        case .backupDB:
            return "backup.db"
        case .backupZip:
            return "backup.gz"
        case .backupRSA:
            return "backup.enc"
        case .shareDB:
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE dd MMMM YYYY HH:mm"
            return "backup-\(formatter.string(from: now)).db"
        case .shareZip:
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE dd MMMM YYYY HH:mm"
            return "backup-\(formatter.string(from: now)).gz"
        case .shareRSA:
            let now = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE dd MMMM YYYY HH:mm"
            return "backup-\(formatter.string(from: now)).enc"
        }
    }
    
    var url: URL {
        return CriptextFileManager.getURLForFile(name: self.name)
    }
    
    var path: String {
        return CriptextFileManager.getURLForFile(name: self.name).path
    }
}

enum FontSize: CGFloat {
    case feed = 14.0
    case feedDate = 11.0
}

enum Commands:Int {
    case emailOpened = 1
    case fileOpened = 2
    case fileDownloaded = 3
    case emailUnsend = 4
    case emailMute = 5
    case userStatus = 20
    case emailCreated = 54
    case fileCreated = 55
}

extension UIWindow {
    class func getBottomMargin(window: UIWindow?) -> CGFloat {
        return window?.safeAreaInsets.bottom ?? 0.0
    }
}

extension Formatter {
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

extension NSLayoutConstraint {
    
    public class func useAndActivateConstraints(constraints: [NSLayoutConstraint]) {
        for constraint in constraints {
            if let view = constraint.firstItem as? UIView {
                view.translatesAutoresizingMaskIntoConstraints = false
            }
        }
        activate(constraints)
    }
}
