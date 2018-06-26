//
//  ComposeViewController.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/22/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import CLTokenInputView
import Photos
import CICropPicker
import M13Checkbox
import ContactsUI
import RichEditorView
import SwiftSoup
import MIBadgeButton_Swift
import IQKeyboardManagerSwift
import SignalProtocolFramework

protocol ComposerSendMailDelegate {
    func sendMail(email: Email)
}

class ComposeViewController: UIViewController {
    let DEFAULT_ATTACHMENTS_HEIGHT = 303
    let MAX_ROWS_BEFORE_CALC_HEIGHT = 3
    let ATTACHMENT_ROW_HEIGHT = 65
    let MARGIN_TOP = 20
    let CONTACT_FIELDS_HEIGHT = 90
    let ENTER_LINE_HEIGHT : CGFloat = 28.0
    let TOOLBAR_MARGIN_HEIGHT = 25
    let COMPOSER_MIN_HEIGHT = 150
    
    @IBOutlet weak var toField: CLTokenInputView!
    @IBOutlet weak var ccField: CLTokenInputView!
    @IBOutlet weak var bccField: CLTokenInputView!
    @IBOutlet weak var subjectField: UITextField!
    @IBOutlet weak var editorView: RichEditorView!
    
    @IBOutlet weak var toolbarView: UIView!
    @IBOutlet weak var toolbarBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolbarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bccHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ccHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var editorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var blackBackground: UIView!
    @IBOutlet weak var attachmentContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachmentTableHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var contactTableView: UITableView!
    @IBOutlet weak var contactTableViewTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var closeBarButton: UIBarButtonItem!
    @IBOutlet weak var attachmentButtonContainerView: UIView!
    @IBOutlet weak var buttonCollapse: UIButton!
    
    var activeAccount:Account!
    
    var expandedBbcSpacing:CGFloat = 45
    var expandedCcSpacing:CGFloat = 45
    var attachmentOptionsHeight: CGFloat = 110
    
    var toolbarBottomConstraintInitialValue: CGFloat?
    var toolbarHeightConstraintInitialValue: CGFloat?
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    
    let rowHeight:CGFloat = 65.0
    
    let imagePicker = CICropPicker()
    
    var thumbUpdated = false
    
    var selectedTokenInputView:CLTokenInputView?
    
    var isEdited = false
    
    var sendBarButton:UIBarButtonItem!
    var sendSecureBarButton:UIBarButtonItem!
    var attachmentBarButton:MIBadgeButton!
    
    var dismissTapGestureRecognizer: UITapGestureRecognizer!
    
    let DOMAIN = "jigl.com"
    
    var composerData = ComposerData()
    let fileManager = CriptextFileManager()
    
    var delegate : ComposerSendMailDelegate?
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textField = UITextField.appearance(whenContainedInInstancesOf: [CLTokenInputView.self])
        textField.font = Font.regular.size(14)
        
        let defaults = UserDefaults.standard
        activeAccount = DBManager.getAccountByUsername(defaults.string(forKey: "activeAccount")!)
        
