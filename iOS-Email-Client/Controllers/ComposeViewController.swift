//
//  ComposeViewController.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/22/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST
import CLTokenInputView
import Photos
import CICropPicker
import M13Checkbox
import TPCustomSwitch
import MonkeyKit
import ContactsUI
import RichEditorView
import SwiftSoup
import MIBadgeButton_Swift

class ComposeViewController: UIViewController {
    @IBOutlet weak var toField: CLTokenInputView!
    @IBOutlet weak var ccField: CLTokenInputView!
    @IBOutlet weak var bccField: CLTokenInputView!
    @IBOutlet weak var subjectField: UITextField!
    @IBOutlet weak var editorView: RichEditorView!
    
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarButtonsTopConstraint: NSLayoutConstraint! //initial value 7
    @IBOutlet weak var dummySwitch: UISwitch!
    
    @IBOutlet weak var bccHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ccHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var editorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var metadataHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var timerButton: UIButton!
    @IBOutlet weak var timeButton: UIButton!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var blackBackground: UIView!
    @IBOutlet weak var timerContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachmentContainerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var timerPicker: UIPickerView!
    
    @IBOutlet weak var openedCheckbox: M13Checkbox!
    @IBOutlet weak var sentCheckbox: M13Checkbox!
    
    @IBOutlet weak var contactTableView: UITableView!
    @IBOutlet weak var contactTableViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var closeBarButton: UIBarButtonItem!
    
    @IBOutlet weak var attachmentButtonContainerView: UIView!
    
    var currentUser:User!
    var currentService: GTLRService!
    var replyingEmail: Email?
    var replyBody: String?
    
    var expandedBbcSpacing:CGFloat = 45
    var expandedCcSpacing:CGFloat = 45
    var expandedMetadataHeight:CGFloat = 182
    let collapsedMetadataHeight:CGFloat = 90
    
    var toolbarBottomConstraintInitialValue: CGFloat?
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    
    let initialValueTopConstraint:CGFloat = 10
    let offsetValueTopconstraint:CGFloat = 12
    let rowHeight:CGFloat = 65.0
    
    var attachmentArray = [Attachment]() //AttachmentGmail or AttachmentCriptext
    var contactArray = [Contact]()
    
    let imagePicker = CICropPicker()
    
    var selectedExpirationDays = 0
    var selectedExpirationHours = 0
    var selectedExpirationMinutes = 0
    
    //Picker data source
    let days = Array(0...24)
    let hours = Array(0...23)
    let minutes = Array(0...59)
    
    let encryptionSwitch = TPCustomSwitch(frame: .zero)
    
    var thumbUpdated = false
    
    var selectedTokenInputView:CLTokenInputView?
    
    var isEdited = false
    
    //draft
    var isDraft = false
    var emailDraft: Email?
    
    var sendBarButton:UIBarButtonItem!
    var sendSecureBarButton:UIBarButtonItem!
    var attachmentBarButton:MIBadgeButton!
    
