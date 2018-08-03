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
    func presentPopover(popover: UIViewController, height: Int, arrowDirections: UIPopoverArrowDirection = []){
        popover.preferredContentSize = CGSize(width: Constants.popoverWidth, height: height)
        popover.popoverPresentationController?.sourceView = self.view
        popover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        popover.popoverPresentationController?.permittedArrowDirections = arrowDirections
        popover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(popover, animated: true)
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
        self.showAlert(title, message: message, style: style, actions: nil)
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
    
    func presentGenericPopover(_ title: String, image: UIImage, sourceView: UIView){
        
        let genericPopover = GenericUIPopover()
        genericPopover.titleCard = title
        genericPopover.imageCard = image
        genericPopover.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 161)
        genericPopover.popoverPresentationController?.sourceView = sourceView
        genericPopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sourceView.frame.size.width, height: sourceView.frame.size.height)
        genericPopover.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        genericPopover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(genericPopover, animated: true, completion: nil)
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

enum Font {
    case regular
    case bold
    case italic
    
    func size(_ size:CGFloat) -> UIFont?{
        switch self {
        case .bold:
            return UIFont(name: "NunitoSans-Bold", size: size)
        case .italic:
            return UIFont(name: "NunitoSans-Italic", size: size)
        default:
            return UIFont(name: "NunitoSans-Regular", size: size)
        }
    }
    
    func attributedString(_ text:String, size:CGFloat) -> NSMutableAttributedString{
        switch self {
        case .bold:
            let font = UIFont(name: "NunitoSans-Bold", size: size)!
            let attrs = [NSAttributedStringKey.font : font]
            return NSMutableAttributedString(string:text, attributes:attrs)
        case .italic:
            let font = UIFont(name: "NunitoSans-Italic", size: size)!
            let attrs = [NSAttributedStringKey.font : font]
            return NSMutableAttributedString(string:text, attributes:attrs)
        default:
            let font = UIFont(name: "NunitoSans-Regular", size: size)!
            let attrs = [NSAttributedStringKey.font : font]
            return NSMutableAttributedString(string:text, attributes:attrs)
        }
    }
}

enum FontSize: CGFloat {
    case feed = 14.0
    case feedDate = 11.0
}

enum Icon {
    case activated
    case enabled
    case disabled
    
    enum arrow {
        case up
        case down
        
        var image: UIImage? {
            switch self {
            case .down:
                return UIImage(named: "arrow-down")
            case .up:
                return UIImage(named: "arrow-up")
            }
        }
    }
    
    enum new_arrow {
        case up
        case down
        
        var image: UIImage? {
            switch self {
            case .down:
                return UIImage(named: "new-arrow-down")
            case .up:
                return UIImage(named: "new-arrow-up")
            }
        }
    }
    
    case camera
    case library
    case icloud
    case lock
    case lock_open
    case not_open
    case not_timer
    case unsend
    case activity
    case btn_unsend
    case btn_unsent
    case my_account
    case send
    case send_secure
    case upgrade
    case system
    case reply
    case forward
    case compose
    
    enum attachment {
        case vertical
        case regular
        case secure
        case image
        case expired
        case generic
        case word
        case ppt
        case pdf
        case excel
        case zip
        case audio
        case video
        
        var image: UIImage? {
            switch self {
            case .vertical:
                return UIImage(named: "attachment")
            case .regular:
                return UIImage(named: "attachment_regular")
            case .secure:
                return UIImage(named: "attachment_inbox")
            case .image:
                return UIImage(named: "attachment_image")
            case .expired:
                return UIImage(named: "attachment_expired")
            case .generic:
                return UIImage(named: "attachment_generic")
            case .word:
                return UIImage(named: "attachment_word")
            case .ppt:
                return UIImage(named: "attachment_ppt")
            case .pdf:
                return UIImage(named: "attachment_pdf")
            case .excel:
                return UIImage(named: "attachment_excel")
            case .zip:
                return UIImage(named: "attachment_zip")
            case .audio:
                return UIImage(named: "attachment_audio")
            case .video:
                return UIImage(named: "attachment_video")
            }
            
        }
    }
    