        self.sendBarButton = UIBarButtonItem(image: Icon.send.image, style: .plain, target: self, action: #selector(didPressSend(_:)))
        self.sendSecureBarButton = UIBarButtonItem(image: Icon.send.image, style: .plain, target: self, action: #selector(didPressSend(_:)))
        self.sendSecureBarButton.tintColor = .white
        
        self.editorView.placeholder = "Message"
        self.editorView.delegate = self
        self.subjectField.delegate = self
        
        self.toField.fieldName = "To"
        self.toField.tintColor = Icon.system.color
        self.toField.delegate = self
        
        let toFieldButton = UIButton(type: .custom)
        toFieldButton.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        toFieldButton.setTitle("+", for: .normal)
        toFieldButton.setTitleColor(Icon.system.color, for: .normal)
        toFieldButton.addTarget(self, action: #selector(didPressAccessoryView(_:)), for: .touchUpInside)
        self.toField.accessoryView = toFieldButton
        self.toField.accessoryView?.isHidden = true
        
        self.bccField.fieldName = "Bcc"
        self.bccField.tintColor = Icon.system.color
        self.bccField.delegate = self
        
        let bccFieldButton = UIButton(type: .custom)
        bccFieldButton.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        bccFieldButton.setTitle("+", for: .normal)
        bccFieldButton.setTitleColor(Icon.system.color, for: .normal)
        bccFieldButton.addTarget(self, action: #selector(didPressAccessoryView(_:)), for: .touchUpInside)
        self.bccField.accessoryView = bccFieldButton
        self.bccField.accessoryView?.isHidden = true
        
        self.ccField.fieldName = "Cc"
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
        
        self.editorView.isScrollEnabled = false
        self.editorHeightConstraint.constant = 150
        self.attachmentContainerBottomConstraint.constant = 50
        
        self.toolbarBottomConstraintInitialValue = toolbarBottomConstraint.constant
        self.toolbarHeightConstraintInitialValue = toolbarHeightConstraint.constant
        
        //3
        self.enableKeyboardHideOnTap()
        
        self.imagePicker.delegate = self
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideBlackBackground(_:)))
        self.blackBackground.addGestureRecognizer(tap)
        
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView()
        self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 0, 0)
        
        let activityButton = MIBadgeButton(type: .custom)
        activityButton.badgeString = ""
        activityButton.frame = CGRect(x:14, y:8, width:18, height:32)
        activityButton.imageEdgeInsets = UIEdgeInsetsMake(2, 2, 5, 2)
        activityButton.badgeEdgeInsets = UIEdgeInsetsMake(5, 12, 0, 13)
        activityButton.tintColor = Icon.enabled.color
        activityButton.tintColor = fileManager.registeredFiles.isEmpty ? Icon.enabled.color : Icon.system.color
        activityButton.isUserInteractionEnabled = false
        self.attachmentBarButton = activityButton
        self.attachmentButtonContainerView.addSubview(self.attachmentBarButton)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didPressAttachment(_:)))
        self.attachmentButtonContainerView.addGestureRecognizer(tapGesture)
        self.title = "New Secure Email"
        self.navigationItem.rightBarButtonItem = self.sendSecureBarButton
        activityButton.setImage(Icon.attachment.vertical.image, for: .normal)
        activityButton.badgeEdgeInsets = UIEdgeInsetsMake(5, 12, 0, 13)
        
        var badgeString = ""
        
        if fileManager.registeredFiles.count > 0 {
            badgeString = "\(fileManager.registeredFiles.count)"
        }
        
        self.attachmentBarButton.badgeString = badgeString
        self.closeBarButton.tintColor = UIColor.white.withAlphaComponent(0.4)
        
        subjectField.text = composerData.initSubject
        editorView.html = composerData.initContent + (composerData.emailDraft == nil && !activeAccount.signature.isEmpty && activeAccount.signatureEnabled ? "<br/> \(activeAccount.signature)" : "")
        
        fileManager.delegate = self
    }
    
    func setupInitContacts(){
        for contact in composerData.initToContacts {
            addToken(contact.displayName, value: contact.email, to: toField)
        }
        for contact in composerData.initCcContacts {
            addToken(contact.displayName, value: contact.email, to: ccField)
        }
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        
        if !self.thumbUpdated {
            self.thumbUpdated = true
        }
        
        if self.toField.allTokens.isEmpty {
            self.sendSecureBarButton.isEnabled = false
            self.sendBarButton.isEnabled = false
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        IQKeyboardManager.shared.enable = false
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        IQKeyboardManager.shared.enable = true
    }
    
    func remove(_ attachment:File){
        
        guard let index = fileManager.registeredFiles.index(where: { (attach) -> Bool in
            return attach == attachment
        }) else {
            //if not found, do nothing
            return
        }
        
        self.removeAttachment(at: IndexPath(row: index, section: 0))
    }
    
    func removeAttachment(at indexPath:IndexPath){
        _ = fileManager.registeredFiles.remove(at: indexPath.row)
        
        self.updateBadge()
        self.toggleAttachmentTable()
        
        self.tableView.performUpdate({
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
        }, completion: nil)
        
    }
    
    func saveDraft() -> Email {
        if let draft = composerData.emailDraft {
            let data = ["draftId": draft.key]
            NotificationCenter.default.post(name: .onDeleteDraft, object: nil, userInfo: data)
            DBManager.delete(draft)
        }
        
        self.resignKeyboard()
        
        var subject = self.subjectField.text ?? ""
        
        if subject.isEmpty {
            subject = "No Subject"
        }
        
        //create draft
        let draft = Email()
        draft.status = .none
        draft.content = self.editorView.html
        let bodyWithoutHtml = self.editorView.text
        draft.preview = String(bodyWithoutHtml.prefix(100))
        draft.unread = false
        draft.subject = subject
        draft.date = Date()
        draft.key = "\(activeAccount.deviceId)\(Int(draft.date.timeIntervalSince1970))"
        draft.threadId = composerData.threadId ?? ""
        draft.labels.append(DBManager.getLabel(SystemLabel.draft.id)!)
        draft.files.append(objectsIn: fileManager.storeFiles())
        DBManager.store(draft)
        
        
        //create email contacts
        var emailContacts = [EmailContact]()
        self.toField.allTokens.forEach { (token) in
            self.fillEmailContacts(emailContacts: &emailContacts, token: token, emailDetail: draft, type: ContactType.to)
        }
        self.ccField.allTokens.forEach { (token) in
            self.fillEmailContacts(emailContacts: &emailContacts, token: token, emailDetail: draft, type: ContactType.cc)
        }
        self.bccField.allTokens.forEach { (token) in
            self.fillEmailContacts(emailContacts: &emailContacts, token: token, emailDetail: draft, type: ContactType.bcc)
        }
        self.fillEmailContacts(emailContacts: &emailContacts, token: CLToken(displayText: "\(activeAccount.username)@\(DOMAIN)", context: nil), emailDetail: draft, type: ContactType.from)
        
        DBManager.store(emailContacts)
        
        return draft
    }
    
    func getEmailFromToken(_ token: CLToken) -> String {
        var email = ""
        if let emailTemp = token.context as? NSString {
            email = String(emailTemp)
        } else {
            email = token.displayText
        }
        return email
    }
    
    func fillEmailContacts(emailContacts: inout Array<EmailContact>, token: CLToken, emailDetail: Email, type: ContactType){
        let email = getEmailFromToken(token)
        let emailContact = EmailContact()
        emailContact.email = emailDetail
        emailContact.type = type.rawValue
        if let contact = DBManager.getContact(email) {
            emailContact.contact = contact
        } else {
            let newContact = Contact()
            newContact.email = email
            newContact.displayName = token.displayText.contains("@") ? String(token.displayText.split(separator: "@")[0]) : token.displayText
            DBManager.store([newContact]);
            emailContact.contact = newContact
        }
        emailContacts.append(emailContact)
    }
    
    @objc func hideBlackBackground(_ flag:Bool = false){
        
        self.showAttachmentDrawer(false)
        self.resignKeyboard()
        self.navigationController?.navigationBar.layer.zPosition = flag ? -1 : 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.blackBackground.alpha = 0
        }
    }
    
    func showAttachmentDrawer(_ flag:Bool = false){
        
        self.resignKeyboard()
        
        self.navigationController?.navigationBar.layer.zPosition = flag ? -1 : 0
        
        self.attachmentContainerBottomConstraint.constant = CGFloat(flag ? -attachmentOptionsHeight : 50)
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.blackBackground.alpha = flag ? 0.5 : 0
        }
    }
    
    func toggleAttachmentTable(){
        var height = DEFAULT_ATTACHMENTS_HEIGHT
        if fileManager.registeredFiles.count > MAX_ROWS_BEFORE_CALC_HEIGHT {
            height = MARGIN_TOP + (fileManager.registeredFiles.count * ATTACHMENT_ROW_HEIGHT)
        }
        
        if fileManager.registeredFiles.isEmpty {
            height = 0
        }
        
        self.attachmentTableHeightConstraint.constant = CGFloat(height)
        self.showAttachmentDrawer(false)
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
        
        self.buttonCollapse.setImage(flag ? Icon.new_arrow.down.image : Icon.new_arrow.up.image, for: .normal)
        self.bccHeightConstraint.constant = flag ? 0 : self.expandedBbcSpacing
        self.ccHeightConstraint.constant = flag ? 0 : self.expandedCcSpacing
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func addAttachments(to body:String) -> String{
        guard !fileManager.registeredFiles.isEmpty else {
            return body
        }
        
        var doc:Document!
        do {
            doc = try SwiftSoup.parse(body)
            let elements = try doc.getElementsByClass("criptext_attachment")
            try elements.remove()
            
            for attachment in fileManager.registeredFiles {
                
                var preTag:Element!
                
                if let body = doc.body() {
                    preTag = try body.appendElement("pre")
                } else {
                    preTag = try doc.appendElement("pre")
                }
                
                try preTag.addClass("criptext_attachment")
                try preTag.html("\(attachment.token):\(attachment.name):\(attachment.size)")
                try preTag.attr("style", "color:white;display:none")
            }
            
            return try doc.html()
        } catch {
            return body
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
        
        guard fileManager.pendingAttachments() else {
            handleExit()
            return
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let sendAction = UIAlertAction(title: "Yes", style: .default, handler: { (_) in
            self.fileManager.registeredFiles = self.fileManager.registeredFiles.filter({$0.requestStatus == .finish})
            self.tableView.reloadData()
            self.updateBadge()
            self.handleExit()
        })
        self.showAlert("Pending Attachments", message: "Some attachments are being uploaded. Would you like to discard them and proceed?", style: .alert, actions: [cancelAction, sendAction])
        return
    }
    
    func handleExit(){
        let discardTitle = "Discard"
        
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: discardTitle, style: .destructive) { action in
            APIManager.cancelAllUploads()
            if let draft = self.composerData.emailDraft {
                let data = ["draftId": draft.key]
                NotificationCenter.default.post(name: .onDeleteDraft, object: nil, userInfo: data)
                DBManager.delete(draft)
            }
            self.dismiss(animated: true, completion: nil)
        })
        sheet.addAction(UIAlertAction(title: "Save Draft", style: .default) { action in
            APIManager.cancelAllUploads()
            let draft = self.saveDraft()
            let data = ["email": draft]
            NotificationCenter.default.post(name: .onNewEmail, object: nil, userInfo: data)
            self.dismiss(animated: true, completion: nil)
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(sheet, animated: true, completion:nil)
    }
    
    @IBAction func didPressSend(_ sender: UIBarButtonItem) {
        self.resignKeyboard()
        
        //validate if there are no more attachments pending
        guard !fileManager.pendingAttachments() else {
            self.showAlert(nil, message: "Please wait for your attachments to finish processing", style: .alert)
            return
        }
        
        //validate
        guard let subject = self.subjectField.text, !subject.isEmpty else {
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let sendAction = UIAlertAction(title: "Send", style: .default, handler: { (_) in
                self.prepareMail()
            })
            self.showAlert("Empty Subject", message: "This email has no subject. Do you want to send it anyway?", style: .alert, actions: [cancelAction, sendAction])
            return
        }
        
        self.prepareMail()
    }
    
    func sendMailInMainController(){
        guard let email = composerData.emailDraft else {
            return
        }
        DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.sent.id], removedLabelIds: [SystemLabel.draft.id])
        DBManager.updateEmail(email, status: .sending)
        self.dismiss(animated: true){
            self.delegate?.sendMail(email: email)
        }
    }
    
    func prepareMail(){
        let draftEmail = saveDraft()
        composerData.emailDraft = draftEmail
        
        let containsNonCriptextEmail = draftEmail.getContacts(type: .to).contains(where: {!$0.email.contains(Constants.domain)}) || draftEmail.getContacts(type: .cc).contains(where: {!$0.email.contains(Constants.domain)}) || draftEmail.getContacts(type: .bcc).contains(where: {!$0.email.contains(Constants.domain)})
        
        guard !containsNonCriptextEmail else {
            self.presentPopover()
            return
        }
        
        self.toggleInteraction(false)
        sendMailInMainController()
    }
    
    func presentPopover(){
        let setPassPopover = EmailSetPasswordViewController()
        setPassPopover.delegate = self
        setPassPopover.preferredContentSize = CGSize(width: 270, height: 300)
        setPassPopover.popoverPresentationController?.sourceView = self.view
        setPassPopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        setPassPopover.popoverPresentationController?.permittedArrowDirections = []
        setPassPopover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(setPassPopover, animated: true)
    }
    
    @IBAction func didPressCC(_ sender: UIButton) {
        let needsCollapsing = self.bccHeightConstraint.constant != 0
        self.collapseCC(needsCollapsing)
    }
    
    @IBAction func didPressSubject(_ sender: UIButton) {
        self.subjectField.becomeFirstResponder()
    }
    
    @IBAction func didPressAttachment(_ sender: UIButton) {
        //derpo
        self.showAttachmentDrawer(true)
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
        
        guard let data = UIImageJPEGRepresentation(image, 0.6) else {
            return
        }
        
        imagePicker.dismiss(animated: true){
            let filename = "Criptext_Image_\(formatter.string(from: currentDate)).png"
            let mimeType = "image/png"
            
            self.isEdited = true
            self.fileManager.registerFile(file: data, name: filename, mimeType: mimeType)
            self.tableView.performUpdate({
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
            }, completion: nil)
            self.toggleAttachmentTable()
            self.updateBadge()
        }
    }
    
    func updateBadge(){
        self.attachmentBarButton.tintColor = Icon.system.color
        let badgeCount = fileManager.registeredFiles.count
        self.attachmentBarButton.badgeString =  badgeCount > 0 ? "\(badgeCount)" : ""
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
        
        self.isEdited = true
        self.fileManager.registerFile(file: data, name: trueName, mimeType: mimeTypeForPath(path: trueName))
        self.tableView.performUpdate({
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        }, completion: nil)
        self.toggleAttachmentTable()
        self.updateBadge()
    }
}

