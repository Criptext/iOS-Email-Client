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
import TLPhotoPicker
import M13Checkbox
import ContactsUI
import RichEditorView
import SwiftSoup
import MIBadgeButton_Swift
import IQKeyboardManagerSwift
import SignalProtocolFramework
import Instructions

protocol ComposerSendMailDelegate: class {
    func sendMail(email: Email, emailBody: String, password: String?)
    func newDraft(draft: Email)
    func deleteDraft(draftId: Int)
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
    let PASSWORD_POPUP_HEIGHT = 295
    
    @IBOutlet weak var fromField: UILabel!
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var fromMenuView: BottomMenuView!
    
    @IBOutlet weak var toField: CLTokenInputView!
    @IBOutlet weak var ccField: CLTokenInputView!
    @IBOutlet weak var bccField: CLTokenInputView!
    @IBOutlet weak var subjectField: UITextField!
    @IBOutlet weak var editorView: RichEditorView!
    @IBOutlet weak var topSeparator: UIView!
    @IBOutlet weak var bottomSeparator: UIView!
    
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
    
    @IBOutlet weak var attachmentButtonContainerView: UIView!
    @IBOutlet weak var buttonCollapse: UIButton!
    
    var activeAccount:Account!
    
    var expandedBbcSpacing: CGFloat = 45
    var expandedCcSpacing: CGFloat = 45
    var attachmentOptionsHeight: CGFloat = 110
    
    var toolbarBottomConstraintInitialValue: CGFloat?
    var toolbarHeightConstraintInitialValue: CGFloat?
    
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    
    let rowHeight:CGFloat = 65.0
    
    let imagePicker = CICropPicker()
    
    var thumbUpdated = false
    
    var selectedTokenInputView:CLTokenInputView?
    
    var isEdited = false
    var attachmentBarButton:MIBadgeButton!
    
    var dismissTapGestureRecognizer: UITapGestureRecognizer!
    var composerData = ComposerData()
    let fileManager = CriptextFileManager()
    let coachMarksController = CoachMarksController()
    
    weak var delegate : ComposerSendMailDelegate?
    
    var enableSendButton: UIBarButtonItem!
    var disableSendButton: UIBarButtonItem!
    var popoverToPresent: BaseUIPopover?
    
    var composerKeyboardOffset: CGFloat = 0.0
    var composerEditorHeight: CGFloat = 0.0
    
    //MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textField = UITextField.appearance(whenContainedInInstancesOf: [CLTokenInputView.self])
        textField.font = Font.regular.size(14)
        
        let defaults = CriptextDefaults()
        activeAccount = DBManager.getAccountById(defaults.activeAccount!)
        fileManager.myAccount = activeAccount
        