    var dismissTapGestureRecognizer: UITapGestureRecognizer!
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sendBarButton = UIBarButtonItem(image: Icon.send.image, style: .plain, target: self, action: #selector(didPressSend(_:)))
        self.sendSecureBarButton = UIBarButtonItem(image: Icon.send_secure.image, style: .plain, target: self, action: #selector(didPressSend(_:)))
        self.sendSecureBarButton.tintColor = Icon.system.color
        
        self.editorView.delegate = self
        self.subjectField.delegate = self
        
        self.toField.fieldName = "To:"
        self.toField.tintColor = Icon.system.color
        self.toField.delegate = self
        let toFieldButton = UIButton(type: .custom)
        toFieldButton.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        toFieldButton.setTitle("+", for: .normal)
        toFieldButton.setTitleColor(Icon.system.color, for: .normal)
        toFieldButton.addTarget(self, action: #selector(didPressAccessoryView(_:)), for: .touchUpInside)
        self.toField.accessoryView = toFieldButton
        self.toField.accessoryView?.isHidden = true
        
        self.bccField.fieldName = "Bcc:"
        self.bccField.tintColor = Icon.system.color
        self.bccField.delegate = self
        let bccFieldButton = UIButton(type: .custom)
        bccFieldButton.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        bccFieldButton.setTitle("+", for: .normal)
        bccFieldButton.setTitleColor(Icon.system.color, for: .normal)
        bccFieldButton.addTarget(self, action: #selector(didPressAccessoryView(_:)), for: .touchUpInside)
        self.bccField.accessoryView = bccFieldButton
        self.bccField.accessoryView?.isHidden = true
        
        self.ccField.fieldName = "Cc:"
        self.ccField.tintColor = Icon.system.color
        self.ccField.delegate = self
        let ccFieldButton = UIButton(type: .custom)
        ccFieldButton.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        ccFieldButton.setTitle("+", for: .normal)
        ccFieldButton.setTitleColor(Icon.system.color, for: .normal)
        ccFieldButton.addTarget(self, action: #selector(didPressAccessoryView(_:)), for: .touchUpInside)
        self.ccField.accessoryView = ccFieldButton
        self.ccField.accessoryView?.isHidden = true
        
        self.contactTableView.isHidden = true
        
        self.timerButton.tintColor = Icon.enabled.color
        
        self.toolbarView.addSubview(self.encryptionSwitch)
        self.encryptionSwitch.center = CGPoint(x: self.dummySwitch.center.x, y: self.dummySwitch.center.y)
        self.encryptionSwitch.addTarget(self, action: #selector(self.didChangeSwitchValue(_:)), for: UIControlEvents.valueChanged)
        self.encryptionSwitch.activeColor = UIColor(red:0.00, green:0.43, blue:0.97, alpha:1.0)
        self.encryptionSwitch.onTintColor = UIColor(red:0.00, green:0.43, blue:0.97, alpha:1.0)
        
        self.toolbarView.bringSubview(toFront: self.encryptionSwitch)
        
        self.editorView.isScrollEnabled = false
        self.editorView.html = "<br><br>" + self.currentUser.emailSignature
        print(self.editorView.lineHeight)
        self.editorHeightConstraint.constant = 370
        
        self.openedCheckbox.setCheckState(.checked, animated: true)
        
        self.toolbarBottomConstraintInitialValue = toolbarBottomConstraint.constant
        
        self.timeButton.setTitle("Encrypt this email", for: .normal)
        self.timeButton.setTitleColor(Icon.enabled.color, for: .normal)
        
        //3
        self.enableKeyboardHideOnTap()
        
        self.imagePicker.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(showTimer(_:)))
        self.blackBackground.addGestureRecognizer(tap)
        //table
        
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView()
        self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        //load attachments from Criptext
        if let emailDraft = self.emailDraft {
            self.loadAttachments(from: emailDraft.body)
        }
        
        let activityButton = MIBadgeButton(type: .custom)
        activityButton.badgeString = ""
        activityButton.frame = CGRect(x:0, y:0, width:19, height:24)
        activityButton.badgeEdgeInsets = UIEdgeInsetsMake(5, 12, 0, 13)
        activityButton.addTarget(self, action: #selector(didPressAttachment(_:)), for: UIControlEvents.touchUpInside)
        activityButton.tintColor = Icon.enabled.color
//        activityButton.badgeBackgroundColor = UIColor.red
//        activityButton.badgeTextColor = UIColor.white
        
        activityButton.tintColor = self.attachmentArray.isEmpty ? Icon.enabled.color : Icon.system.color
        self.attachmentBarButton = activityButton
        self.attachmentButtonContainerView.addSubview(self.attachmentBarButton)
//        activityButton.badgeBackgroundColor
        if self.currentUser.defaultOn {
            self.encryptionSwitch.thumbImage = Icon.lock.image
            self.encryptionSwitch.setOn(self.currentUser.defaultOn, animated: true)
            self.title = "New Secure Email"
            self.navigationItem.rightBarButtonItem = self.sendSecureBarButton
            activityButton.setImage(Icon.attachment.secure.image, for: .normal)
            activityButton.badgeEdgeInsets = UIEdgeInsetsMake(5, 12, 0, 13)
        } else {
            self.encryptionSwitch.thumbImage = Icon.lock_open.image
            self.title = "New Email"
            self.navigationItem.rightBarButtonItem = self.sendBarButton
            activityButton.setImage(Icon.attachment.regular.image, for: .normal)
            activityButton.badgeEdgeInsets = UIEdgeInsetsMake(5, 12, 0, 10)
        }
        
        var badgeString = ""
        
        if self.attachmentArray.count > 0 {
            badgeString = "\(self.attachmentArray.count)"
        }
        
        self.attachmentBarButton.badgeString = badgeString
        
        //Download gmail attachments if necessary
        self.download(self.attachmentArray.filter({$0.isEncrypted == false}) as! [AttachmentGmail], mail: self.emailDraft)
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        
        if !self.thumbUpdated {
            self.thumbUpdated = true
            self.encryptionSwitch.thumbImage = Icon.lock.image
            self.encryptionSwitch.setOn(self.currentUser.defaultOn, animated: true)
        }
        
        if self.toField.allTokens.isEmpty {
            self.sendSecureBarButton.isEnabled = false
            self.sendBarButton.isEnabled = false
        }
    }
    
    //MARK: - functions
    
    func add(_ attachment:Attachment){
        self.attachmentBarButton.tintColor = Icon.system.color
        self.attachmentArray.insert(attachment, at: 0)
        
        var height = 303
        
        if self.attachmentArray.count < 3 {
            height = 108 + (self.attachmentArray.count * 65)
        }
        
        if self.attachmentArray.isEmpty {
            height = 110
        }
        
        self.attachmentContainerHeightConstraint.constant = CGFloat(height)
        UIView.animate(withDuration: 0.5) { 
            self.view.layoutIfNeeded()
        }
        
        self.tableView.performUpdate({
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        }, completion: nil)
        
        var badgeString = ""
        let badge = (Int(self.attachmentBarButton.badgeString ?? "0") ?? 0 ) + 1
        
        if badge > 0 {
            badgeString = "\(badge)"
        }
        
        self.attachmentBarButton.badgeString = badgeString
    }
    
    func remove(_ attachment:Attachment){
        
        guard let index = self.attachmentArray.index(where: { (attach) -> Bool in
            return attach == attachment
        }) else {
            //if not found, do nothing
            return
        }
        
        self.removeAttachment(at: IndexPath(row: index, section: 0))
    }
    
    func removeAttachment(at indexPath:IndexPath){
        let attachment = self.attachmentArray.remove(at: indexPath.row)
        
        var badgeString = ""
        let badge = (Int(self.attachmentBarButton.badgeString ?? "1") ?? 1 ) - 1
        
        if badge > 0 {
            badgeString = "\(badge)"
        }
        
        self.attachmentBarButton.badgeString = badgeString
        
        var height = 303
        
        if self.attachmentArray.count < 3 {
            height = 108 + (self.attachmentArray.count * 65)
        }
        
        if self.attachmentArray.isEmpty {
            self.attachmentBarButton.tintColor = Icon.enabled.color
            height = 110
        }
        
        self.attachmentContainerHeightConstraint.constant = CGFloat(height)
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    
        do{
            try FileManager.default.removeItem(at: attachment.fileURL!)
        }catch{
            print("file already updated")
        }
        
        //cancelling request just in case
        APIManager.cancelUpload(attachment.fileName)
        
        self.tableView.performUpdate({
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
        }, completion: nil)
        
    }
    
    func saveDraft() {
        
        guard let service = self.currentService else {
            //TODO: alert user
            self.showAlert("Service unavailable", message: "Please try saving the draft later", style: .alert)
            return
        }
        self.resignKeyboard()
        
        var recipients = self.toField.allTokens.map({return ($0.displayText, String($0.context as! NSString)) })
        recipients.append(contentsOf: self.bccField.allTokens.map({return ($0.displayText, String($0.context as! NSString))}))
        recipients.append(contentsOf: self.ccField.allTokens.map({return ($0.displayText, String($0.context as! NSString))}))
        let bcc = self.bccField.allTokens.map({return ($0.displayText, String($0.context as! NSString))})
        let cc = self.ccField.allTokens.map({return ($0.displayText, String($0.context as! NSString))})
        
        var subject = self.subjectField.text ?? ""
        
        if subject.isEmpty {
            subject = "No Subject"
        }
        
        let body = self.addAttachments(to: self.editorView.html)
        
        self.showSnackbar("Saving Draft...", attributedText: nil, buttons: "", permanent: true)
        //update draft
        if self.isDraft, let emailDraft = self.emailDraft {
            APIManager.updateDraft(message: emailDraft.messageId,
                                   threadId: emailDraft.threadId,
                                   to: recipients,
                                   cc: cc,
                                   bcc: bcc,
                                   subject: subject,
                                   body: body,
                                   attachments: Array(emailDraft.attachments),
                                   from: self.currentUser,
                                   service: service,
                                   completion: { (error, result) in
                self.hideSnackbar()
                if error == nil {
                    self.dismiss(animated: true){
                        (UIApplication.shared.delegate as! AppDelegate).triggerRefresh()
                    }
                }else {
                    print(error!)
                    self.showAlert("Network Error", message: "Please retry saving the email draft later", style: .alert)
                    return
                }
            })
            return
        }
        
        let plainAttachments = self.attachmentArray.filter({$0.isEncrypted == false}) as! [AttachmentGmail]
        //create draft
        APIManager.draftMail(to: recipients,
                             cc: cc,
                             bcc: bcc,
                             subject: subject,
                             body: body,
                             threadId: replyingEmail?.threadId,
                             attachments: plainAttachments,
                             from: self.currentUser,
                             service:service) { (error, result) in
            CriptextSpinner.hide(from: self.view)
            self.hideSnackbar()
            if error == nil {
                self.dismiss(animated: true){
                    (UIApplication.shared.delegate as! AppDelegate).triggerRefresh()
                }
            }else {
                print(error!)
                self.showAlert("Network Error", message: "Please retry saving the email draft later", style: .alert)
                return
            }
        }
    }
    
    @objc func showTimer(_ flag:Bool = false){
        if !flag {
            self.showAttachmentDrawer(false)
        }
        
        self.resignKeyboard()
        
        self.navigationController?.navigationBar.layer.zPosition = flag ? -1 : 0
        self.timerContainerHeightConstraint.constant = flag ? 290 : 0
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.blackBackground.alpha = flag ? 0.5 : 0
        }
    }
    
    func showAttachmentDrawer(_ flag:Bool = false){
        
        self.resignKeyboard()
        
        self.navigationController?.navigationBar.layer.zPosition = flag ? -1 : 0
        
        var height = 303
        if self.attachmentArray.count < 3 {
            height = 108 + (self.attachmentArray.count * 65)
        }
        
        if self.attachmentArray.isEmpty {
            height = 110
        }
        
        self.attachmentContainerHeightConstraint.constant = CGFloat(flag ? height : 0)
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.blackBackground.alpha = flag ? 0.5 : 0
        }
    }
    
    func resignKeyboard() {
        self.toField.endEditing()
        self.ccField.endEditing()
        self.bccField.endEditing()
        self.subjectField.resignFirstResponder()
        self.editorView.webView.endEditing(true)
    }
    
    func collapseCC(_ flag:Bool){
        //do not collapse if already collapsed
        if flag && self.bccHeightConstraint.constant == 0 {
            return
        }
        //do not expand if already expanded
        if !flag && self.bccHeightConstraint.constant > 0 {
            return
        }
        
        self.bccHeightConstraint.constant = flag ? 0 : self.expandedBbcSpacing
        self.ccHeightConstraint.constant = flag ? 0 : self.expandedCcSpacing
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func loadAttachments(from body:String) {
        var doc:Document!
        do {
            doc = try SwiftSoup.parse(body)
            
            let preTags = try doc.getElementsByAttributeValueContaining("class", "criptext_attachment")
            
            for attachmentTag in preTags {
                
                let content = try attachmentTag.html()
                
                let components = content.components(separatedBy: ":")
                
                let token = components[0].replacingOccurrences(of: "<wbr>", with: "")
                let name = components[1].replacingOccurrences(of: "<wbr>", with: "")
                let size = components[2].replacingOccurrences(of: "<wbr>", with: "")
                var password = ""
                if components.count > 3 {
                    password = components[3].replacingOccurrences(of: "<wbr>", with: "")
                }
                
                var readonly = "0"
                if components.count > 4 {
                    readonly = components[4].replacingOccurrences(of: "<wbr>", with: "")
                }
                
                let attach = AttachmentCriptext()
                attach.fileToken = token
                attach.fileName = name
                attach.size = Int(size)!
                attach.currentPassword = password
                attach.isReadOnly = readonly == "1"
                
                
                attach.mimeType = mimeTypeForPath(path: attach.fileName)
                attach.isUploaded = true
                self.attachmentArray.append(attach)
                
                try attachmentTag.html("")
                try attachmentTag.removeAttr("class")
                
                
            }
        } catch {
            print("error loading attachments from draft")
        }
    }
    
    func addAttachments(to body:String) -> String{
        guard !self.attachmentArray.isEmpty else {
            return body
        }
        
        var doc:Document!
        do {
            doc = try SwiftSoup.parse(body)
            let elements = try doc.getElementsByClass("criptext_attachment")
            try elements.remove()
            
            for attachment in self.attachmentArray {
                if !attachment.isEncrypted {
                    continue
                }
                
                var preTag:Element!
                
                if let body = doc.body() {
                    preTag = try body.appendElement("pre")
                } else {
                    preTag = try doc.appendElement("pre")
                }
                
                try preTag.addClass("criptext_attachment")
                let readOnly = attachment.isReadOnly ? "1" : "0"
                try preTag.html("\(attachment.fileToken):\(attachment.fileName):\(attachment.size):\(attachment.currentPassword):\(readOnly)")
                try preTag.attr("style", "color:white;display:none")
            }
            
            return try doc.html()
        } catch {
            return body
        }
    }
    
    func isAttachmentPending () -> Bool {
        return (self.attachmentArray.contains { (attachment) -> Bool in
            if attachment.isUploaded {
                //ignore those already uploaded
                return false
            }
            return true
        })
    }
    
    func download (_ attachments:[AttachmentGmail], mail:Email?) {
        guard let emailDraft = mail, !attachments.isEmpty else {
            return
        }
        for attachment in attachments {
            if FileManager.default.fileExists(atPath: (attachment.fileURL?.path)!) {
                DBManager.update(attachment, isUploaded: true)
                continue
            }
            APIManager.download(attachment: attachment.attachmentId, for: emailDraft.id, with: self.currentService, user: "me", completionHandler: { (error, data) in
                guard let attachmentData = data else {
                    //show error
                    self.showAlert("Network Error", message: "Please retry opening the draft later", style: .alert)
                    return
                }
                
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
//                attachment.attachmentId.substring(to: attachment.attachmentId.startIndex.advancedBy(10))
                let substring = attachment.attachmentId.substring(to: attachment.attachmentId.index(attachment.attachmentId.startIndex, offsetBy: 10))
                let filePath = documentsPath + "/" + substring + attachment.fileName
                let fileURL = URL(fileURLWithPath: filePath)
                
                do {
                    try attachmentData.write(to: fileURL)
                } catch {
                    //show error
                    self.showAlert("Network Error", message: "Please retry opening the attachment later", style: .alert)
                    return
                }
                
                DBManager.update(attachment, isUploaded: true)
                
            })
        }
    }
    
    func toggleInteraction(_ flag:Bool){
        self.sendBarButton.isEnabled = flag
        self.sendSecureBarButton.isEnabled = flag
        self.closeBarButton.isEnabled = flag
        self.view.isUserInteractionEnabled = flag
        self.navigationController?.navigationBar.layer.zPosition = flag ? 0 : -1
        self.blackBackground.isUserInteractionEnabled = flag
        self.blackBackground.alpha = flag ? 0 : 0.5
    }
    
    //MARK: - IBActions
    @IBAction func didPressCancel(_ sender: UIBarButtonItem) {
        
        if !self.isEdited {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        let discardTitle = self.isDraft ? "Delete Changes" : "Discard"
        
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: discardTitle, style: .destructive) { action in
            APIManager.cancelAllUploads()
            self.dismiss(animated: true, completion: nil)
        })
        sheet.addAction(UIAlertAction(title: "Save Draft", style: .default) { action in
            APIManager.cancelAllUploads()
            self.saveDraft()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(sheet, animated: true, completion:nil)
    }
    
    @IBAction func didPressSend(_ sender: UIBarButtonItem) {
        self.resignKeyboard()
        
        //validate if there are no more attachments pending
        guard !self.isAttachmentPending() else {
            self.showAlert(nil, message: "Please wait for your attachments to finish processing", style: .alert)
            return
        }
        
        //validate
        guard let subject = self.subjectField.text, !subject.isEmpty else {
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let sendAction = UIAlertAction(title: "Send", style: .default, handler: { (_) in
                self.sendMail()
            })
            self.showAlert("Empty Subject", message: "This email has no subject. Do you want to send it anyway?", style: .alert, actions: [cancelAction, sendAction])
            return
        }
        
        self.sendMail()
    }
    
    func sendMail(){
        let subject = self.subjectField.text ?? "No Subject"
        
        let recipients = self.toField.allTokens.map { (token) -> String in
            var finalString = token.displayText
            
            if let context = token.context as? NSString {
                finalString = finalString + " <\(String(context))>"
            } else {
                finalString = finalString + " <\(token.displayText)>"
            }
            
            return finalString
        }
        
        let bcc = self.bccField.allTokens.map { (token) -> String in
            var finalString = token.displayText
            
            if let context = token.context as? NSString {
                finalString = finalString + " <\(String(context))>"
            } else {
                finalString = finalString + " <\(token.displayText)>"
            }
            
            return finalString
        }
        
        let cc = self.ccField.allTokens.map { (token) -> String in
            var finalString = token.displayText
            
            if let context = token.context as? NSString {
                finalString = finalString + " <\(String(context))>"
            } else {
                finalString = finalString + " <\(token.displayText)>"
            }
            
            return finalString
        }
        
        var body = self.editorView.html
        
        self.toggleInteraction(false)
        
        //remove reply
        if self.encryptionSwitch.isOn(), let range = body.range(of: "<pre class=\"criptext-remove-this\"></pre>") {
            body = String(body[body.startIndex..<range.lowerBound])
        }
        
        let daySeconds = self.selectedExpirationDays * 86400
        let hourSeconds = self.selectedExpirationHours * 3600
        let minuteSeconds = self.selectedExpirationMinutes * 60
        let totalSeconds = daySeconds + hourSeconds + minuteSeconds
        
        var expirationType = ExpirationType.regular
        
        if recipients.isEmpty {
            return
        }
        
        if totalSeconds > 0 {
            if self.sentCheckbox.checkState == .checked {
                expirationType = .send
            }else if self.openedCheckbox.checkState == .checked {
                expirationType = .open
            }
        }
        
        if self.encryptionSwitch.isOn() {
            let fullString = NSMutableAttributedString(string: "")
            
            let image1Attachment = NSTextAttachment()
            image1Attachment.image = #imageLiteral(resourceName: "lock")
            
            let image1String = NSAttributedString(attachment: image1Attachment)
            
            fullString.append(image1String)
            fullString.append(NSAttributedString(string: " Sending secure email..."))
            self.showSnackbar("", attributedText: fullString, buttons: "", permanent: true)
        }else{
            self.showSnackbar("Sending mail...", attributedText: nil, buttons: "", permanent: true)
        }
        
        
        
        guard let emailDraft = self.emailDraft else {
            APIManager.sendMail(to: recipients,
                                cc: cc,
                                bcc: bcc,
                                subject: subject,
                                body: body,
                                replyBody: self.encryptionSwitch.isOn() ? self.replyBody : nil,
                                messageId: self.replyingEmail?.messageId,
                                threadId: self.replyingEmail?.threadId,
                                draftId: nil,
                                encrypted: self.encryptionSwitch.isOn(),
                                from: self.currentUser,
                                with: self.attachmentArray,
                                expiration: (totalSeconds, expirationType)) { (error, result) in
                                    CriptextSpinner.hide(from: self.view)
                                    self.toggleInteraction(true)
                                    
                                    if let error = error {
                                        self.showAlert("Network Error", message: error, style: .alert)
                                        self.hideSnackbar()
                                        return
                                    }
                                    
                                    guard let _ = result else {
                                        self.showAlert("Network Error", message: "Please retry sending the email later", style: .alert)
                                        self.hideSnackbar()
                                        return
                                    }
                                    
                                    self.dismiss(animated: true, completion: nil)
            }
            
            return
        }
        
        APIManager.getDraftId(message: emailDraft.messageId, service: self.currentService) { (error, draftId) in
            guard let draftId = draftId else {
                //no draft in relation to this message id
                self.toggleInteraction(true)
                self.showAlert("Network Error", message: "Please retry sending the draft later", style: .alert)
                return
            }
            
            APIManager.sendMail(to: recipients,
                                cc: cc,
                                bcc: bcc,
                                subject: subject,
                                body: body,
                                replyBody: self.encryptionSwitch.isOn() ? self.replyBody : nil,
                                messageId: self.replyingEmail?.messageId,
                                threadId: self.replyingEmail?.threadId,
                                draftId: draftId,
                                encrypted: self.encryptionSwitch.isOn(),
                                from: self.currentUser,
                                with: self.attachmentArray,
                                expiration: (totalSeconds, expirationType)) { (error, result) in
                                    CriptextSpinner.hide(from: self.view)
                                    self.toggleInteraction(true)
                                    
                                    if let error = error {
                                        self.showAlert("Network Error", message: error, style: .alert)
                                        self.hideSnackbar()
                                        return
                                    }
                                    
                                    guard let _ = result else {
                                        self.showAlert("Network Error", message: "Please retry sending the email later", style: .alert)
                                        return
                                    }
                                    
                                    self.dismiss(animated: true){
                                        (UIApplication.shared.delegate as! AppDelegate).triggerRefresh()
                                    }
                                    
            }
            
        }
    }
    
    @IBAction func didPressCC(_ sender: UIButton) {
        let needsCollapsing = self.bccHeightConstraint.constant != 0
        self.collapseCC(needsCollapsing)
    }
    
    @IBAction func didPressSetTimer(_ sender: UIButton) {
        self.showTimer(false)
        
        let days = self.timerPicker.selectedRow(inComponent: 0)
        let hours = self.timerPicker.selectedRow(inComponent: 1)
        let minutes = self.timerPicker.selectedRow(inComponent: 2)
        
        
//        var finalString = ""
//        
//        if days > 0 {
//            finalString = finalString + "\(days) Days "
//        }
//        
//        if hours > 0 {
//            finalString = finalString + "\(hours) Hrs "
//        }
//        
//        if minutes > 0 {
//            finalString = finalString + "\(minutes) Mins"
//        }
        
        self.selectedExpirationDays = days
        self.selectedExpirationHours = hours
        self.selectedExpirationMinutes = minutes
        
        self.timerButton.tintColor = Icon.activated.color
    }
    
    @IBAction func didPressShowTimer(_ sender: UIButton) {
        guard self.currentUser.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to set timer")
            return
        }
        
        self.showTimer(true)
    }
    
    @IBAction func didPressCancelTimer(_ sender: UIButton) {
        self.showTimer(false)
        
        self.selectedExpirationDays = 0
        self.selectedExpirationHours = 0
        self.selectedExpirationMinutes = 0
        
        self.timerPicker.selectRow(0, inComponent: 0, animated: true)
        self.timerPicker.selectRow(0, inComponent: 1, animated: true)
        self.timerPicker.selectRow(0, inComponent: 2, animated: true)
        
        self.timerButton.tintColor = Icon.enabled.color
    }
    
    @IBAction func didPressSubject(_ sender: UIButton) {
        self.subjectField.becomeFirstResponder()
    }
    
    @IBAction func checkboxValueChanged(_ sender: M13Checkbox) {
        if sender == self.openedCheckbox  && self.openedCheckbox.checkState == .checked{
            self.sentCheckbox.setCheckState(.unchecked, animated: true)
        }
        
        if sender == self.sentCheckbox  && self.sentCheckbox.checkState == .checked{
            self.openedCheckbox.setCheckState(.unchecked, animated: true)
        }
    }
    
    @IBAction func didPressAttachment(_ sender: UIButton) {
        //derpo
        self.showAttachmentDrawer(true)
    }
    
    @IBAction func didChangeSwitchValue(_ sender: UISwitch) {
        if let senderSwitch = sender as? TPCustomSwitch, senderSwitch.isOn() {
            self.encryptionSwitch.setThumb(Icon.activated.color)
            self.encryptionSwitch.thumbImage = Icon.lock.image
            //change icon for attachment w/ padlock
            self.attachmentButton.setImage(Icon.attachment.secure.image, for: .normal)
            self.attachmentBarButton.setImage(Icon.attachment.secure.image, for: .normal)
            self.attachmentBarButton.badgeEdgeInsets = UIEdgeInsetsMake(5, 12, 0, 13)
            self.timerButton.isHidden = false
            
            self.attachmentBarButton.tintColor = self.attachmentArray.filter({$0.isEncrypted == true}).isEmpty ? Icon.enabled.color : Icon.system.color
            
            self.title = "New Secure Email"
            self.navigationItem.rightBarButtonItem = self.sendSecureBarButton
        }else{
            self.encryptionSwitch.setThumb(Icon.disabled.color)
            self.encryptionSwitch.thumbImage = Icon.lock_open.image
            //change icon for attachment w/o padlock
            self.attachmentBarButton.setImage(Icon.attachment.regular.image, for: .normal)
            self.attachmentBarButton.badgeEdgeInsets = UIEdgeInsetsMake(5, 12, 0, 10)
            self.timerButton.isHidden = true
            
            self.attachmentBarButton.tintColor = self.attachmentArray.filter({$0.isEncrypted == false}).isEmpty ? Icon.enabled.color : Icon.system.color
            
            self.title = "New Email"
            self.navigationItem.rightBarButtonItem = self.sendBarButton
        }
        
        self.tableView.reloadData()
        
        let containsEncrypted = self.attachmentArray.contains(where: { return $0.isEncrypted })
        
        if self.encryptionSwitch.isOn() && !containsEncrypted && !self.attachmentArray.isEmpty {
            self.showAlert("Warning", message: "1 or more attachments are not encrypted. Eliminate them and attach them securely using the button", style: .alert)
        }
        
        if !self.encryptionSwitch.isOn() &&
            containsEncrypted &&
            UserDefaults.standard.bool(forKey: "showEncryptionAlert") {
            print("------------------------------------")
            let alert = UIAlertController(title: "You just turned off Criptext Encryption for this email.", message: "\nRemember:\n\n-Your email won't be encrypted.\n-Your secure attachments won't be sent.\n-Email content can be read by filters, firewalls and servers.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
            
            alert.addAction(UIAlertAction(title: "Don't show again", style: .destructive) { action in
                UserDefaults.standard.set(false, forKey: "showEncryptionAlert")
            })
            
            self.present(alert, animated: true, completion:nil)
        }
    }
    
    @IBAction func didPressAttachmentLibrary(_ sender: UIButton) {
        PHPhotoLibrary.requestAuthorization({ (status) in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    self.imagePicker.presentGalleryPicker(from: self)
                    break
                default:
                    self.showAlert("Access denied", message: "You need to enable access for this app in your settings", style: .alert)
                    break
                }
            }
        })
    }
    
    @IBAction func didPressAttachmentCamera(_ sender: UIButton) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
            DispatchQueue.main.async {
                if !granted {
                    self.showAlert("Access denied", message: "You need to enable access for this app in your settings", style: .alert)
                    return
                }
                self.imagePicker.presentCameraPicker(from: self)
            }
        })
    }
    