extension ComposeViewController: emailSetPasswordDelegate {
    func setPassword(password: String) {
        self.toggleInteraction(false)
        sendMailInMainController()
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
        
        let duration = notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! Double
        
        UIView.animate(withDuration: duration) { () -> Void in
            
            self.toolbarBottomConstraint.constant = self.toolbarBottomConstraintInitialValue!
            self.view.layoutIfNeeded()
            
        }
        
    }
}


//MARK: - Progress Delegate
extension ComposeViewController: ProgressDelegate {
    func chunkUpdateProgress(_ percent: Double, for token: String, part: Int) {
        
    }
    
    func updateProgress(_ percent: Double, for id: String) {

    }
}

//MARK: - TableView Data Source
extension ComposeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if tableView == self.contactTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell", for: indexPath) as! ContactTableViewCell
            let contact = composerData.contactArray[indexPath.row]
            
            cell.nameLabel?.text = contact.displayName
            cell.emailLabel?.text = contact.email
            cell.avatarImageView.setImageWith(contact.displayName, color: colorByName(name: contact.displayName), circular: true, fontName: "NunitoSans-Regular")
            
            return cell
        }
        
        let attachment = fileManager.registeredFiles[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttachmentTableViewCell", for: indexPath) as! AttachmentTableViewCell
        
        cell.nameLabel.text = attachment.name
        cell.sizeLabel.text = attachment.prettyPrintSize()
        cell.lockImageView.image = Icon.lock.image
        
        cell.lockImageView.tintColor = Icon.enabled.color
        cell.lockImageView.image = Icon.lock_open.image
        
        cell.progressView.isHidden = attachment.requestStatus == .finish
        cell.successImageView.isHidden = attachment.requestStatus != .finish
        
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
        cell.delegate = self
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.contactTableView {
            return composerData.contactArray.count
        }
        return fileManager.registeredFiles.count
    }
}

