//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Pedro on 11/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import UIKit
import Social
import RichEditorView
import CLTokenInputView
import RealmSwift
import MobileCoreServices

class ShareViewController: UIViewController {
    
    let PASSWORD_POPUP_HEIGHT = 295
    
    @IBOutlet weak var composerUIView: ComposerUIView!
    var account: Account?
    var myAccount: Account!
    var fileManager = CriptextFileManager()
    var emailDraft: Email?
    var contacts = [Contact]()
    
    override func viewDidLoad() {
        configRealm()
        getAccount()
        composerUIView.initialLoad()
        composerUIView.delegate = self
        composerUIView.attachmentsTableView.delegate = self
        composerUIView.attachmentsTableView.dataSource = self
        composerUIView.contactsTableView.delegate = self
        composerUIView.contactsTableView.dataSource = self
        let nib = UINib(nibName: "AttachmentTableViewCell", bundle: nil)
        composerUIView.attachmentsTableView.register(nib, forCellReuseIdentifier: "attachmentCell")
        fileManager.token = myAccount.jwt
        fileManager.delegate = self
        fileManager.setEncryption(id: 0, key: AESCipher.generateRandomBytes(), iv: AESCipher.generateRandomBytes())
        self.handleExtensionItems()
    }
    
    func handleExtensionItems() {
        let contentTypeUrl = kUTTypeURL as String
        let contentTypeImage = kUTTypeImage as String
        let contentTypeText = kUTTypePlainText as String
        let contentTypeFileUrl = kUTTypeFileURL as String
        
        guard let items = self.extensionContext?.inputItems else {
            return
        }
        for item in items {
            guard let extensionItem = item as? NSExtensionItem,
                let attachments = extensionItem.attachments else {
                continue
            }
            for provider in attachments {
                if (provider.hasItemConformingToTypeIdentifier(contentTypeImage)) {
                    provider.loadItem(forTypeIdentifier: contentTypeImage, options: nil) { (it, error) in
                        guard let url = it as? URL else {
                            return
                        }
                        DispatchQueue.main.async {
                            self.addFile(url: url)
                        }
                    }
                } else if (provider.hasItemConformingToTypeIdentifier(contentTypeText)) {
                    provider.loadItem(forTypeIdentifier: contentTypeText, options: nil) { (it, error) in
                        guard let text = it as? String else {
                            return
                        }
                        DispatchQueue.main.async {
                            self.composerUIView.addToContent(text: text)
                        }
                    }
                } else if (provider.hasItemConformingToTypeIdentifier(contentTypeFileUrl)) {
                    provider.loadItem(forTypeIdentifier: contentTypeFileUrl, options: nil) { (it, error) in
                        guard let url = it as? URL else {
                            return
                        }
                        DispatchQueue.main.async {
                            self.addFile(url: url)
                        }
                    }
                } else if (provider.hasItemConformingToTypeIdentifier(contentTypeUrl)) {
                    provider.loadItem(forTypeIdentifier: contentTypeUrl, options: nil) { (it, error) in
                        guard let url = it as? URL else {
                            return
                        }
                        DispatchQueue.main.async {
                            self.composerUIView.addToContent(text: url.path)
                        }
                    }
                }
            }
        }
    }
    
    func getAccount() {
        guard let groupDefaults = UserDefaults.init(suiteName: Env.groupApp),
            let username = groupDefaults.string(forKey: "activeAccount"),
            let account = SharedDB.getAccountByUsername(username) else {
                self.close()
                return
        }
        myAccount = account
    }
    
    func configRealm() {
        let fileURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Env.groupApp)!.appendingPathComponent("default.realm")
        let config = Realm.Configuration(
            fileURL: fileURL,
            schemaVersion: Env.databaseVersion)
        Realm.Configuration.defaultConfiguration = config
    }
    
    func addFile(url: URL){
        let filename = url.lastPathComponent
        self.fileManager.registerFile(filepath: url.path, name: filename, mimeType: File.mimeTypeForPath(path: filename))
        self.composerUIView.attachmentsTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
        self.composerUIView.resizeAttachmentTable(numberOfAttachments: fileManager.registeredFiles.count)
    }
}