    @IBAction func didPressAttachmentDocuments(_ sender: UIButton) {
        let providerList = UIDocumentMenuViewController(documentTypes: ["public.content", "public.data"], in: .import)
        providerList.delegate = self;
        
        providerList.popoverPresentationController?.sourceView = self.view
        providerList.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        self.present(providerList, animated: true, completion: nil)
    }
    
    @objc func didPressAccessoryView(_ sender: UIButton) {
        let tokenInputView = sender.superview as! CLTokenInputView
        
        tokenInputView.beginEditing()
    }
    
}
//MARK: - Image Picker
extension ComposeViewController: CICropPickerDelegate {
    func imagePicker(_ imagePicker: UIImagePickerController!, pickedImage image: UIImage!) {
        
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy_MM_dd"
        
        
        let tmpPath = NSTemporaryDirectory() + NSUUID().uuidString + ".png"
        
        guard let data = UIImageJPEGRepresentation(image, 0.6) else {
            return
        }
        
        if self.encryptionSwitch.isOn() && !self.currentUser.isPro() && data.count > 5000000 {
            //deny basic user attaching file over 5 Mbs
            var actions = [UIAlertAction]()
            
            let proAction = UIAlertAction(title: "Upgrate to Pro", style: .default, handler: { (action) in
                UIApplication.shared.open(URL(string: "https://criptext.com/mpricing")!)
            })
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            
            actions.append(proAction)
            actions.append(okAction)
            
            self.showAlert(nil, message: "File size of 5 Mb limit exceeded. Upgrade to Pro to increase allowed file size to 100 Mb", style: .alert, actions: actions)
            return
        }
        
        if self.encryptionSwitch.isOn() && self.currentUser.isPro() && data.count > 100000000 {
            //deny pro user attaching file over 100 Mbs
            self.showAlert(nil, message: "File size of 100 Mb limit exceeded.", style: .alert)
            return
        }
        
        try! data.write(to: URL(fileURLWithPath: tmpPath))
        
        imagePicker.dismiss(animated: true){
            var attachment:Attachment!
            if self.encryptionSwitch.isOn() {
                attachment = AttachmentCriptext()
            } else {
                attachment = AttachmentGmail()
            }
            
            attachment.fileName = "Criptext_Image_\(formatter.string(from: currentDate)).png"
            attachment.mimeType = mimeTypeForPath(path: attachment.fileName)
            attachment.filePath = tmpPath
            attachment.size = data.count
            attachment.isEncrypted = self.encryptionSwitch.isOn()
            
            self.isEdited = true
            
            self.add(attachment)
            if !attachment.isEncrypted {
                attachment.isUploaded = true
                return
            }
            
            APIManager.upload(data, id:attachment.fileName, fileName:attachment.fileName, mimeType:attachment.mimeType, from:self.currentUser, delegate: self) { (error, fileToken) in
                
                if let error = error as NSError?,
                    let errorObject = error.userInfo["error"] as? [String:String] {
                    
                    var actions = [UIAlertAction]()
                    
                    if !self.currentUser.isPro() && error.code == APIManager.CODE_FILE_SIZE_EXCEEDED {
                        let proAction = UIAlertAction(title: "Upgrate to Pro", style: .default, handler: { (action) in
                            UIApplication.shared.open(URL(string: "https://criptext.com/mpricing")!)
                        })
                        actions.append(proAction)
                    }
                    
                    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    actions.append(okAction)
                    
                    self.showAlert(errorObject["title"], message: errorObject["description"], style: .alert, actions: actions)
                    //delete attachment
                    self.remove(attachment)
                    return
                }
                
                guard let fileToken = fileToken else {
                    attachment.isUploaded = false
                    print(error!)
                    //show error in UI
                    return
                }
                
                attachment.isUploaded = true
                attachment.fileToken = fileToken
                //store attachment in DB
                
                //clean up local file not needed anymore
                try? FileManager.default.removeItem(atPath:attachment.filePath)
                
                //update cell to hide progress bar
                guard let index = self.attachmentArray.index(where: { (attach) -> Bool in
                    return attach == attachment
                }) else {
                    //if not found, do nothing
                    return
                }
                
                let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! AttachmentTableViewCell
                
                cell.progressView.progress = 1
                cell.progressView.isHidden = true
            }
        }
    }
}

