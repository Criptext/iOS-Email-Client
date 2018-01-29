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
import GoogleAPIClientForREST

extension GTLRService {
    func isReady() -> Bool{
    
        if let _ = self.authorizer {
            return true
        }
        
        return false
    }
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
        guard let snackbarVC = self.snackbarController else {
            return
        }
        
//        let fullString = NSMutableAttributedString(string: "Start of text")
//        
//        let image1Attachment = NSTextAttachment()
//        image1Attachment.image = #imageLiteral(resourceName: "inbox-forward-icon")
//        
//        let image1String = NSAttributedString(attachment: image1Attachment)
//        
//        fullString.append(image1String)
//        fullString.append(NSAttributedString(string: "End of text meh"))
        
        if let attributedText = attributedText {
            snackbarVC.snackbar.attributedText = attributedText
        } else {
            snackbarVC.snackbar.text = title
        }
        
        snackbarVC.snackbar.backgroundColor = Icon.system.color
        
        snackbarVC.animate(snackbar: .visible, delay: 0)
        
        if !permanent {
            snackbarVC.animate(snackbar: .hidden, delay: 3.5)
        }
    }
    
    func setSnackbar(_ title:String, attributedText:NSAttributedString?){
        guard let snackbarVC = self.snackbarController else {
            return
        }
        
        if let attributedText = attributedText {
            snackbarVC.snackbar.attributedText = attributedText
        } else {
            snackbarVC.snackbar.text = title
        }
    }
    
    func hideSnackbar(){
        guard let snackbarVC = self.snackbarController else {
            return
        }
        snackbarVC.animate(snackbar: .hidden, delay: 1)
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
//        let encodedData = htmlEncodedString.data(using: String.Encoding.utf8)!
//        let attributedOptions = [ NSAttributedString.DocumentAttributeKey.documentType.rawValue: NSAttributedString.DocumentType.html,
//                                  NSAttributedString.DocumentAttributeKey.characterEncoding: NSNumber(value: String.Encoding.utf8.rawValue)] as! [NSAttributedString.DocumentReadingOptionKey : Any]
//
//        guard let attributedString = try? NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil) else {
//            self.init(htmlEncodedString)
//            return
//        }
//
//        self.init(attributedString.string)
        
        self.init(htmlEncodedString)
    }
}

enum Font {
    case regular
    case bold
    
    func size(_ size:CGFloat) -> UIFont?{
        switch self {
        case .bold:
            return UIFont(name: "Lato-Black", size: size)
        default:
            return UIFont(name: "Lato-Regular", size: size)
        }
    }
    
    func attributedString(_ text:String, size:CGFloat) -> NSMutableAttributedString{
        switch self {
        case .bold:
            let font = UIFont(name: "Lato-Semibold", size: size)!
            let attrs = [NSAttributedStringKey.font : font]
            return NSMutableAttributedString(string:text, attributes:attrs)
        default:
            let font = UIFont(name: "Lato-Regular", size: size)!
            let attrs = [NSAttributedStringKey.font : font]
            return NSMutableAttributedString(string:text, attributes:attrs)
        }
    }
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
    
    enum attachment {
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
            case .regular:
                return UIImage(named: "attachment_regular")
            case .secure:
                return UIImage(named: "attachment_secure")
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

enum Label {
    case inbox
    case draft
    case sent
    case junk
    case trash
    case unread
    case all
    
    var id: String {
        switch self {
        case .inbox:
            return "INBOX"
        case .draft:
            return "DRAFT"
        case .sent:
            return "SENT"
        case .junk:
            return "SPAM"
        case .trash:
            return "TRASH"
        case .unread:
            return "UNREAD"
        default:
            return ""
        }
    }
    
    var description: String {
        switch self {
        case .inbox:
            return "Inbox"
        case .draft:
            return "Drafts"
        case .sent:
            return "Sent"
        case .junk:
            return "Junk"
        case .trash:
            return "Trash"
        case .unread:
            return "Unread"
        case .all:
            return "All Mail"
        default:
            return ""
        }
    }
    
