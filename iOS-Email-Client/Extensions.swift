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

extension UIViewController {
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
    
    func presentLinkDevicePopover(linkData: LinkData){
        let linkDeviceVC = SignInVerificationUIPopover()
        linkDeviceVC.linkData = linkData
        linkDeviceVC.deviceType = Device.Kind(rawValue: linkData.deviceType) ?? .pc
        linkDeviceVC.onResponse = { [weak self] accept in
            guard let delegate = self?.getTopView() as? LinkDeviceDelegate else {
                return
            }
            guard accept else {
                delegate.onCancelLinkDevice(linkData: linkData)
                return
            }
            delegate.onAcceptLinkDevice(linkData: linkData)
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
            CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
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

extension UIViewController {
    func showAlert(_ title: String?, message: String?, style: UIAlertControllerStyle) {
        let popover = GenericAlertUIPopover()
        popover.myTitle = title
        popover.myMessage = message
        self.presentPopover(popover: popover, height: 200)
    }
    
    func showAlert(_ title: String?, message: String?, style: UIAlertControllerStyle, actions:[UIAlertAction]?) {
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
        snackbarVC.animate(snackbar: .visible, delay: 0)
        
        if !permanent {
            snackbarVC.animate(snackbar: .hidden, delay: 2.5)
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
        return email.characters.count > 0 && NSPredicate(format: "self matches %@", "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,64}").evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        return password.characters.count > 4 && password.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
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

extension UITableView {
    
    func performUpdate(_ update: ()->Void, completion: (()->Void)?) {
        
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        
        // Table View update on row / section
        beginUpdates()
        update()
        endUpdates()
        
        CATransaction.commit()
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
    case shareDB
    case shareZip
    
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
        case .shareDB:
            return "share.db"
        case .backupZip:
            return "backup.gz"
        case .shareZip:
            return "share.gz"
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

extension UITableView {
    func applyChanges(section: Int = 0, deletions: [Int], insertions: [Int], updates: [Int]){
        beginUpdates()
        deleteRows(at: deletions.map({IndexPath(row: $0, section: section)}), with: .automatic)
        insertRows(at: insertions.map({IndexPath(row: $0, section: section)}), with: .automatic)
        reloadRows(at: updates.map({IndexPath(row: $0, section: section)}), with: .automatic)
        endUpdates()
    }
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