        let sendImage = Icon.send.image?.tint(with: .white)
        self.enableSendButton = UIBarButtonItem(image: sendImage, style: .plain, target: self, action: #selector(didPressSend(_:)))
        let disableImage = Icon.send.image?.tint(with: UIColor.white.withAlphaComponent(0.6))
        self.disableSendButton = UIBarButtonItem(image: disableImage, style: .plain, target: self, action: nil)
        
        self.editorView.placeholder = String.localize("MESSAGE")
        self.editorView.delegate = self
        self.subjectField.delegate = self
        self.subjectField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        
        self.toField.fieldName = String.localize("TO")
        self.toField.delegate = self
        
        let toFieldButton = UIButton(type: .custom)
        toFieldButton.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        toFieldButton.setTitle(String.localize("+"), for: .normal)
        toFieldButton.setTitleColor(Icon.system.color, for: .normal)
        toFieldButton.addTarget(self, action: #selector(didPressAccessoryView(_:)), for: .touchUpInside)
        self.toField.accessoryView = toFieldButton
        self.toField.accessoryView?.isHidden = true
        
        self.bccField.fieldName = String.localize("BCC")
        self.bccField.delegate = self
        
        let bccFieldButton = UIButton(type: .custom)
        bccFieldButton.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        bccFieldButton.setTitle(String.localize("+"), for: .normal)
        bccFieldButton.setTitleColor(Icon.system.color, for: .normal)
        bccFieldButton.addTarget(self, action: #selector(didPressAccessoryView(_:)), for: .touchUpInside)
        self.bccField.accessoryView = bccFieldButton
        self.bccField.accessoryView?.isHidden = true
        
        self.ccField.fieldName = String.localize("CC")
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
        self.tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        
        let activityButton = MIBadgeButton(type: .custom)
        activityButton.badgeString = ""
        activityButton.frame = CGRect(x:14, y:8, width:18, height:32)
        activityButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 5, right: 2)
        activityButton.badgeEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 0, right: 13)
        activityButton.tintColor = Icon.enabled.color
        activityButton.isUserInteractionEnabled = false
        self.attachmentBarButton = activityButton
        self.attachmentButtonContainerView.layer.borderWidth = 2.0
        self.attachmentButtonContainerView.addSubview(self.attachmentBarButton)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didPressAttachment(_:)))
        self.attachmentButtonContainerView.addGestureRecognizer(tapGesture)
        self.title = String.localize("NEW_SECURE_EMAIL")
        self.navigationItem.rightBarButtonItem = self.enableSendButton
        activityButton.setImage(Icon.attachment.vertical.image, for: .normal)
        activityButton.badgeEdgeInsets = UIEdgeInsets(top: 5, left: 12, bottom: 0, right: 13)
        
        let closeImage = UIImage(named: "close-rounded")!.tint(with: UIColor.white.withAlphaComponent(0.6))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: closeImage, style: .plain, target: self, action: #selector(didPressCancel(_:)))
        
        subjectField.text = composerData.initSubject
        editorView.html = "\(composerData.initContent)\(composerData.emailDraft == nil && !activeAccount.signature.isEmpty && activeAccount.signatureEnabled ? "<br/> \(activeAccount.signature)" : "")"
        
        fileManager.delegate = self
        if fileManager.registeredFiles.count > 0{
            for file in fileManager.registeredFiles{
                let fileKey = file.fileKey
                guard !fileKey.isEmpty, fileKey.contains(":") else {
                    continue
                }
                let keys = File.getKeyAndIv(key: fileKey)
                fileManager.setEncryption(id: 0, key: keys.0, iv: keys.1)
                break
            }
        } else {
            fileManager.setEncryption(id: 0, key: AESCipher.generateRandomBytes(), iv: AESCipher.generateRandomBytes())
        }
        self.coachMarksController.overlay.allowTap = true
        self.coachMarksController.overlay.color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85)
        self.coachMarksController.dataSource = self
        
        fromMenuView.delegate = self
        setFrom(account: activeAccount)
        
        applyTheme()
    }
    
    func setFrom(account: Account) {
        let accounts = DBManager.getAccounts(ignore: account.username)
        fromButton.isHidden = accounts.count == 0 || (composerData.threadId != nil && composerData.threadId != composerData.emailDraft?.key.description)
        let emails = Array(accounts.map({$0.email}))
        fromButton.setImage(UIImage(named: "icon-down"), for: .normal)
        fromMenuView.isUserInteractionEnabled = false
        fromMenuView.initialLoad(options: emails)
        activeAccount = account
        
        let attributedFrom = NSMutableAttributedString(string: "From: ", attributes: [.font: Font.bold.size(15)!])
        let attributedEmail = NSAttributedString(string: account.email, attributes: [.font: Font.regular.size(15)!])
        attributedFrom.append(attributedEmail)
        fromField.attributedText = attributedFrom
    }
    
    func applyTheme(){
        let theme = ThemeManager.shared.theme
        self.view.backgroundColor = theme.overallBackground
        toField.setTextColor(theme.mainText)
        toField.tintColor = theme.mainText
        ccField.tintColor = theme.mainText
        ccField.setTextColor(theme.mainText)
        bccField.tintColor = theme.mainText
        bccField.setTextColor(theme.mainText)
        toField.fieldColor = theme.mainText
        ccField.fieldColor = theme.mainText
        bccField.fieldColor = theme.mainText
        toField.backgroundColor = theme.overallBackground
        subjectField.textColor = theme.mainText
        subjectField.textColor = theme.mainText
        subjectField.backgroundColor = theme.overallBackground
        subjectField.textColor = theme.mainText
        scrollView.backgroundColor = theme.overallBackground
        tableView.backgroundColor = theme.overallBackground
        self.view.backgroundColor = theme.overallBackground
        topSeparator.backgroundColor = theme.separator
        bottomSeparator.backgroundColor = theme.separator
        attachmentButtonContainerView.backgroundColor = theme.attachment
        attachmentBarButton.imageView?.tintColor = theme.mainText
        editorView.webView.backgroundColor = theme.overallBackground
        editorView.webView.isOpaque = false
        contactTableView.backgroundColor = theme.overallBackground
        subjectField.attributedPlaceholder = NSAttributedString(string: String.localize("SUBJECT"), attributes: [.foregroundColor: theme.mainText, .font: Font.regular.size(subjectField.minimumFontSize)!])
        self.attachmentButtonContainerView.layer.borderColor = theme.overallBackground.cgColor
        
        fromField.textColor = theme.mainText
        fromField.backgroundColor = theme.overallBackground
        
        fromButton.imageView?.tintColor = theme.markedText
        buttonCollapse.imageView?.tintColor = theme.markedText
    }
    
    @IBAction func didPressFrom(_ sender: Any) {
        fromButton.setImage(UIImage(named: "icon-up"), for: .normal)
        fromMenuView.isUserInteractionEnabled = true
        fromMenuView.toggleMenu(true)
        resignKeyboard()
    }
    
    @objc func onDonePress(_ sender: Any){
        switch(sender as? UIView){
        case toField:
            subjectField.becomeFirstResponder()
        case subjectField:
            let _ = editorView.becomeFirstResponder()
        default:
            break
        }
    }
    
    @IBAction func onDidEndOnExit(_ sender: Any) {
        self.onDonePress(sender)
    }
    
    func setupInitContacts(){
        for contact in composerData.initToContacts {
            addToken(contact.displayName, value: contact.email.lowercased(), to: toField)
        }
        for contact in composerData.initCcContacts {
            addToken(contact.displayName, value: contact.email.lowercased(), to: ccField)
        }
    }
    
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated)
        
        if !self.thumbUpdated {
            self.thumbUpdated = true
        }
        
        self.navigationItem.rightBarButtonItem = (!self.toField.allTokens.isEmpty || !self.ccField.allTokens.isEmpty || !self.bccField.allTokens.isEmpty) ? self.enableSendButton : self.disableSendButton
    }
    
    override func viewDidAppear(_ animated: Bool) {
        IQKeyboardManager.shared.enable = false
        if let popover = popoverToPresent {
            self.presentPopover(popover: popover, height: 205)
            popoverToPresent = nil
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        coachMarksController.stop(immediately: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        IQKeyboardManager.shared.enable = true
    }
    
    func remove(_ attachment:File){
        
        guard let index = fileManager.registeredFiles.firstIndex(where: { (attach) -> Bool in
            return attach == attachment
        }) else {
            //if not found, do nothing
            return
        }
        
        self.removeAttachment(at: IndexPath(row: index, section: 0))
    }
    
    func removeAttachment(at indexPath:IndexPath){
        _ = fileManager.registeredFiles.remove(at: indexPath.row)
        self.toggleAttachmentTable()
        self.tableView.performUpdate({
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
        }, completion: nil)
        
    }
    
    func saveDraft() -> Email {
        if let draft = composerData.emailDraft {
            delegate?.deleteDraft(draftId: draft.key)
            FileUtils.deleteDirectoryFromEmail(account: activeAccount, metadataKey: "\(draft.key)")
            DBManager.deleteDraftInComposer(draft)
        }
        
        self.resignKeyboard()
        
        //create draft
        DBManager.store(fileManager.registeredFiles)
        let draft = Email()
        draft.status = .none
        let bodyWithoutHtml = self.editorView.text.replaceNewLineCharater(separator: " ")
        draft.account = self.activeAccount
        
        let preview = String(bodyWithoutHtml.prefix(100))
        let pattern = "\\s+"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let cleanedPreview = regex.stringByReplacingMatches(in: preview, range: NSMakeRange(0, preview.count), withTemplate: " ")
        
        draft.preview = cleanedPreview
        draft.unread = false
        draft.subject = self.subjectField.text ?? ""
        draft.date = Date()
        draft.key = Int("\(activeAccount.deviceId)\(Int(draft.date.timeIntervalSince1970))")!
        draft.threadId = composerData.threadId ?? "\(draft.key)"
        draft.labels.append(DBManager.getLabel(SystemLabel.draft.id)!)
        draft.files.append(objectsIn: fileManager.registeredFiles)
        draft.fromAddress = "\(activeAccount.name) <\(activeAccount.username)\(Constants.domain)>"
        draft.buildCompoundKey()
        DBManager.store(draft)
        
        FileUtils.saveEmailToFile(email: activeAccount.email, metadataKey: "\(draft.key)", body: self.editorView.html, headers: "")
        
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
        self.fillEmailContacts(emailContacts: &emailContacts, token: CLToken(displayText: "\(activeAccount.username)\(Constants.domain)", context: nil), emailDetail: draft, type: ContactType.from)
        
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
        emailContact.compoundKey = "\(emailDetail.key):\(email):\(type.rawValue)"
        if let contact = DBManager.getContact(email) {
            emailContact.contact = contact
            if(contact.email != "\(activeAccount.username)\(Env.domain)"){
                DBManager.updateScore(contact: contact)
            }
        } else {
            let newContact = Contact()
            newContact.email = email
            newContact.score = 1
            newContact.displayName = token.displayText.contains("@") ? String(token.displayText.split(separator: "@")[0]) : token.displayText
            DBManager.store([newContact], account: activeAccount)
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
        coachMarksController.stop(immediately: true)
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
    
    func collapseCC(_ shouldCollapse: Bool){
        //do not collapse if already collapsed
        if shouldCollapse && self.bccHeightConstraint.constant == 0 {
            return
        }
        //do not expand if already expanded
        if !shouldCollapse && self.bccHeightConstraint.constant > 0 {
            return
        }
        
        if (shouldCollapse) {
            expandedCcSpacing = self.ccHeightConstraint.constant
            expandedBbcSpacing = self.bccHeightConstraint.constant
        }
        
        self.buttonCollapse.setImage(shouldCollapse ? Icon.new_arrow.down.image : Icon.new_arrow.up.image, for: .normal)
        self.bccHeightConstraint.constant = shouldCollapse ? 0 : self.expandedBbcSpacing
        self.ccHeightConstraint.constant = shouldCollapse ? 0 : self.expandedCcSpacing
        
        UIView.animate(withDuration: 0.5, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func toggleInteraction(_ flag:Bool){
        self.navigationItem.rightBarButtonItem = flag ? self.enableSendButton : self.disableSendButton
        
        self.view.isUserInteractionEnabled = flag
        self.navigationController?.navigationBar.layer.zPosition = flag ? 0 : -1
        self.blackBackground.isUserInteractionEnabled = flag
        self.blackBackground.alpha = flag ? 0 : 0.5
    }
    
    //MARK: - IBActions
    @objc func didPressCancel(_ sender: UIBarButtonItem) {
        
        if !self.isEdited {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        guard fileManager.pendingAttachments() else {
            handleExit()
            return
        }
        
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("PENDING_ATTACH")
        popover.initialMessage = String.localize("ATTACH_UPLOADING_DISCARD")
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("YES")
        popover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            weakSelf.fileManager.registeredFiles = weakSelf.fileManager.registeredFiles.filter({$0.requestStatus == .finish})
            weakSelf.tableView.reloadData()
            weakSelf.handleExit()
        }
        self.presentPopover(popover: popover, height: 200)
    }
    
    func handleExit(){
        let theme = ThemeManager.shared.theme
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: String.localize("DISCARD"), style: .destructive) { action in
            APIManager.cancelAllUploads()
            if let draft = self.composerData.emailDraft {
                self.delegate?.deleteDraft(draftId: draft.key)
                DBManager.delete(draft)
            }
            self.dismiss(animated: true, completion: nil)
        })
        sheet.addAction(UIAlertAction(title: String.localize("SAVE_DRAFT"), style: .default) { action in
            APIManager.cancelAllUploads()
            let draft = self.saveDraft()
            self.delegate?.newDraft(draft: draft)
            self.dismiss(animated: true, completion: nil)
        })
        sheet.addAction(UIAlertAction(title: String.localize("CANCEL"), style: .default))
        sheet.view.subviews.first?.subviews.first?.subviews.first?.backgroundColor = theme.background
        sheet.view.tintColor = theme.mainText
        self.present(sheet, animated: true, completion:nil)
    }
    
    @IBAction func didPressSend(_ sender: UIBarButtonItem) {
        self.resignKeyboard()
        guard !fileManager.pendingAttachments() else {
            self.showAlert(nil, message: String.localize("WAIT_ATTACHMENT"), style: .alert)
            return
        }
        self.prepareMail()
    }
    
    func sendMailInMainController(password: String? = nil){
        guard let email = composerData.emailDraft else {
            return
        }
        DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.sent.id], removedLabelIds: [SystemLabel.draft.id])
        DBManager.updateEmail(email, status: Email.Status.sending.rawValue)
        self.dismiss(animated: true){
            self.delegate?.sendMail(email: email, emailBody: self.editorView.html, password: password)
        }
    }
    
    func prepareMail(){
        let draftEmail = saveDraft()
        composerData.emailDraft = draftEmail
        
        let containsNonCriptextEmail = draftEmail.getContacts(type: .to).contains(where: {!$0.email.contains(Constants.domain)}) || draftEmail.getContacts(type: .cc).contains(where: {!$0.email.contains(Constants.domain)}) || draftEmail.getContacts(type: .bcc).contains(where: {!$0.email.contains(Constants.domain)})
        
        guard !(containsNonCriptextEmail && activeAccount.encryptToExternal) else {
            self.presentPopover()
            return
        }
        
        self.toggleInteraction(false)
        sendMailInMainController()
    }
    
    func presentPopover(){
        let setPassPopover = EmailSetPasswordViewController()
        setPassPopover.delegate = self
        setPassPopover.preferredContentSize = CGSize(width: Constants.popoverWidth, height: PASSWORD_POPUP_HEIGHT)
        setPassPopover.popoverPresentationController?.sourceView = self.view
        setPassPopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        setPassPopover.popoverPresentationController?.permittedArrowDirections = []
        setPassPopover.popoverPresentationController?.backgroundColor = ThemeManager.shared.theme.overallBackground
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
        guard fileManager.registeredFiles.count < 5 else {
            self.showAlert(String.localize("ATTACHMENT_CAP"), message: String.localize("ATTACHMENT_CAP_SIZE"), style: .alert)
            return
        }
        self.showAttachmentDrawer(true)
    }
    
    @IBAction func didPressAttachmentLibrary(_ sender: UIButton) {
        PHPhotoLibrary.requestAuthorization({ (status) in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    let picker = TLPhotosPickerViewController()
                    picker.delegate = self
                    var configure = TLPhotosPickerConfigure()
                    configure.allowedVideoRecording = false
                    picker.configure = configure
                    self.present(picker, animated: true, completion: nil)
                    break
                default:
                    self.showAlert(String.localize("ACCESS_DENIED"), message: String.localize("NEED_ENABLE_ACCESS"), style: .alert)
                    break
                }
            }
        })
    }
    
    @IBAction func didPressAttachmentCamera(_ sender: UIButton) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
            DispatchQueue.main.async {
                if !granted {
                    self.showAlert(String.localize("ACCESS_DENIED"), message:String.localize("NEED_ENABLE_ACCESS"), style: .alert)
                    return
                }
                self.imagePicker.presentCameraPicker(from: self)
            }
        })
    }
    
    @IBAction func didPressAttachmentDocuments(_ sender: UIButton) {
        let providerList = UIDocumentPickerViewController(documentTypes: ["public.content", "public.data"], in: .import)
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
        
        let currentDate = Date().timeIntervalSince1970
        guard let data = image.jpegData(compressionQuality: 0.6) else {
            return
        }
        
        imagePicker.dismiss(animated: true){
            let filename = "Criptext_Image_\(currentDate).png"
            let mimeType = "image/png"
            
            let fileURL = CriptextFileManager.getURLForFile(name: filename)
            try! data.write(to: fileURL)
            
            self.isEdited = true
            self.fileManager.registerFile(filepath: fileURL.path, name: filename, mimeType: mimeType)
            self.tableView.performUpdate({
                self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
            }, completion: nil)
            self.toggleAttachmentTable()
        }
    }
}