//MARK: - Document Handler Delegate
extension ComposeViewController:UIDocumentMenuDelegate, UIDocumentPickerDelegate {
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        //show document picker
        documentPicker.delegate = self;
        
        documentPicker.popoverPresentationController?.sourceView = self.view
        documentPicker.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        
        var fileAttributes: NSDictionary!
        //Documentation states that the file might not be imported due to being accessed from somewhere else
        do {
            fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path) as NSDictionary
        }catch{
            self.showAlert("Error", message: "File import fail, try again later", style: .alert)
            return
        }
        
        let trueName = url.lastPathComponent
        var finalPath = NSTemporaryDirectory() + "/" + NSUUID().uuidString + trueName
        
        if trueName.contains(" ") {
            finalPath = finalPath.replacingOccurrences(of: " ", with: "_")
        }
        
        let fileURL = URL(fileURLWithPath: finalPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
        
        do {
            try FileManager.default.moveItem(at: url, to: fileURL)
        }catch{
            self.showAlert("Error", message: "File import fail, try again later", style: .alert)
            return
        }
        
        guard let data = FileManager.default.contents(atPath: finalPath) else {
            self.showAlert("Error", message: "File import fail, try again later", style: .alert)
            return
        }
        
        if self.encryptionSwitch.isOn() && !self.currentUser.isPro() && data.count > 5000000 {
            //deny basic user attaching file over 5 Mbs
            var actions = [UIAlertAction]()
            
            let proAction = UIAlertAction(title: "Upgrate to Pro", style: .default, handler: { (action) in
                UIApplication.shared.open(URL(string: "https://criptext.com/mpricing")!)
            })
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            
            actions.append(proAction)
            actions.append(okAction)
            
            self.showAlert(nil, message: "File size of 5 Mb limit exceeded. Upgrade to Pro to increase allowed file size to 100 Mb", style: .alert, actions: actions)
            return
        }
        
        if self.encryptionSwitch.isOn() && self.currentUser.isPro() && data.count > 100000000 {
            //deny pro user attaching file over 100 Mbs
            self.showAlert(nil, message: "File size of 100 Mb limit exceeded.", style: .alert)
            return
        }
        
        //upload file to server
        
        var attachment:Attachment!
        if self.encryptionSwitch.isOn() {
            attachment = AttachmentCriptext()
        } else {
            attachment = AttachmentGmail()
        }
        
        attachment.fileName = trueName
        attachment.mimeType = mimeTypeForPath(path: trueName)
        attachment.filePath = finalPath
        attachment.size = Int(fileAttributes.fileSize())
        attachment.isEncrypted = self.encryptionSwitch.isOn()
        
        self.isEdited = true
        
        self.add(attachment)
        if !attachment.isEncrypted {
            attachment.isUploaded = true
            return
        }
        
        APIManager.upload(data, id:attachment.fileName, fileName:attachment.fileName, mimeType:attachment.mimeType, from:self.currentUser, delegate: self) { (error, fileToken) in
            
            if let error = error as NSError?,
            let errorObject = error.userInfo["error"] as? [String:String] {
                var actions = [UIAlertAction]()
                
                if !self.currentUser.isPro() && error.code == APIManager.CODE_FILE_SIZE_EXCEEDED {
                    let proAction = UIAlertAction(title: "Upgrate to Pro", style: .default, handler: { (action) in
                        UIApplication.shared.open(URL(string: "https://criptext.com/mpricing")!)
                    })
                    actions.append(proAction)
                }
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                actions.append(okAction)
                
                self.showAlert(errorObject["title"], message: errorObject["description"], style: .alert, actions: actions)
                
                //delete attachment
                self.remove(attachment)
                return
            }
            
            guard let fileToken = fileToken else {
                attachment.isUploaded = false
                print(error!)
                //show error in UI
                return
            }
            
            attachment.isUploaded = true
            attachment.fileToken = fileToken
            
            try? FileManager.default.removeItem(atPath:attachment.filePath)
            
            //update cell to hide progress bar
            guard let index = self.attachmentArray.index(where: { (attach) -> Bool in
                return attach == attachment
            }) else {
                //if not found, do nothing
                return
            }
            
            let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! AttachmentTableViewCell
            
            cell.progressView.progress = 1
            cell.progressView.isHidden = true
        }
    }
}