    var color: UIColor {
        switch self {
        case .activated:
            return UIColor(red:0.00, green:0.56, blue:1.00, alpha:1.0)
        case .disabled:
            return UIColor(red:0.59, green:0.59, blue:0.59, alpha:1.0)
        case .system:
            return UIColor(red:0.00, green:0.48, blue:1.00, alpha:1.0)
        case .enabled:
            fallthrough
        default:
            return UIColor(red:0.50, green:0.50, blue:0.50, alpha:1.0)
        }
    }
    
    var image: UIImage? {
        switch self {
        case .compose:
            return UIImage(named: "composer")
        case .camera:
            return UIImage(named: "attachment_camera")
        case .library:
            return UIImage(named: "attachment_photolibrary")
        case .icloud:
            return UIImage(named: "attachment_docproviders")
        case .lock:
            return UIImage(named: "switch_locked_on")
        case .lock_open:
            return UIImage(named: "switch_locked_off")
        case .not_open:
            return UIImage(named: "not-open")
        case .not_timer:
            return UIImage(named: "not-timer")
        case .unsend:
            return UIImage(named: "unsend")
        case .activity:
            return UIImage(named: "activity")
        case .btn_unsend:
            return UIImage(named: "unsend_btn")
        case .btn_unsent:
            return UIImage(named: "unsent_btn")
        case .my_account:
            return UIImage(named: "my_account")
        case .send:
            return UIImage(named: "send")
        case .send_secure:
            return UIImage(named: "send_secure")
        case .upgrade:
            return UIImage(named: "slider_upgrade")
        case .forward:
            return UIImage(named: "inbox-forward-icon")
        case .reply:
            return UIImage(named: "inbox-reply-icon")
        default:
            return UIImage()
        }
    }
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

enum ContactType : String {
    case from = "from"
    case to = "to"
    case cc = "cc"
    case bcc = "bcc"
}

extension UIColor {
    
    static let mainUI = UIColor(red: 0, green: 145/255, blue: 255/255, alpha: 1)
    static let mainUILight = UIColor(red: 0, green: 145/255, blue: 255/255, alpha: 0.63)
    static let neutral = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1)
    static let alert = UIColor(red: 221/255, green: 64/255, blue: 64/255, alpha: 1)
    static let alertLight = UIColor(red: 227/255, green: 102/255, blue: 102/255, alpha: 1)
    static let alertText = UIColor(red: 238/255, green: 163/255, blue: 163/255, alpha: 1)
    static let itemSelected = UIColor(red: 242/255, green: 248/255, blue: 255/255, alpha: 1)
    static let lightText = UIColor(red: 55/255, green: 58/255, blue: 69/255, alpha: 1)
    static let bright = UIColor(red: 157/255, green: 157/255, blue: 157/255, alpha: 1)
    static let charcoal = UIColor(red: 106/255, green: 112/255, blue: 127/255, alpha: 1)
    static let lightIcon = UIColor(red: 220/255, green: 221/255, blue: 224/255, alpha: 1)
    
    func toHexString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
        return String(format:"%06x", rgb)
    }
}

var DJB_TYPE : UInt8 = 0x05;

extension Data {
    
    func prependByte() -> Data {
        guard self.count == 32 else {
            return self
        }
        let myData = NSMutableData(bytes: &DJB_TYPE, length: 1)
        myData.append(self)
        return myData as Data
    }
    
    func removeByte() -> Data {
        guard self.count == 33 else {
            return self
        }
        return self.suffix(from: 1)
    }
    
    func customBase64String() -> String {
        let dataPlus = self.prependByte()
        let customBase64String = dataPlus.base64EncodedString()
        return customBase64String
    }
    
    func plainBase64String() -> String {
        let customBase64String = self.base64EncodedString()
        return customBase64String
    }
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

enum MessageType: Int {
    case none = 0
    case cipherText = 1
    case preKey = 3
}