//MARK: - Document Handler Delegate
extension ComposeViewController: UIDocumentPickerDelegate {
    
    func documentMenu(didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        //show document picker
        documentPicker.delegate = self;
        
        documentPicker.popoverPresentationController?.sourceView = self.view
        documentPicker.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        
        let filename = url.lastPathComponent
        self.isEdited = true
        self.fileManager.registerFile(filepath: url.path, name: filename, mimeType: File.mimeTypeForPath(path: filename))
        self.tableView.performUpdate({
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        }, completion: nil)
        self.toggleAttachmentTable()
    }
}

extension ComposeViewController: EmailSetPasswordDelegate {
    func setPassword(active: Bool, password: String?) {
        self.toggleInteraction(false)
        sendMailInMainController(password: password)
    }
}

//MARK: - Keyboard handler
extension ComposeViewController{
    // 3
    // Add a gesture on the view controller to close keyboard when tapped
    func enableKeyboardHideOnTap(){
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil) // See 4.1
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil) //See 4.2
    }
    
    //3.1
    @objc func hideKeyboard() {
        composerKeyboardOffset = 0.0
        self.editorHeightConstraint.constant = composerEditorHeight
        self.view.endEditing(true)
    }
    
    //4.1
    @objc func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame: CGRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        var marginBottom: CGFloat = 0.0
        if #available(iOS 11.0, *),
            let window = UIApplication.shared.keyWindow {
            marginBottom = window.safeAreaInsets.bottom
        }
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: duration) { () -> Void in
            self.toolbarBottomConstraint.constant = keyboardFrame.size.height - marginBottom
            self.view.layoutIfNeeded()
        }
        composerKeyboardOffset = keyboardFrame.size.height - marginBottom
        self.editorHeightConstraint.constant = composerEditorHeight + composerKeyboardOffset
    }
    
    //4.2
    @objc func keyboardWillHide(notification: NSNotification) {
        let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: duration) { () -> Void in
            self.toolbarBottomConstraint.constant = self.toolbarBottomConstraintInitialValue!
            self.view.layoutIfNeeded()
            
        }
        
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
            UIUtils.setProfilePictureImage(imageView: cell.avatarImageView, contact: contact)
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
        
        cell.typeImageView.image = UIUtils.getImageByFileType(attachment.mimeType)
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
            
            self.addToken(contact.displayName, value: contact.email.lowercased(), to: focusInput)
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
    }
    
    func tableViewCellDidTap(_ cell: AttachmentTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else {
            return
        }
        fileManager.registerFile(file: fileManager.registeredFiles[indexPath.row], uploading: true)
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
        guard let input = text else {
            return
        }
        
        if input.contains(",") || input.contains(" ") {
            let name = input.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")
            
            guard name.contains("@") else {
                addToken("\(name)\(Constants.domain)", value: "\(name)\(Constants.domain)".lowercased(), to: view)
                return
            }
            if Utils.validateEmail(name) {
                addToken(name, value: name.lowercased(), to: view)
            } else {
                self.showAlert(String.localize("BAD_RECIPIENT"), message: String.localize("ENTER_VALID_EMAIL"), style: .alert)
            }
        }
        
        self.contactTableView.isHidden = (view.text?.isEmpty)!
        self.toolbarHeightConstraint.constant = (view.text?.isEmpty)! ? self.toolbarHeightConstraintInitialValue! : 0
        self.toolbarView.isHidden = (view.text?.isEmpty)! ? false : true
        
        if !(text?.isEmpty)! {
            composerData.contactArray = DBManager.getContacts(text ?? "", account: self.activeAccount)
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
        self.navigationItem.rightBarButtonItem = (!self.toField.allTokens.isEmpty || !self.ccField.allTokens.isEmpty || !self.bccField.allTokens.isEmpty) ? self.enableSendButton : self.disableSendButton
        self.contactTableView.isHidden = true
        
        guard let text = view.text, text.count > 0 else {
            return
        }
        
        guard text.contains("@") else {
            addToken("\(text)\(Constants.domain)", value: "\(text)\(Constants.domain)".lowercased(), to: view)
            return
        }
        if Utils.validateEmail(text) {
            addToken(text, value: text.lowercased(), to: view)
        } else {
            self.showAlert(String.localize("BAD_RECIPIENT"), message: String.localize("ENTER_VALID_EMAIL"), style: .alert)
        }
    }
    
    func tokenInputView(_ view: CLTokenInputView, didRemove token: CLToken) {
        self.navigationItem.rightBarButtonItem = (!self.toField.allTokens.isEmpty || !self.ccField.allTokens.isEmpty || !self.bccField.allTokens.isEmpty) ? self.enableSendButton : self.disableSendButton
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
    
    func tokenInputViewShouldReturn(_ view: CLTokenInputView) -> Bool {
        switch(view){
        case toField:
            if(self.bccHeightConstraint.constant == 0){
                subjectField.becomeFirstResponder()
                break
            }
            ccField.beginEditing()
        case ccField:
            bccField.beginEditing()
        default:
            subjectField.becomeFirstResponder()
        }
        return false
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
        
        self.addToken(email, value: email.lowercased(), to: tokenInputView)
    }
    
    func addToken(_ display:String, value:String, to view:CLTokenInputView){
        let theme = ThemeManager.shared.theme
        guard ccField.allTokens.count + bccField.allTokens.count + toField.allTokens.count < 300 else {
            self.showAlert(String.localize("RECIPIENTS_CAP"), message: String.localize("RECIPIENTS_CAP_SIZE"), style: .alert)
            return
        }
        guard value.contains("@") else {
            let textColor = UIColor(red: 0, green:0.23, blue: 0.41, alpha: 1.0)
            let bgColor = UIColor(red: 0.90, green:0.96, blue: 1.0, alpha: 1.0)
            let valueObject = NSString(string: "\(value)\(Constants.domain)")
            let token = CLToken(displayText: "\(value)\(Constants.domain)", context: valueObject)
            view.add(token, highlight: textColor, background: bgColor)
            return
        }
        guard Utils.validateEmail(value) else {
            self.showAlert(String.localize("BAD_RECIPIENT"), message: String.localize("ENTER_VALID_EMAIL"), style: .alert)
            return
        }
        let textColor = value.contains(Constants.domain) ? theme.emailBubbleCriptext : theme.emailBubble
        let bgColor = value.contains(Constants.domain) ? theme.bgBubbleCriptext : theme.bgBubble
        let valueObject = NSString(string: value)
        let token = CLToken(displayText: display, context: valueObject)
        view.add(token, highlight: textColor, background: bgColor)
        
        self.navigationItem.rightBarButtonItem = (!self.toField.allTokens.isEmpty || !self.ccField.allTokens.isEmpty || !self.bccField.allTokens.isEmpty) ? self.enableSendButton : self.disableSendButton
    }
}

extension ComposeViewController: CriptextFileDelegate {
    func fileError(message: String) {
        self.tableView.reloadData()
        let alertPopover = GenericAlertUIPopover()
        alertPopover.myTitle = String.localize("LARGE_FILE")
        alertPopover.myMessage = message
        if presentedViewController == nil {
            self.presentPopover(popover: alertPopover, height: 205)
        } else {
            self.popoverToPresent = alertPopover
        }
    }
    
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
        guard let index = fileManager.registeredFiles.firstIndex(where: {$0.token == file.token}),
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
        
        composerEditorHeight = cgheight
        self.editorHeightConstraint.constant = cgheight + composerKeyboardOffset
    }
    
    func richEditor(_ editor: RichEditorView, contentDidChange content: String) {
        guard !self.isEdited else {
            return
        }
        if(!content.isEmpty && !activeAccount.signatureEnabled){
            self.isEdited = true
        }
        let signature = activeAccount.signature
        if(!content.isEmpty && !content.replacingOccurrences(of: "<br/> \(signature)", with: "").replacingOccurrences(of: "<br> \(signature)", with: "").isEmpty){
            self.isEdited = true
        }
    }
    
    func richEditorDidLoad(_ editor: RichEditorView) {
        self.editorView.replace(font: "NunitoSans-Regular", css: "editor-style")
        let hasInitialContacts = composerData.initToContacts.count > 0 || composerData.initCcContacts.count > 0
        if(hasInitialContacts){
            self.setupInitContacts()
        }
        if(!hasInitialContacts){
            toField.beginEditing()
        } else if(!composerData.initSubject.isEmpty){
            editorView.focus(at: CGPoint(x: 0.0, y: 0.0))
        } else {
            subjectField.becomeFirstResponder()
        }
        let theme = ThemeManager.shared.theme
        editorView.setEditorFontColor(theme.mainText)
        editorView.setEditorBackgroundColor(theme.overallBackground)
    }
    
    func richEditorTookFocus(_ editor: RichEditorView) {
        self.collapseCC(true)
        let defaults = CriptextDefaults()
        if !defaults.guideAttachments {
            let presentationContext = PresentationContext.viewController(self)
            self.coachMarksController.start(in: presentationContext)
            defaults.guideAttachments = true
        }
    }
}