//MARK: - Keyboard handler
extension ComposeViewController{
    // 3
    // Add a gesture on the view controller to close keyboard when tapped
    func enableKeyboardHideOnTap(){
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil) // See 4.1
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil) //See 4.2
        
        // 3.1
        self.dismissTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ComposeViewController.hideKeyboard))
        self.dismissTapGestureRecognizer.delegate = self
        self.view.addGestureRecognizer(self.dismissTapGestureRecognizer)
    }
    
    //3.1
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
    
    //4.1
    @objc func keyboardWillShow(notification: NSNotification) {
        
        self.toolbarButtonsTopConstraint.constant = self.offsetValueTopconstraint
        
        let info = notification.userInfo!
        
        let keyboardFrame: CGRect = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        UIView.animate(withDuration: duration) { () -> Void in
            
            self.toolbarBottomConstraint.constant = keyboardFrame.size.height + 5
            
            self.view.layoutIfNeeded()
            
        }
        
    }
    
    //4.2
    @objc func keyboardWillHide(notification: NSNotification) {
        
        self.toolbarButtonsTopConstraint.constant = self.initialValueTopConstraint
        
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        UIView.animate(withDuration: duration) { () -> Void in
            
            self.toolbarBottomConstraint.constant = self.toolbarBottomConstraintInitialValue!
            self.view.layoutIfNeeded()
            
        }
        
    }
}