    var image: UIImage? {
        switch self {
        case .inbox:
            return UIImage(named: "slider_inbox")
        case .draft:
            return UIImage(named: "slider_draft")
        case .sent:
            return UIImage(named: "slider_sent")
        case .junk:
            return UIImage(named: "slider_junk")
        case .trash:
            return UIImage(named: "slider_trash")
        default:
            return UIImage(named: "slider_allmail")
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

struct Constants {
    static let unsendEmail = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" +
        "<html xmlns=\"http://www.w3.org/1999/xhtml\">" +
        " <head>" +
        "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">" +
        "  <meta name=\"viewport\" content=\"width=device-width,user-scalable=yes\">" +
        " </head>" +
        " <body>" +
        "  <style>  @media only screen and (max-width: 600px) {    td[class=\"pattern\"] td{ width: 100% !important;}td[class=\"hero\"] img { width: 100%; height: auto !important; } td[class=\"hero\"] { width: 100% !important; height: auto !important;}td[class=\"minilogo\"] img{ width: 180px; height: auto !important; text-align: center; }  } iframe#alive + div#rendered {display:none !important;}</style>" +
        "  <div>" +
        "   <table cellpadding=\"0\" cellspacing=\"0\" border=\"0\"> " +
        "    <tbody>" +
        "     <tr> " +
        "      <td class=\"pattern\" width=\"600\">    " +
        "       <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"> <script src=\"https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js\"></script> <style type=\"text/css\">" +
        "    body{" +
        "      font-family: arial,sans-serif;" +
        "    }" +
        "    .myframenew{" +
        "      width: 100% !important;" +
        "      height: auto !important;" +
        "      word-wrap: break-word;" +
        "    }" +
        "    @media screen and (max-width: 750px) {" +
        "      img{" +
        "        max-width: 680px !important;" +
        "      }" +
        "    }" +
        "    @media screen and (max-width: 500px) {" +
        "      img{" +
        "        max-width: 375px !important;" +
        "      }" +
        "    }" +
        "    img{" +
        "      max-width: 800px;" +
        "      height: auto;" +
        "    }" +
        "  </style> <script type=\"text/javascript\">" +
        "    $(document).ready(function(){" +
        "      for(var i=0;i<$(\"img\").length;i++){" +
        "        //$($(\"img\")[i]).attr(\"width\",\"auto\");" +
        "        //$($(\"img\")[i]).attr(\"height\",\"auto\");" +
        "      }" +
        "    });" +
        "  </script>   " +
        "       <div> " +
        "        <a style=\"color: #ccc; font-style: italic;\">The content is no longer available</a> " +
        "       </div>   </td>" +
        "     </tr>" +
        "    </tbody>" +
        "   </table>" +
        "  </div>" +
        "  <div style=\"font-size:0em\">" +
        "   <pre style=\"color:white;display:none;\">5oe7b8oqjjbxogvij55kbi1bgj8xgc6n2dg6i529</pre>" +
        "  </div>" +
        "  <div style=\"font-size:0em\"></div>" +
        "  <div></div>" +
        "  <div></div>" +
        " </body>" +
        "</html><html><head><script>" +
        "var imageElements = function() {" +
        "var imageNodes = document.getElementsByTagName('img');" +
        "return [].slice.call(imageNodes);" +
        "}" +
        "var findCIDImageURL = function() {" +
        "var images = imageElements();" +
        "" +
        "var imgLinks = [];" +
        "for (var i = 0; i < images.length; i++) {" +
        "var url = images[i].getAttribute('src');" +
        "if (url.indexOf('cid:') == 0 || url.indexOf('x-mailcore-image:') == 0)" +
        "imgLinks.push(url);" +
        "}" +
        "return JSON.stringify(imgLinks);" +
        "}" +
        "var replaceImageSrc = function(info) {" +
        "var images = imageElements();" +
        "" +
        "for (var i = 0; i < images.length; i++) {" +
        "var url = images[i].getAttribute('src');" +
        "if (url.indexOf(info.URLKey) == 0) {" +
        "images[i].setAttribute('src', info.LocalPathKey);" +
        "break;" +
        "}" +
        "}" +
        "}" +
        "var preElements = function() {" +
        "var preNodes = document.getElementsByTagName('pre');" +
        "return [].slice.call(preNodes);" +
        "}" +
        "var getCriptextToken = function() {" +
        "var preTags = preElements();" +
        "    " +
        "    var token = preTags[0].innerHTML;" +
        "    return token;" +
        "}" +
        "var urlify = function() {" +
        "    var urlRegex = /(=\")?(http(s)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&\\/\\/=]*)(<\\/a>)?/g;" +
        "    " +
        "    return document.documentElement.outerHTML.replace(urlRegex, function(url) {" +
        "                                                      if(url.indexOf('=\"') > -1 ||" +
        "                                                         url.indexOf('.length') > -1 ||" +
        "                                                         url.indexOf('.push') > -1 ||" +
        "                                                         url.indexOf('.slice.call') > -1){" +
        "                                                        return url" +
        "                                                      }" +
        "                                                      " +
        "                                                      var trueUrl = url" +
        "                                                      if(trueUrl.indexOf('http') == -1){" +
        "                                                        trueUrl = \"https://\"+url" +
        "                                                      }" +
        "                                                      return '<a href=\"' + trueUrl + '\" target=\"_blank\">' + url + '</a>';" +
        "                        });" +
        "}" +
        "                     " +
    "</script><style type='text/css'>body{ font-family: 'Helvetica Neue', Helvetica, Arial; margin:0; padding:30px;} hr {border: 0; height: 1px; background-color: #bdc3c7;}.show { display: block;}.hide:target + .show { display: inline;} .hide:target { display: block;} .content { display:block;} .hide:target ~ .content { display:inline;} </style></head><body></body><iframe src='x-mailcore-msgviewloaded:' style='width: 0px; height: 0px; border: none;'></iframe><script>var replybody = document.getElementsByTagName(\"blockquote\")[0].parentElement;var newNode = document.createElement(\"img\");newNode.src = \"file:///var/containers/Bundle/Application/B6B86B64-73F7-4B6F-9563-571BC2623208/Criptext Secure Email.app/showmore.png\";newNode.width = 30;newNode.style.paddingTop = \"10px\";newNode.style.paddingBottom = \"10px\";replybody.style.display = \"none\";replybody.parentElement.insertBefore(newNode, replybody);newNode.addEventListener(\"click\", function(){ if(replybody.style.display == \"block\"){ replybody.style.display = \"none\";} else {replybody.style.display = \"block\";} window.location.href = \"inapp://heightUpdate\";});</script></html>"
}