extension ShareViewController: ComposerDelegate {
    func typingRecipient(text: String) {
        contacts = SharedDB.getContacts(text)
        self.composerUIView.contactsTableView.isHidden = contacts.isEmpty
        self.composerUIView.contactsTableView.reloadData()
    }
    
    func send() {
        self.prepareMail()
    }
    
    func close() {
        self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    func badRecipient() {
        let alert = UIAlertController(title: "Invalid Email", message: "\nPlease add a valid email", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Got it!", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

extension ShareViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(tableView){
        case self.composerUIView.contactsTableView:
            return contacts.count
        default:
            return fileManager.registeredFiles.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch(tableView){
        case self.composerUIView.contactsTableView:
            let contact = contacts[indexPath.row]
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
            cell.textLabel?.text = contact.displayName
            cell.detailTextLabel?.text = contact.email
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "attachmentCell", for: indexPath) as! AttachmentTableCell
            cell.setFields(fileManager.registeredFiles[indexPath.row])
            cell.iconDownloadImageView.isHidden = true
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch(tableView){
        case self.composerUIView.contactsTableView:
            return 60.0
        default:
            return 65.0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard tableView == self.composerUIView.contactsTableView else {
            return
        }
        
        let contact = contacts[indexPath.row]
        composerUIView.addContact(name: contact.displayName, email: contact.email)
    }
}

extension ShareViewController: CriptextFileDelegate {
    func uploadProgressUpdate(file: File, progress: Int) {
        guard let attachmentCell = getCellForFile(file) else {
            return
        }
        attachmentCell.markImageView.isHidden = true
        attachmentCell.progressView.isHidden = false
        attachmentCell.progressView.setProgress(Float(progress)/100.0, animated: true)
    }
    
    func finishRequest(file: File, success: Bool) {
        guard let attachmentCell = getCellForFile(file) else {
            return
        }
        attachmentCell.setMarkIcon(success: success)
    }
    
    func getCellForFile(_ file: File) -> AttachmentTableCell? {
        guard let index = fileManager.registeredFiles.index(where: {$0.token == file.token}),
            let cell = self.composerUIView.attachmentsTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? AttachmentTableCell else {
                return nil
        }
        return cell
    }
}


extension ShareViewController {
    
    func prepareMail(){
        
        guard !self.composerUIView.toField.allTokens.isEmpty || !self.composerUIView.ccField.allTokens.isEmpty || !self.composerUIView.bccField.allTokens.isEmpty else {
            let alert = UIAlertController(title: "Invalid Recipients", message: "\nPlease add at least one recipient before sending this email", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Got it!", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let draftEmail = saveDraft()
        self.emailDraft = draftEmail
        
        let containsNonCriptextEmail = draftEmail.getContacts(type: .to).contains(where: {!$0.email.contains(Env.domain)}) || draftEmail.getContacts(type: .cc).contains(where: {!$0.email.contains(Env.domain)}) || draftEmail.getContacts(type: .bcc).contains(where: {!$0.email.contains(Env.domain)})
        
        guard !containsNonCriptextEmail else {
            presentPopover()
            return
        }
        updateAndMail()
    }
    
    func presentPopover(){
        let setPassPopover = EmailSetPasswordViewController()
        setPassPopover.delegate = self
        setPassPopover.preferredContentSize = CGSize(width: Constants.popoverWidth, height: PASSWORD_POPUP_HEIGHT)
        setPassPopover.popoverPresentationController?.sourceView = self.view
        setPassPopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        setPassPopover.popoverPresentationController?.permittedArrowDirections = []
        setPassPopover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(setPassPopover, animated: true)
    }
    
    func saveDraft() -> Email {
        if let draft = emailDraft {
            SharedDB.deleteDraftInComposer(draft)
        }
        
        //create draft
        SharedDB.store(fileManager.registeredFiles)
        let draft = Email()
        draft.status = .none
        draft.content = self.composerUIView.editorView.html
        let bodyWithoutHtml = self.composerUIView.getPlainEditorContent()
        draft.preview = String(bodyWithoutHtml.prefix(100))
        draft.unread = false
        draft.subject = self.composerUIView.subjectTextField.text ?? ""
        draft.date = Date()
        draft.key = Int("\(myAccount.deviceId)\(Int(draft.date.timeIntervalSince1970))")!
        draft.threadId = "\(draft.key)"
        draft.labels.append(SharedDB.getLabel(SystemLabel.draft.id)!)
        draft.files.append(objectsIn: fileManager.registeredFiles)
        SharedDB.store(draft)
        
        if fileManager.encryption && !fileManager.registeredFiles.isEmpty,
            let keys = fileManager.keyPairs[0] {
            let fileKey = FileKey()
            fileKey.key = FileKey.getKeyCodedString(key: keys.0, iv: keys.1)
            fileKey.emailId = draft.key
            SharedDB.store([fileKey])
        }
        
        //create email contacts
        var emailContacts = [EmailContact]()
        self.composerUIView.toField.allTokens.forEach { (token) in
            self.fillEmailContacts(emailContacts: &emailContacts, token: token, emailDetail: draft, type: ContactType.to)
        }
        self.composerUIView.ccField.allTokens.forEach { (token) in
            self.fillEmailContacts(emailContacts: &emailContacts, token: token, emailDetail: draft, type: ContactType.cc)
        }
        self.composerUIView.bccField.allTokens.forEach { (token) in
            self.fillEmailContacts(emailContacts: &emailContacts, token: token, emailDetail: draft, type: ContactType.bcc)
        }
        self.fillEmailContacts(emailContacts: &emailContacts, token: CLToken(displayText: "\(myAccount.username)\(Env.domain)", context: nil), emailDetail: draft, type: ContactType.from)
        
        SharedDB.store(emailContacts)
        
        return draft
    }
    
    func fillEmailContacts(emailContacts: inout Array<EmailContact>, token: CLToken, emailDetail: Email, type: ContactType){
        let email = getEmailFromToken(token)
        let emailContact = EmailContact()
        emailContact.email = emailDetail
        emailContact.type = type.rawValue
        emailContact.compoundKey = "\(emailDetail.key):\(email):\(type.rawValue)"
        if let contact = SharedDB.getContact(email) {
            emailContact.contact = contact
        } else {
            let newContact = Contact()
            newContact.email = email
            newContact.displayName = token.displayText.contains("@") ? String(token.displayText.split(separator: "@")[0]) : token.displayText
            SharedDB.store([newContact]);
            emailContact.contact = newContact
        }
        emailContacts.append(emailContact)
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
    
    func updateAndMail(secure: Bool = true, password: String? = nil){
        guard let email = emailDraft else {
            return
        }
        SharedDB.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.sent.id], removedLabelIds: [SystemLabel.draft.id])
        SharedDB.updateEmail(email, status: Email.Status.sending.rawValue)
        SharedDB.updateEmail(email, secure: secure)
        sendMail(email: email, password: password)
    }
    
    func sendMail(email: Email, password: String?) {
        let alert = UIAlertController(title: nil, message: "Sending Email...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.style = UIActivityIndicatorView.Style.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        
        let sendMailAsyncTask = SendMailAsyncTask(account: myAccount, email: email, password: password)
        sendMailAsyncTask.start { [weak self] responseData in
            guard let weakSelf = self else {
                alert.dismiss(animated: true, completion: nil)
                return
            }
            guard case .SuccessInt = responseData else {
                alert.dismiss(animated: true, completion: { [weak self] in
                    let alert = UIAlertController(title: "Unable to send email", message: "\nPlease check your internet connection and try again", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Got it!", style: .cancel, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                })
                return
            }
            weakSelf.close()
        }
    }
}

extension ShareViewController: EmailSetPasswordDelegate {
    func setPassword(active: Bool, password: String?) {
        updateAndMail(secure: active, password: password)
    }
}