//MARK: - Progress Delegate
extension ComposeViewController: ProgressDelegate {
    func updateProgress(_ percent: Double, for id: String) {
        
        guard let index = self.attachmentArray.index(where: { (attachment) -> Bool in
            return attachment.fileName == id
        }) else {
            //if not found, do nothing
            return
        }
        
//        let attachment = self.attachmentArray[index]
        let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as! AttachmentTableViewCell
        cell.progressView.progress = Float(percent)
    }
}

//MARK: - TableView Data Source
extension ComposeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.contactTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell", for: indexPath)
            let contact = self.contactArray[indexPath.row]
            
            cell.textLabel?.text = contact.displayName
            cell.detailTextLabel?.text = contact.email
            
            return cell
        }
        
        let attachment = self.attachmentArray[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttachmentTableViewCell", for: indexPath) as! AttachmentTableViewCell
        cell.delegate = self
        
        cell.nameLabel.text = attachment.fileName
        cell.sizeLabel.text = "\(attachment.filesize)"
        
        //set initial state
        cell.passwordImageView.tintColor = Icon.disabled.color
        cell.passwordLabel.textColor = Icon.disabled.color
        cell.readOnlyImageView.tintColor = Icon.disabled.color
        cell.readOnlyLabel.textColor = Icon.disabled.color
        
        if !attachment.currentPassword.isEmpty {
            cell.passwordImageView.tintColor = Icon.activated.color
            cell.passwordLabel.textColor = Icon.activated.color
        }
        
        if attachment.isReadOnly {
            cell.readOnlyImageView.tintColor = Icon.activated.color
            cell.readOnlyLabel.textColor = Icon.activated.color
        }
        
        cell.readOnlyContainerView.isHidden = !attachment.isEncrypted
        cell.passwordContainerView.isHidden = !attachment.isEncrypted
        
        cell.lockImageView.image = Icon.lock.image
        
        if attachment.isEncrypted {
            cell.lockImageView.tintColor = Icon.activated.color
        } else {
            if self.encryptionSwitch.isOn() {
                cell.lockImageView.tintColor = Icon.enabled.color
                cell.lockImageView.image = Icon.lock_open.image
            } else {
                cell.lockImageView.tintColor = UIColor.red
            }
            
        }
        
        cell.progressView.isHidden = (attachment.isEncrypted && attachment.isUploaded) || cell.progressView.progress == 1 || !attachment.isEncrypted
        
        //image icon
        var imageIcon:UIImage!
        switch attachment.mimeType {
        case "application/pdf":
            imageIcon = Icon.attachment.pdf.image
            break
        case _ where attachment.mimeType.contains("application/msword") ||
            attachment.mimeType.contains("application/vnd.openxmlformats-officedocument.wordprocessingml") ||
            attachment.mimeType.contains("application/vnd.ms-word"):
            imageIcon = Icon.attachment.word.image
            break
        case "image/png", "image/jpeg":
            imageIcon = Icon.attachment.image.image
            break
        case _ where attachment.mimeType.contains("application/vnd.ms-powerpoint") ||
            attachment.mimeType.contains("application/vnd.openxmlformats-officedocument.presentationml"):
            imageIcon = Icon.attachment.ppt.image
            break
        case _ where attachment.mimeType.contains("application/vnd.ms-excel") ||
            attachment.mimeType.contains("application/vnd.openxmlformats-officedocument.spreadsheetml"):
            imageIcon = Icon.attachment.excel.image
            break
        default:
            imageIcon = Icon.attachment.generic.image
        }
        
        cell.typeImageView.image = imageIcon
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.contactTableView {
            return self.contactArray.count
        }
        return self.attachmentArray.count
    }
}