//MARK: - TableView Delegate
extension ComposeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.contactTableView {
            return 60.0
        }
        return self.rowHeight
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView == self.contactTableView {
            let contact = composerData.contactArray[indexPath.row]
            
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

extension ComposeViewController: AttachmentTableViewCellDelegate{
    func tableViewCellDidTapReadOnly(_ cell: AttachmentTableViewCell) {}
    
    func tableViewCellDidTapPassword(_ cell: AttachmentTableViewCell) {}
    
    func tableViewCellDidTapRemove(_ cell: AttachmentTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        fileManager.removeFile(filetoken: fileManager.registeredFiles[indexPath.row].token)
        tableView.deleteRows(at: [indexPath], with: .none)
        updateBadge()
    }
    
    func tableViewCellDidTap(_ cell: AttachmentTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        fileManager.registerFile(file: fileManager.registeredFiles[indexPath.row])
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
                let valueObject = NSString(string: name!)
                let token = CLToken(displayText: name!, context: valueObject)
                view.add(token)
            } else {
//                view.textField.text = name
                self.showAlert("Invalid recipient", message: "Please enter a valid email address", style: .alert)
            }
            
        } else if text!.contains(" ") {
            let name = text?.replacingOccurrences(of: " ", with: "")
            
            if APIManager.isValidEmail(text: name!) {
                let valueObject = NSString(string: name!)
                let token = CLToken(displayText: name!, context: valueObject)
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
        self.toolbarHeightConstraint.constant = (view.text?.isEmpty)! ? self.toolbarHeightConstraintInitialValue! : 0
        self.toolbarView.isHidden = (view.text?.isEmpty)! ? false : true
        
        if !(text?.isEmpty)! {
            composerData.contactArray = DBManager.getContacts(text ?? "")
            
            self.contactTableView.isHidden = composerData.contactArray.isEmpty
            self.toolbarHeightConstraint.constant = composerData.contactArray.isEmpty ? self.toolbarHeightConstraintInitialValue! : 0
            self.toolbarView.isHidden = composerData.contactArray.isEmpty ? false : true
            
            self.contactTableView.reloadData()
        }
        
        self.view.layoutIfNeeded()
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
        
    }

    func tokenInputViewDidEndEditing(_ view: CLTokenInputView) {
        
        self.contactTableView.isHidden = true
        
        guard let text = view.text, text.count > 0 else {
            return
        }
        
        if APIManager.isValidEmail(text: text) {
            let token = CLToken(displayText: text, context: nil)
            view.add(token)
        } else {
            self.showAlert("Invalid recipient", message: "Please enter a valid email address", style: .alert)
        }
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

extension ComposeViewController: CriptextFileDelegate {
    func finishRequest(file: File, success: Bool) {
        guard let cell = getCellForFile(file) else {
            return
        }
        cell.setMarkIcon(success: success)
    }
    
    func uploadProgressUpdate(file: File, progress: Int) {
        guard let cell = getCellForFile(file) else {
            return
        }
        let percentage = Float(progress)/100.0
        cell.successImageView.isHidden = true
        cell.progressView.isHidden = false
        cell.progressView.setProgress(percentage, animated: true)
    }
    
    func getCellForFile(_ file: File) -> AttachmentTableViewCell? {
        guard let index = fileManager.registeredFiles.index(where: {$0.token == file.token}),
            let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? AttachmentTableViewCell else {
                return nil
        }
        return cell
    }
}

//MARK: - Rich editor Delegate
extension ComposeViewController: RichEditorDelegate {
    
    func richEditor(_ editor: RichEditorView, heightDidChange height: Int) {
        let cgheight = CGFloat(height)
        let diff = cgheight - self.editorHeightConstraint.constant
        let offset = self.scrollView.contentOffset
        
        if CGFloat(height + CONTACT_FIELDS_HEIGHT + TOOLBAR_MARGIN_HEIGHT) > self.toolbarView.frame.origin.y {
            var newOffset = CGPoint(x: offset.x, y: offset.y + ENTER_LINE_HEIGHT)
            if diff == -ENTER_LINE_HEIGHT  {
                newOffset = CGPoint(x: offset.x, y: offset.y - ENTER_LINE_HEIGHT)
            }

            if self.isEdited && !editor.webView.isLoading {
                self.scrollView.setContentOffset(newOffset, animated: true)
            }
        }
        
        guard height > COMPOSER_MIN_HEIGHT else {
            return
        }
        
        self.editorHeightConstraint.constant = cgheight
    }
    
    func richEditor(_ editor: RichEditorView, contentDidChange content: String) {
        guard !content.isEmpty else {
            return
        }
        self.isEdited = true
    }
    
    func richEditorDidLoad(_ editor: RichEditorView) {
        self.editorView.replace(font: "NunitoSans-Regular", css: "editor-style")
        if(!composerData.initSubject.isEmpty && composerData.initToContacts.count > 0){
            self.setupInitContacts()
            editorView.focus(at: CGPoint(x: 0.0, y: 0.0))
        }else{
            toField.beginEditing()
        }
    }
    
    func richEditorTookFocus(_ editor: RichEditorView) {
        self.collapseCC(true)
    }
}