extension ComposeViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let hintView = HintUIView()
        hintView.messageLabel.text = String.localize("ADD_ATTACHMENT")
        hintView.rightConstraint.constant = 80
        hintView.topCenterConstraint.constant = 27
        
        return (bodyView: hintView, arrowView: nil)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        var coachMark = coachMarksController.helper.makeCoachMark(for: attachmentButtonContainerView){
            (frame: CGRect) -> UIBezierPath in
            return UIBezierPath(ovalIn: frame.insetBy(dx: -4, dy: -4))
        }
        coachMark.allowTouchInsideCutoutPath = true
        return coachMark
    }
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
}


extension ComposeViewController: TLPhotosPickerViewControllerDelegate {
    func dismissPhotoPicker(withTLPHAssets: [TLPHAsset]) {
        for asset in withTLPHAssets {
            switch(asset.type) {
            case .photo, .livePhoto:
                asset.tempCopyMediaFile(videoRequestOptions: nil, imageRequestOptions: nil, exportPreset: AVAssetExportPresetMediumQuality, convertLivePhotosToJPG: true, progressBlock: nil) { (url, mimeType) in
                    DispatchQueue.main.async {
                        let filename = url.absoluteString.split(separator: "/").last?.description ?? asset.originalFileName ?? "Unknown"
                        self.handleAssetResult(name: filename, url: url, mimeType: mimeType)
                    }
                }
            case .video:
                asset.exportVideoFile(completionBlock: { (url, mimeType) in
                    DispatchQueue.main.async {
                        self.handleAssetResult(name: asset.originalFileName ?? "Unknown", url: url, mimeType: mimeType)
                    }
                })
            }
        }
    }
    
    func handleAssetResult(name: String, url: URL, mimeType: String) {
        guard self.fileManager.registerFile(filepath: url.path, name: name, mimeType: mimeType) else {
            self.toggleAttachmentTable()
            return
        }
        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        self.toggleAttachmentTable()
    }
}

extension ComposeViewController: BottomMenuDelegate {
    func didPressOption(_ option: String) {
        let accountId = option.replacingOccurrences(of: Env.domain, with: "")
        guard let account = DBManager.getAccountById(accountId) else {
            return
        }
        self.setFrom(account: account)
    }
    
    func didPressBackground() {
        fromMenuView.isUserInteractionEnabled = false
        self.fromButton.setImage(UIImage(named: "icon-down"), for: .normal)
        self.fromMenuView.toggleMenu(false)
    }
}