//MARK: - TableView Delegate
extension ComposeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.contactTableView {
            return 44.0
        }
        return self.rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == self.contactTableView {
            let contact = self.contactArray[indexPath.row]
            
            print(contact.email)
            var focusInput:CLTokenInputView!
            
            if self.toField.isEditing {
                focusInput = self.toField
            }
            
            if self.ccField.isEditing {
                focusInput = self.ccField
            }
            
            if self.bccField.isEditing {
                focusInput = self.bccField
            }
            
            self.addToken(contact.displayName, value: contact.email, to: focusInput)
            return
        }
    }
}

//MARK: - Cell Delegate
extension ComposeViewController: AttachmentTableViewCellDelegate {
    func tableViewCellDidTapPassword(_ cell: AttachmentTableViewCell) {
        let indexPath = self.tableView.indexPath(for: cell)
        var attachment = self.attachmentArray[indexPath!.row]
        
        guard attachment.currentPassword.isEmpty else {
            attachment.currentPassword = ""
            self.tableView.reloadData()
            return
        }
        
        let alertController = UIAlertController(title: "Set password", message: "It must be longer than 5 characters and don't contain special characters", preferredStyle: .alert)
        
        alertController.addTextField { (textField) in
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
            textField.delegate = self
            textField.addTarget(alertController, action: #selector(alertController.textDidChangeInLoginAlert), for: .editingChanged)
        }
        alertController.addTextField { (textField) in
            textField.placeholder = "Confirm Password"
            textField.isSecureTextEntry = true
            textField.delegate = self
            textField.addTarget(alertController, action: #selector(alertController.textDidChangeInLoginAlert), for: .editingChanged)
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        let okAction = UIAlertAction(title: "Ok", style: .default) { (action) in
            attachment.currentPassword = alertController.textFields?[0].text ?? ""
            self.tableView.reloadData()
        }
        
        okAction.isEnabled = false
        alertController.addAction(okAction)
        
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableViewCellDidTapReadOnly(_ cell: AttachmentTableViewCell) {
        let indexPath = self.tableView.indexPath(for: cell)
        var attachment = self.attachmentArray[indexPath!.row]
        attachment.isReadOnly = !attachment.isReadOnly
        print("wot")
        self.tableView.reloadData()
    }
    
    func tableViewCellDidLongPress(_ cell: AttachmentTableViewCell) {
        
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            self.tableView.reloadData()
            return
        }
        
        let attachment = self.attachmentArray[indexPath.row]
        
        cell.holdGestureRecognizer.isEnabled = false
        let alertController = UIAlertController(title: "Remove Attachment", message: "Are you sure you want to remove the attachment: \(attachment.fileName)", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive) { (action) in
            cell.holdGestureRecognizer.isEnabled = true
            
            self.removeAttachment(at: indexPath)
        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            cell.holdGestureRecognizer.isEnabled = true
        })
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func tableViewCellDidTap(_ cell: AttachmentTableViewCell) {
        
    }
}

//MARK: - UIGestureRecognizer Delegate
extension ComposeViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        let touchPt = touch.location(in: self.view)
        
        guard let tappedView = self.view.hitTest(touchPt, with: nil) else {
            return true
        }
        
        
        if gestureRecognizer == self.dismissTapGestureRecognizer && tappedView.isDescendant(of: self.contactTableView) && !self.contactTableView.isHidden {
            return false
        }
        
        return true
    }
}

//MARK: - TextField Delegate
extension ComposeViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if !self.isEdited && !(textField.text?.isEmpty)!{
            self.isEdited = true
        }
        
        return true
//        let set = CharacterSet(charactersIn: "ABCDEFGHIJKLMONPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ").inverted
//        return string.rangeOfCharacter(from: set) == nil
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.collapseCC(true)
    }
}

//MARK: - Picker Delegate
extension ComposeViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0:
            return self.days.count
        case 1:
            return self.hours.count
        case 2:
            return self.minutes.count
        default:
            return 0
        }
    }
}

extension ComposeViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        var text:String!
        
        switch component {
        case 0:
            text = "\(self.days[row])"
        case 1:
            text = "\(self.hours[row])"
        case 2:
            text = "\(self.minutes[row])"
        default:
            text = ""
        }
        
        return text
    }
}


//MARK: - Token Input Delegate
extension ComposeViewController: CLTokenInputViewDelegate {
    
    func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        if !self.isEdited {
            self.isEdited = true
        }
        
        self.sendSecureBarButton.isEnabled = true
        self.sendBarButton.isEnabled = true
        
        if text!.contains(",") {
            let name = text?.replacingOccurrences(of: ",", with: "")
            
            if APIManager.isValidEmail(text: name!) {
                let token = CLToken(displayText: name!, context: nil)
                view.add(token)
            } else {
//                view.textField.text = name
                self.showAlert("Invalid recipient", message: "Please enter a valid email address", style: .alert)
            }
            
        } else if text!.contains(" ") {
            let name = text?.replacingOccurrences(of: " ", with: "")
            
            if APIManager.isValidEmail(text: name!) {
                let token = CLToken(displayText: name!, context: nil)
                view.add(token)
            } else {
//                view.textField.text = name
                self.showAlert("Invalid recipient", message: "Please enter a valid email address", style: .alert)
            }
        }
        
        if self.toField.allTokens.isEmpty && (self.toField.text?.isEmpty)! {
            self.sendSecureBarButton.isEnabled = false
            self.sendBarButton.isEnabled = false
        }
        
        self.contactTableView.isHidden = (view.text?.isEmpty)!
        
        if !(text?.isEmpty)! {
            self.contactArray = DBManager.getContacts(text ?? "")
            self.contactTableView.isHidden = self.contactArray.isEmpty
            
            self.contactTableView.reloadData()
        }
    }
    
    func tokenInputViewDidBeginEditing(_ view: CLTokenInputView) {
        
        if view == self.toField {
            self.contactTableViewTopConstraint.constant = 1
        }
        
        if view == self.ccField {
            self.contactTableViewTopConstraint.constant = view.bounds.height
        }
        
        if view == self.bccField {
            self.contactTableViewTopConstraint.constant = self.ccField.bounds.height + self.bccField.bounds.height
        }
        
        self.collapseCC(false)
    }

    func tokenInputViewDidEndEditing(_ view: CLTokenInputView) {
        self.contactTableView.isHidden = true
        guard let text = view.text, text.characters.count > 0 else {
            return
        }
        
        if APIManager.isValidEmail(text: text) {
            let token = CLToken(displayText: text, context: nil)
            view.add(token)
        } else {
            self.showAlert("Invalid recipient", message: "Please enter a valid email address", style: .alert)
        }
//        let token = CLToken(displayText: text, context: nil)
//        view.add(token)
    }
    
    func tokenInputView(_ view: CLTokenInputView, didRemove token: CLToken) {
        if self.toField.allTokens.isEmpty && (self.toField.text?.isEmpty)! {
            self.sendSecureBarButton.isEnabled = false
            self.sendBarButton.isEnabled = false
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        
        if view == self.toField {
            self.toHeightConstraint.constant = height
            if self.toField.isEditing {
                self.contactTableViewTopConstraint.constant = 1
            }
        } else if view == self.ccField {
            self.ccHeightConstraint.constant = height
            
            if self.ccField.isEditing {
                self.contactTableViewTopConstraint.constant = height
            }
        } else if view == self.bccField {
            self.bccHeightConstraint.constant = height
            
            if self.bccField.isEditing {
                self.contactTableViewTopConstraint.constant = self.ccField.bounds.height + height
            }
        }
    }
}

extension ComposeViewController: CNContactPickerDelegate {
    func showContactPicker(_ sender:UIButton){
        self.selectedTokenInputView = sender.superview as? CLTokenInputView
        
        let picker = CNContactPickerViewController()
        picker.displayedPropertyKeys = [CNContactEmailAddressesKey]
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let tokenInputView = self.selectedTokenInputView, let email = contactProperty.value as? String else {
            return
        }
        
        self.addToken(email, value: email, to: tokenInputView)
    }
    
    func addToken(_ display:String, value:String, to view:CLTokenInputView){
        let valueObject = NSString(string: value)
        let token = CLToken(displayText: display, context: valueObject)
        view.add(token)
    }
}

//MARK: - Rich editor Delegate
extension ComposeViewController: RichEditorDelegate {
    
    func richEditor(_ editor: RichEditorView, heightDidChange height: Int) {
        
        let cgheight = CGFloat(height)
        let diff = cgheight - self.editorHeightConstraint.constant
        
        let offset = self.scrollView.contentOffset
        
        //90 = to and subject fields + 45 = toolbar
        if CGFloat(height + 90 + 25) > self.toolbarView.frame.origin.y {
            var newOffset = CGPoint(x: offset.x, y: offset.y + 28)
            if diff == -28  {
                newOffset = CGPoint(x: offset.x, y: offset.y - 28)
            }
            
            //avoid this when populating a draft
//            if self.isEdited && editor.isEditorLoaded {
//                self.scrollView.setContentOffset(newOffset, animated: true)
//            }
            
        }
        
        guard height > 350 else {
            return
        }
        
        self.editorHeightConstraint.constant = cgheight
    }
    
    func richEditor(_ editor: RichEditorView, contentDidChange content: String) {
//        if !self.isEdited && editor.isEditorLoaded {
            self.isEdited = true
//        }
    }
    
    func richEditorDidLoad(_ editor: RichEditorView) {
        
        self.editorView.replace(font: "Lato-Regular", css: "editor-style")
        
    }
    
    func richEditorTookFocus(_ editor: RichEditorView) {
        self.collapseCC(true)
    }
}
