//
//  EmailDetailViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/27/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//
import Material
import Foundation
import Photos
import SafariServices
import Instructions
import RealmSwift

class EmailDetailViewController: UIViewController {
    let ESTIMATED_ROW_HEIGHT : CGFloat = 77
    let ESTIMATED_SECTION_HEADER_HEIGHT : CGFloat = 50
    let CONTACTS_BASE_HEIGHT = 56
    let CONTACTS_MAX_HEIGHT: CGFloat = 300.0
    let CONTACTS_ROW_HEIGHT = 28
    
    var collapseUntilIndex = 0
    var isExpanded = false
    var emailData : EmailDetailData!
    weak var mailboxData : MailboxData!
    weak var myAccount: Account!
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var emailsTableView: UITableView!
    @IBOutlet weak var topToolbar: TopbarUIView!
    @IBOutlet weak var generalOptionsContainerView: MoreOptionsUIView!
    
    weak var myHeaderView : UIView?
    weak var target: UIView?
    var emailDetailOptionsInterface: EmailDetailOptionsInterface?
    var emailMoreOptionsInterface: EmailMoreOptionsInterface?
    var emailDetailContentOptionsInterface: EmailDetailContentOptionsInterface?
    let fileManager = CriptextFileManager()
    let coachMarksController = CoachMarksController()
    
    var message: ControllerMessage?
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webView.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        self.setupToolbar()
        self.setupTableView()
        
        self.registerCellNibs()
        self.topToolbar.delegate = self
        fileManager.delegate = self
        fileManager.myAccount = myAccount
        
        displayMarkIcon(asRead: false)
        
        self.coachMarksController.overlay.allowTap = true
        self.coachMarksController.overlay.color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85)
        self.coachMarksController.dataSource = self
        
        calculateCollapse()
        
        emailData.observerToken = emailData.emails.observe { [weak self] changes in
            guard let tableView = self?.emailsTableView else {
                return
            }
            guard let weakSelf = self else {
                return
            }
            switch(changes){
            case .initial:
                tableView.reloadData()
            case .update(_, let deletions, let insertions, _):
                insertions.forEach({ (position) in
                    let email = weakSelf.emailData.emails[position]
                    guard let myAccount = weakSelf.myAccount else {
                        return
                    }
                    if(weakSelf.emailData.bodies[email.key] == nil){
                        weakSelf.emailData.bodies[email.key] = FileUtils.getBodyFromFile(account: myAccount, metadataKey: "\(email.key)")
                    }
                })
                if deletions.count > 0 {
                    weakSelf.calculateCollapse()
                }
                weakSelf.emailData.rebuildLabels()
                (weakSelf.myHeaderView as? EmailDetailHeaderCell)?.addLabels(weakSelf.emailData.labels)
                tableView.reloadData()
                let hasNewInboxEmail = insertions.contains(where: { (position) -> Bool in
                    let email = weakSelf.emailData.emails[position]
                    return email.labels.contains(where: {$0.id == SystemLabel.inbox.id})
                })
                if (hasNewInboxEmail) {
                    weakSelf.showSnackbar(String.localize("HAVE_NEW_EMAIL"), attributedText: nil, buttons: "", permanent: false)
                }
            default:
                break
            }
            
            if(weakSelf.emailData.emails.isEmpty){
                weakSelf.mailboxData.removeSelectedRow = true
                weakSelf.navigationController?.popViewController(animated: true)
            }
        }
        applyTheme()
    }
    
    func calculateCollapse() {
        guard !isExpanded else {
            return
        }
        collapseUntilIndex = 0
        for (index, email) in emailData.emails.enumerated() {
            guard emailData.emails.count >= 4,
                index > 1,
                let state = emailData.emailStates[email.key] else {
                    continue
            }
            if !state.isExpanded {
                collapseUntilIndex = index
            }
        }
        if collapseUntilIndex == emailData.emails.count - 1,
            let lastEmail = emailData.emails.last {
            emailData.emailStates[lastEmail.key]?.isExpanded = true
            collapseUntilIndex -= 1
            if collapseUntilIndex < 2 {
                collapseUntilIndex = 0
            }
        }
        isExpanded = collapseUntilIndex == 0
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.topToolbar.isHidden = true
        self.coachMarksController.stop(immediately: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.topToolbar.swapTrashIcon(labelId: emailData.selectedLabel)
        self.topToolbar.isHidden = false
        let defaults = CriptextDefaults()
        if !defaults.guideUnsend,
            let email = emailData.emails.first,
            email.isSent && emailData.getState(email.key).isExpanded && emailData.emails.count == 1 {
            let presentationContext = PresentationContext.viewController(self)
            self.coachMarksController.start(in: presentationContext)
            defaults.guideUnsend = true
        }
        
        handleControllerMessage(message)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        emailData.observerToken?.invalidate()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        self.view.backgroundColor = theme.background
        self.emailsTableView.backgroundColor = theme.background
        self.emailsTableView.reloadData()
    }
    
    func handleControllerMessage(_ message: ControllerMessage?) {
        guard let controllerMessage = message else {
            return
        }
        switch(controllerMessage){
        case .ReplyThread(let emailKey):
            guard let index = emailData.emails.firstIndex(where: {$0.key == emailKey}) else {
                break
            }
            emailsTableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
            onReplyPress()
        default:
            break
        }
        self.message = nil
    }
    
    func setupToolbar(){
        self.navigationController?.navigationBar.addSubview(self.topToolbar)
        let margins = self.navigationController!.navigationBar.layoutMarginsGuide
        self.topToolbar.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: -8.0).isActive = true
        self.topToolbar.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 8.0).isActive = true
        self.topToolbar.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: 8.0).isActive = true
        self.navigationController?.navigationBar.bringSubviewToFront(self.topToolbar)
        self.topToolbar.isHidden = true
        
        let cancelButton = UIUtils.createLeftBackButton(target: self)
        let cancelBarButton = UIBarButtonItem(customView: cancelButton)
        self.navigationItem.leftBarButtonItem = cancelBarButton
    }
    
    func setupTableView(){
        emailsTableView.sectionHeaderHeight = UITableView.automaticDimension;
        emailsTableView.estimatedSectionHeaderHeight = ESTIMATED_SECTION_HEADER_HEIGHT;
    }
    
    func registerCellNibs(){
        let headerNib = UINib(nibName: "EmailTableHeaderView", bundle: nil)
        self.emailsTableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "emailTableHeaderView")
        let footerNib = UINib(nibName: "EmailTableFooterView", bundle: nil)
        self.emailsTableView.register(footerNib, forHeaderFooterViewReuseIdentifier: "emailTableFooterView")
        for email in self.emailData.emails {
            let nib = UINib(nibName: "EmailDetailTableCell", bundle: nil)
            self.emailsTableView.register(nib, forCellReuseIdentifier: "emailDetail\(email.key)")
        }
    }
    
    func displayMarkIcon(asRead: Bool){
        topToolbar.swapMarkTo(unread: !asRead)
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        let email = getMail(index: indexPath.row)
        return emailData.getState(email.key).cellHeight < ESTIMATED_ROW_HEIGHT ? ESTIMATED_ROW_HEIGHT : emailData.getState(email.key).cellHeight
    }
    
    func reportContact(type: ContactUtils.ReportType){
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleGeneralOptionsView()
            return
        }
        self.toggleGeneralOptionsView()
        let isSpam = emailData.selectedLabel == SystemLabel.spam.id
        let isTrash = emailData.selectedLabel == SystemLabel.trash.id
        let removeLabel = isSpam ? [SystemLabel.spam.id] : isTrash ? [SystemLabel.trash.id] : []
        let addLabel = isSpam ? [] : [SystemLabel.spam.id]
        let email = getMail(index: indexPath.row)
        let emailKey = email.key
        
        let changedLabels = getLabelNames(added: addLabel, removed: removeLabel)
        if(email.fromContact.email != self.myAccount.email) {
            if(addLabel.contains(SystemLabel.spam.id)){
                DBManager.uptickSpamCounter(email.fromContact)
                var data: String? = nil
                if(type == ContactUtils.ReportType.phishing){
                    if(email.boundary != ""){
                        data = FileUtils.getHeaderFromFile(account: myAccount, metadataKey: "\(email.key)")
                    } else {
                        data = email.content
                    }
                }
                APIManager.postReportContact(emails: [email.fromContact.email], type: type, data: data, token: self.myAccount.jwt, completion:{_ in })
            } else if (removeLabel.contains(SystemLabel.spam.id)) {
                DBManager.resetSpamCounter(email.fromContact)
                APIManager.postReportContact(emails: [email.fromContact.email], type: ContactUtils.ReportType.notSpam, data: nil, token: self.myAccount.jwt, completion:{_ in })
            }
        }
        DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: addLabel, removedLabelIds: removeLabel)
        let eventData = EventData.Peer.EmailLabels(metadataKeys: [emailKey], labelsAdded: changedLabels.0, labelsRemoved: changedLabels.1)
        DBManager.createQueueItem(params: ["cmd": Event.Peer.emailsLabels.rawValue, "params": eventData.asDictionary()], account: myAccount)
    }
}

extension EmailDetailViewController: UITableViewDelegate, UITableViewDataSource{

    func getMail(index: Int) -> Email {
        let trueIndex = index == 0 ? 0 : index + collapseUntilIndex 
        return emailData.emails[trueIndex]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let email = getMail(index: indexPath.row)
        let cell = reuseOrCreateCell(identifier: "emailDetail\(email.key)") as! EmailTableViewCell
        let body = self.emailData.bodies[email.key] ?? ""
        let emailBody = body.isEmpty ? (email.isUnsent ? Constants.contentUnsent(email.getPreview()) : Constants.contentEmpty) : body
        cell.setContent(email, emailBody: emailBody, state: emailData.getState(email.key), myEmail: emailData.accountEmail)
        cell.delegate = self
        target = cell.moreOptionsContainerView
        guard !isExpanded,
            indexPath.row == 0 || indexPath.row == 1 else {
            cell.hideCollapse()
            return cell
        }
        cell.counterLabelUp.text = "\(collapseUntilIndex)"
        cell.counterLabelDown.text = "\(collapseUntilIndex)"
        if(indexPath.row == 0){
            cell.showBottomCollapse()
            return cell
        }else{
            cell.showTopCollapse()
            return cell
        }
    }
    
    func reuseOrCreateCell(identifier: String) -> UITableViewCell {
        guard let cell = emailsTableView.dequeueReusableCell(withIdentifier: identifier) else {
            let nib = UINib(nibName: "EmailDetailTableCell", bundle: nil)
            emailsTableView.register(nib, forCellReuseIdentifier: identifier)
            return reuseOrCreateCell(identifier: identifier)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emailData.emails.count - collapseUntilIndex
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard myHeaderView == nil else {
            return myHeaderView
        }
        let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "emailTableHeaderView") as! EmailDetailHeaderCell
        headerView.addLabels(emailData.labels)
        headerView.setSubject(emailData.subject)
        headerView.onStarPressed = { [weak self] in
            self?.onStarPressed()
        }
        myHeaderView = headerView
        return myHeaderView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "emailTableFooterView") as! EmailDetailFooterCell
        footerView.delegate = self
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 78.0
    }
}

extension EmailDetailViewController: EmailTableViewCellDelegate {
    
    func tableViewDeleteDraft(email: Email) {
        DBManager.delete(email)
    }
    
    func tableViewExpandViews() {
        isExpanded = true
        collapseUntilIndex = 0
        emailsTableView.reloadData()
    }
    
    func tableViewCellDidTapEmail(email: String) {
        var contact: Contact
        if let existingContact = DBManager.getContact(email) {
            contact = existingContact
        } else {
            contact = Contact()
            contact.email = email
            contact.displayName = String(email.split(separator: "@").first!)
            DBManager.store([contact], account: self.myAccount)
        }
        presentComposer(contactsTo: [contact])
    }
    
    func tableViewCellDidTapLink(url: String) {
        if (myAccount.customerType != Account.CustomerType.enterprise.id && url == Constants.adminUrl) {
            joinPlus()
            return
        }
        guard emailData.selectedLabel != SystemLabel.spam.id else {
            return
        }
        openUrl(url: url)
    }
    
    func openUrl(url: String) {
        let svc = SFSafariViewController(url: URL(string: url)!)
        self.present(svc, animated: true, completion: nil)
    }
    
    func joinPlus() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let webviewVC = storyboard.instantiateViewController(withIdentifier: "membershipViewController") as! MembershipWebViewController
        webviewVC.delegate = self
        webviewVC.initialTitle = Constants.isPlus(customerType: myAccount.customerType) ? String.localize("BILLING") : String.localize("JOIN_PLUS")
        webviewVC.accountJWT = self.myAccount.jwt
        self.navigationController?.pushViewController(webviewVC, animated: true)
    }
    
    func tableViewCellDidChangeHeight(_ height: CGFloat, email: Email) {
        guard !email.isInvalidated else {
            return
        }
        emailData.setState(email.key, cellHeight: height)
        self.emailsTableView.reloadData()
    }
    
    func tableViewCellDidLoadContent(_ cell: EmailTableViewCell, email: Email) {
        self.emailsTableView.reloadData()
    }
    
    func tableViewCellDidTap(_ cell: EmailTableViewCell) {
        guard let indexPath = self.emailsTableView.indexPath(for: cell) else {
            return
        }
        let email = getMail(index: indexPath.row)
        emailData.setState(email.key, isExpanded: !emailData.getState(email.key).isExpanded)
        emailsTableView.reloadData()
    }
    
    func tableViewCellDidTapAttachment(file: File) {
        PHPhotoLibrary.requestAuthorization({ (status) in
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                switch status {
                case .authorized:
                    if(!file.fileKey.isEmpty){
                        let keys = File.getKeyAndIv(key: file.fileKey)
                        weakSelf.fileManager.setEncryption(id: file.emailId, key: keys.0, iv: keys.1)
                    }
                    if let attachmentCell = weakSelf.getCellFromFile(file) {
                        attachmentCell.markImageView.isHidden = true
                        attachmentCell.progressView.isHidden = false
                        attachmentCell.progressView.setProgress(0, animated: false)
                    }
                    weakSelf.fileManager.registerFile(file: file)
                    break
                default:
                    weakSelf.showAlert(String.localize("ACCESS_DENIED"), message: String.localize("NEED_ENABLE_ACCESS"), style: .alert)
                    break
                }
            }
        })
    }
    
    func tableViewCellDidTapIcon(_ cell: EmailTableViewCell, _ sender: UIView, _ iconType: EmailTableViewCell.IconType) {
        switch(iconType){
        case .contacts:
            handleContactsTap(cell, sender)
        case .options:
            handleOptionsTap(cell, sender)
        case .edit:
            handleEditTap(cell, sender)
        }
    }
    
    func handleEditTap(_ cell: EmailTableViewCell, _ sender: UIView){
        guard let indexPath = emailsTableView.indexPath(for: cell) else {
            return
        }
        let email = getMail(index: indexPath.row)
        let contactsTo = Array(email.getContacts(type: .to))
        let contactsCc = Array(email.getContacts(type: .cc))
        presentComposer(email: email, contactsTo: contactsTo, contactsCc: contactsCc, subject: email.subject, content: self.emailData.bodies[email.key] ?? "", blockFrom: true)
    }
    
    func handleContactsTap(_ cell: EmailTableViewCell, _ sender: UIView){
        guard let indexPath = emailsTableView.indexPath(for: cell) else {
            return
        }
        let email = getMail(index: indexPath.row)
        let data = calculateContactsHeight(email: email)
        
        let contactsPopover = ContactsDetailUIPopover()
        contactsPopover.contactHeights = data.0
        contactsPopover.initialFromHeight = data.1
        contactsPopover.initialToHeight = data.2
        contactsPopover.initialCcHeight = data.3
        contactsPopover.initialBccHeight = data.4
        contactsPopover.email = email
        presentPopover(contactsPopover, sender, height: min(CGFloat(CONTACTS_BASE_HEIGHT + Int(data.5)), CONTACTS_MAX_HEIGHT))
    }
    
    func calculateContactsHeight(email: Email) -> ([String: CGFloat], CGFloat, CGFloat, CGFloat, CGFloat, CGFloat) {
        var contactsHeight = [String: CGFloat]()
        var toHeigth: CGFloat = 0.0
        var ccHeigth: CGFloat = 0.0
        var bccHeigth: CGFloat = 0.0
        var sumHeights: CGFloat = 0
        let width = self.view.frame.size.width - 95
        for contact in email.getContacts(type: .to) {
            let height = UIUtils.getLabelHeight("\(contact.displayName) \(contact.email)", width: width, fontSize: 13.0) + 8
            contactsHeight[contact.email] = height
            toHeigth += height
            sumHeights += height
        }
        for contact in email.getContacts(type: .cc) {
            let height = UIUtils.getLabelHeight("\(contact.displayName) \(contact.email)", width: width, fontSize: 13.0) + 8
            contactsHeight[contact.email] = height
            ccHeigth += height
            sumHeights += height
        }
        for contact in email.getContacts(type: .bcc) {
            let height = UIUtils.getLabelHeight("\(contact.displayName) \(contact.email)", width: width, fontSize: 13.0) + 8
            contactsHeight[contact.email] = height
            bccHeigth += height
            sumHeights += height
        }
        
        let myContact = !email.fromAddress.isEmpty ? ContactUtils.getStringEmailName(contact: email.fromAddress) : (email.fromContact.email, email.fromContact.displayName)
        let name = ContactUtils.checkIfFromHasName(email.fromAddress) ? myContact.1 : email.fromContact.displayName
        let emailString = ContactUtils.checkIfFromHasName(email.fromAddress) ? myContact.0 : email.fromContact.email
        let fromHeight = UIUtils.getLabelHeight("\(name) \(emailString)", width: width, fontSize: 13.0) + 8
        sumHeights += fromHeight
        
        return (contactsHeight, fromHeight, toHeigth, ccHeigth, bccHeigth, sumHeights)
    }
    
    func presentPopover(_ popover: UIViewController, _ sender: UIView, height: CGFloat){
        popover.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: height)
        popover.popoverPresentationController?.sourceView = sender
        popover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width/1.0001, height: sender.frame.size.height)
        popover.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        popover.popoverPresentationController?.backgroundColor = theme.overallBackground
        self.present(popover, animated: true, completion: nil)
    }
    
    func handleOptionsTap(_ cell: EmailTableViewCell, _ sender: UIView){
        guard let indexPath = emailsTableView.indexPath(for: cell) else {
            return
        }
        
        emailsTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        let email = getMail(index: indexPath.row)
        let state = emailData.getState(email.key)
        emailMoreOptionsInterface = EmailMoreOptionsInterface(email: email, state: state)
        emailMoreOptionsInterface?.delegate = self
        generalOptionsContainerView.setDelegate(newDelegate: emailMoreOptionsInterface!)
        toggleGeneralOptionsView()
    }
    
    func deselectSelectedRow(){
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            return
        }
        emailsTableView.deselectRow(at: indexPath, animated: false)
    }
    
    @objc func toggleGeneralOptionsView(){
        guard generalOptionsContainerView.isHidden else {
            generalOptionsContainerView.closeMoreOptions()
            return
        }
        generalOptionsContainerView.showMoreOptions()
    }
    
    func tableViewTrustRecipient(cell: EmailTableViewCell, email: Email) {
        guard let indexPath = emailsTableView.indexPath(for: cell) else {
            return
        }
        
        emailsTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        if (email.isSpam) {
            emailDetailContentOptionsInterface = EmailDetailContentOptionsInterface(options: [.once])
        } else if emailData.getState(email.key).trustedOnce {
            emailDetailContentOptionsInterface = EmailDetailContentOptionsInterface(options: [.always, .disable])
        } else {
            emailDetailContentOptionsInterface = EmailDetailContentOptionsInterface()
        }
        emailDetailContentOptionsInterface?.delegate = self
        generalOptionsContainerView.setDelegate(newDelegate: emailDetailContentOptionsInterface!)
        toggleGeneralOptionsView()
    }
    
    func tableViewLearnMore() {
        self.goToUrl(url: "https://criptext.atlassian.net/l/c/10NeN7ZM")
    }
}

extension EmailDetailViewController: MembershipWebViewControllerDelegate {
    func close() {
        self.navigationController?.popViewController(animated: true)
    }
}

extension EmailDetailViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension EmailDetailViewController: EmailDetailFooterDelegate {
    
    func presentComposer(email: Email, contactsTo: [Contact], contactsCc: [Contact], subject: String, content: String, blockFrom: Bool, attachments: [File]? = nil){
        var fromAlias: Alias? = nil
        if (email.isSent) {
            let userDomain = email.fromContact.email.split(separator: "@")
            let username = userDomain[0].description
            let domain = userDomain[1].description == Env.plainDomain ? nil : userDomain[1].description
            if email.fromContact.email != email.account.email,
                let alias = DBManager.getAlias(username: username, domain: domain, account: email.account) {
                fromAlias = alias
            }
        } else {
            let myContact = email.getContacts(emails: [myAccount.email]).first
            if myContact == nil {
                let aliases = DBManager.getAliases(account: myAccount)
                for alias in aliases {
                    let hasAlias = email.getContacts(emails: [alias.email]).first != nil
                    if hasAlias {
                        fromAlias = alias
                        break
                    }
                }
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composerVC = navComposeVC.viewControllers.first as! ComposeViewController
        let composerData = ComposerData()
        if let myAlias = fromAlias {
            composerData.initAlias = myAlias
            composerData.initToContacts.append(contentsOf: contactsTo.filter { $0.email != myAlias.email })
            composerData.initCcContacts.append(contentsOf: contactsCc.filter { $0.email != myAlias.email })
        } else {
            composerData.initToContacts.append(contentsOf: contactsTo)
            composerData.initCcContacts.append(contentsOf: contactsCc)
        }
        composerData.blockFrom = blockFrom
        composerData.initSubject = subject
        composerData.initContent = content
        composerData.threadId = emailData.threadId
        composerData.emailDraft = email.isDraft ? email : nil
        if(email.isDraft){
            for file in email.files {
                file.requestStatus = .finish
                composerVC.fileManager.registeredFiles.append(file)
            }
        } else if let files = attachments {
            for file in files {
                let newFile = file.duplicate()
                newFile.requestStatus = .finish
                composerVC.fileManager.registeredFiles.append(newFile)
            }
        }
        composerVC.delegate = self
        composerVC.composerData = composerData
        self.navigationController?.children.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func presentComposer(contactsTo: [Contact]){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composerVC = navComposeVC.viewControllers.first as! ComposeViewController
        let composerData = ComposerData()
        composerData.initToContacts.append(contentsOf: contactsTo)
        composerVC.delegate = self
        composerVC.composerData = composerData
        self.navigationController?.children.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func onFooterReplyPress() {
        guard let lastIndex = emailData.emails.lastIndex(where: {!$0.isDraft}) else {
            return
        }
        let index = lastIndex == 0 ? 0 : lastIndex - collapseUntilIndex
        emailsTableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        onReplyPress()
    }
    
    func onFooterReplyAllPress() {
        guard let lastIndex = emailData.emails.lastIndex(where: {!$0.isDraft}) else {
            return
        }
        let index = lastIndex == 0 ? 0 : lastIndex - collapseUntilIndex
        emailsTableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        onReplyAllPress()
    }
    
    func onFooterForwardPress() {
        guard let lastIndex = emailData.emails.lastIndex(where: {!$0.isDraft}) else {
            return
        }
        let index = lastIndex == 0 ? 0 : lastIndex - collapseUntilIndex
        emailsTableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        onForwardPress()
    }
}

extension EmailDetailViewController: NavigationToolbarDelegate {
    func onBackPress() {
        if mailboxData.selectedLabel != SystemLabel.all.id,
            !self.emailData.emails.contains(where: {$0.labels.contains(where: {$0.id == mailboxData.selectedLabel})}) {
            mailboxData.removeSelectedRow = true
        }
        self.emailData.observerToken?.invalidate()
        self.emailData.observerToken = nil
        self.navigationController?.popViewController(animated: true)
    }
    
    func onMoveThreads() {
        handleMoveTo()
    }
    
    func onTrashThreads() {
        guard emailData.selectedLabel == SystemLabel.trash.id || emailData.selectedLabel == SystemLabel.spam.id || emailData.selectedLabel == SystemLabel.draft.id else {
            self.setLabels(added: [SystemLabel.trash.id], removed: [], forceRemove: true)
            return
        }
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("DELETE_THREADS")
        popover.initialMessage = String.localize("THESE_DELETED_PERMANENTLY")
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("OK")
        popover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            DBManager.delete(Array(weakSelf.emailData.emails))
            weakSelf.mailboxData.removeSelectedRow = true
            weakSelf.navigationController?.popViewController(animated: true)
            
            let eventData = EventData.Peer.ThreadDeleted(threadIds: [weakSelf.emailData.threadId])
            DBManager.createQueueItem(params: ["cmd": Event.Peer.threadsDeleted.rawValue, "params": eventData.asDictionary()], account: weakSelf.myAccount)
        }
        self.presentPopover(popover: popover, height: 200)
    }
    
    func onMarkThreads() {
        let unread = self.mailboxData.unreadMails <= 0
        for email in self.emailData.emails {
            DBManager.updateEmail(email, unread: true)
        }
        self.navigationController?.popViewController(animated: true)
        
        let params = ["cmd": Event.Peer.threadsUnread.rawValue,
                      "params": [
                        "unread": unread ? 1 : 0,
                        "threadIds": [emailData.threadId]
            ]] as [String : Any]
        DBManager.createQueueItem(params: params, account: myAccount)
    }
    
    func onMoreOptions() {
        emailDetailOptionsInterface = EmailDetailOptionsInterface(currentLabel: emailData.selectedLabel)
        emailDetailOptionsInterface?.delegate = self
        generalOptionsContainerView.setDelegate(newDelegate: emailDetailOptionsInterface!)
        
        toggleGeneralOptionsView()
    }
    
    func archiveThreads(){
        toggleGeneralOptionsView()
        setLabels(added: [], removed: [SystemLabel.inbox.id])
    }
    
    func restoreThreads(){
        toggleGeneralOptionsView()
        setLabels(added: [], removed: [emailData.selectedLabel])
    }
}

extension EmailDetailViewController: EmailContentOptionsDelegate {
    func onOncePress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow,
            let cell = emailsTableView.cellForRow(at: indexPath) as? EmailTableViewCell else {
            self.toggleGeneralOptionsView()
            return
        }
        emailData.setState(cell.email.key, trusted: true)
        cell.enableImages(emailState: emailData.getState(cell.email.key))
        self.toggleGeneralOptionsView()
    }
    
    func onAlwaysPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleGeneralOptionsView()
            return
        }
        let email = emailData.emails[indexPath.row]
        DBManager.update(contact: email.fromContact, isTrusted: true)
        DBManager.refresh()
        
        for visibleCell in emailsTableView.visibleCells {
            guard let cell = visibleCell as? EmailTableViewCell else {
                continue
            }
            if(cell.email.fromContact.email == email.fromContact.email) {
                cell.enableImages(emailState: emailData.getState(cell.email.key))
            }
        }
        
        self.toggleGeneralOptionsView()
        
        let eventData = EventData.Peer.ContactTrust(email: email.fromContact.email, trusted: true)
        let eventParams = ["cmd": Event.Peer.contactTrust.rawValue, "params": eventData.asDictionary()] as [String : Any]
        APIManager.postPeerEvent(["peerEvents": [eventParams]], token: myAccount.jwt) { (responseData) in
            self.showSnackbar(String.localize("BLOCK_CONTENT_CONTACT_TRUSTED", arguments: email.fromContact.displayName), attributedText: nil, buttons: "", permanent: false)
            if case .Success = responseData {
                return
            }
            DBManager.createQueueItem(params: eventParams, account: self.myAccount)
        }
    }
    
    func onDisablePress() {
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("TURN_OFF_REMOTE_TITLE")
        popover.initialMessage = String.localize("TURN_OFF_REMOTE_MESSAGE")
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("SAVE")
        popover.onResponse = { accept in
            guard accept else {
                return
            }
            APIManager.setBlockContent(isOn: false, token: self.myAccount.jwt) { (responseData) in
                self.toggleGeneralOptionsView()
                guard case .Success = responseData else {
                    self.showSnackbar(String.localize("BLOCK_CONTENT_UPDATE_FAILED"), attributedText: nil, buttons: "", permanent: false)
                    return
                }
                self.disableBlockContent()
            }
        }
        self.presentPopover(popover: popover, height: 274)
    }
    
    func disableBlockContent() {
        self.showSnackbar(String.localize("BLOCK_CONTENT_UPDATE_SUCCESS"), attributedText: nil, buttons: "", permanent: false)
        DBManager.update(account: myAccount, blockContent: false)
        DBManager.refresh()
        
        for visibleCell in emailsTableView.visibleCells {
            guard let cell = visibleCell as? EmailTableViewCell else {
                continue
            }
            cell.enableImages(emailState: emailData.getState(cell.email.key))
        }
    }
    
    func onContentOptionsClose() {
        self.toggleGeneralOptionsView()
    }
}

extension EmailDetailViewController: EmailMoreOptionsInterfaceDelegate {
    func onTurnOnLightsPressed() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleGeneralOptionsView()
            return
        }
        generalOptionsContainerView.closeMoreOptions()
        let email = getMail(index: indexPath.row)
        guard let turnedOn = emailData.getState(email.key).hasTurnedOnLights else {
            emailData.setState(email.key, hasLightsOn: true)
            emailsTableView.reloadData()
            return
        }
        emailData.setState(email.key, hasLightsOn: !turnedOn)
        emailsTableView.reloadData()
    }
    
    func onRetryPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleGeneralOptionsView()
            return
        }
        generalOptionsContainerView.closeMoreOptions()
        let email = getMail(index: indexPath.row)
        DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.sent.id], removedLabelIds: [SystemLabel.draft.id])
        DBManager.updateEmail(email, status: Email.Status.sending.rawValue)
        sendMail(email: email, emailBody: self.emailData.bodies[email.key] ?? "", password: nil)
    }
    
    func onReplyPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            generalOptionsContainerView.closeMoreOptions()
            return
        }
        generalOptionsContainerView.closeMoreOptions()
        deselectSelectedRow()
        let email = getMail(index: indexPath.row)
        let fromContact = email.fromContact
        let replyToContact = email.replyTo.isEmpty ? nil : ContactUtils.parseContact(email.replyTo, account: myAccount)
        let contactsTo = (fromContact.email == emailData.accountEmail) ? Array(email.getContacts(type: .to)) : [replyToContact ?? fromContact]
        let subject = "\(email.subject.lowercased().starts(with: "re:") ? "" : "Re: ")\(email.subject)"
        let contact = ContactUtils.checkIfFromHasName(email.fromAddress) ? email.fromAddress : "\(email.fromContact.displayName) &#60;\(email.fromContact.email)&#62;"
        let content = ("<br><br><div class=\"criptext_quote\">\(String.localize("ON_REPLY")) \(email.completeDate), \(contact) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">\(self.emailData.bodies[email.key] ?? "")</blockquote></div>")
        sendTrustedOnReply(email: email)
        presentComposer(email: email, contactsTo: contactsTo, contactsCc: [], subject: subject, content: content, blockFrom: true)
    }
    
    func onReplyAllPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            generalOptionsContainerView.closeMoreOptions()
            return
        }
        generalOptionsContainerView.closeMoreOptions()
        deselectSelectedRow()
        let email = getMail(index: indexPath.row)
        var contactsTo = [Contact]()
        var contactsCc = [Contact]()
        let myEmail = emailData.accountEmail
        let replyToContact = email.replyTo.isEmpty ? nil : ContactUtils.parseContact(email.replyTo, account: myAccount)
        if let replyTo = replyToContact {
            contactsTo.append(replyTo)
        } else {
            contactsTo.append(contentsOf: email.getContacts(type: .from, notEqual: myEmail))
        }
        contactsTo.append(contentsOf: email.getContacts(type: .to, notEqual: myEmail))
        contactsCc.append(contentsOf: email.getContacts(type: .cc, notEqual: myEmail))
        let subject = "\(email.subject.lowercased().starts(with: "re:") ? "" : "Re: ")\(email.subject)"
        let contact = ContactUtils.checkIfFromHasName(email.fromAddress) ? email.fromAddress : "\(email.fromContact.displayName) &#60;\(email.fromContact.email)&#62;"
        let content = ("<br><br><div class=\"criptext_quote\">\(String.localize("ON_REPLY")) \(email.completeDate), \(contact) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">\(self.emailData.bodies[email.key] ?? "")</blockquote></div>")
        sendTrustedOnReply(email: email)
        presentComposer(email: email, contactsTo: contactsTo, contactsCc: contactsCc, subject: subject, content: content, blockFrom: true)
    }
    
    func sendTrustedOnReply(email: Email) {
        if (!email.isSent && !email.fromContact.isTrusted) {
            let eventData = EventData.Peer.ContactTrust(email: email.fromContact.email, trusted: true)
            let eventParams = ["cmd": Event.Peer.contactTrust.rawValue, "params": eventData.asDictionary()] as [String : Any]
            DBManager.update(contact: email.fromContact, isTrusted: true)
            DBManager.createQueueItem(params: eventParams, account: self.myAccount)
        }
    }
    
    func onForwardPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            generalOptionsContainerView.closeMoreOptions()
            return
        }
        generalOptionsContainerView.closeMoreOptions()
        deselectSelectedRow()
        let email = getMail(index: indexPath.row)
        let ccContacts: List<Contact> = email.getContacts(type: ContactType.cc)
        let toContacts: List<Contact> = email.getContacts(type: ContactType.to)
        toContacts.append(objectsIn: ccContacts)
        let subject = "\(email.subject.lowercased().starts(with: "fw:") || email.subject.lowercased().starts(with: "fwd:") ? "" : "Fw: ")\(email.subject)"
        let contact = ContactUtils.checkIfFromHasName(email.fromAddress) ? email.fromAddress.replacingOccurrences(of: "<", with: "&#60;").replacingOccurrences(of: ">", with: "&#62;") : "<b>\(email.fromContact.displayName) &#60;\(email.fromContact.email)&#62;"
        let content = ("<br><br><div class=\"criptext_quote\"><span>---------- \(String.localize("FORWARD_MAIL")) ---------</span><br><span>\(String.localize("FROM")): \(contact)</span><br><span>\(String.localize("DATE")): \(email.completeDate)</span><br><span>\(String.localize("SUBJECT")): \(email.subject)</span><br>\(String.localize("TO")): \(toContacts.map({$0.displayName + " &#60;" + $0.email + "&#62;"}).joined(separator: ", "))<br><br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">\(self.emailData.bodies[email.key] ?? "")</blockquote></div>")
        presentComposer(email: email, contactsTo: [], contactsCc: [], subject: subject, content: content, blockFrom: false, attachments: email.getFiles())
    }
    
    func onDeletePress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleGeneralOptionsView()
            return
        }
        self.toggleGeneralOptionsView()
        let email = getMail(index: indexPath.row)
        guard emailData.selectedLabel == SystemLabel.trash.id || emailData.selectedLabel == SystemLabel.spam.id || emailData.selectedLabel == SystemLabel.draft.id else {
            self.moveSingleEmailToTrash(email)
            return
        }
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("DELETE_EMAIL")
        popover.initialMessage = String.localize("EMAIL_DELETE_PERMANENTLY")
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("Ok")
        popover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            weakSelf.deleteSingleEmail(email, indexPath: indexPath)
        }
        self.presentPopover(popover: popover, height: 170)
    }
    
    func deleteSingleEmail(_ email: Email, indexPath: IndexPath){
        let triggerEvent = email.canTriggerEvent
        let emailKey = email.key
        DBManager.delete(email)
        if (triggerEvent) {
            let eventData = EventData.Peer.EmailDeleted(metadataKeys: [emailKey])
            DBManager.createQueueItem(params: ["cmd": Event.Peer.emailsDeleted.rawValue, "params": eventData.asDictionary()], account: myAccount)
        }
    }
    
    func moveSingleEmailToTrash(_ email: Email){
        let triggerEvent = email.canTriggerEvent
        let changedLabels = getLabelNames(added: [SystemLabel.trash.id], removed: [])
        let emailKey = email.key
        DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.trash.id], removedLabelIds: [])
        if (triggerEvent) {
            let eventData = EventData.Peer.EmailLabels(metadataKeys: [emailKey], labelsAdded: changedLabels.0, labelsRemoved: changedLabels.1)
            DBManager.createQueueItem(params: ["cmd": Event.Peer.emailsLabels.rawValue, "params": eventData.asDictionary()], account: myAccount)
        }
    }
    
    func onMarkPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleGeneralOptionsView()
            return
        }
        let thresholdDate = getMail(index: indexPath.row).date
        var emailKeys = [Int]()
        for email in emailData.emails {
            guard email.date >= thresholdDate else {
                continue
            }
            DBManager.updateEmail(email, unread: true)
            guard email.canTriggerEvent else {
                continue
            }
            emailKeys.append(email.key)
        }
        if !emailKeys.isEmpty {
            emailKeys.chunked(into: Env.peerEventDataSize).forEach({ (batch) in
                let params = ["cmd": Event.Peer.emailsUnread.rawValue,
                          "params": [
                            "unread": 1,
                            "metadataKeys": batch
                ]] as [String : Any]
                DBManager.createQueueItem(params: params, account: myAccount)
            })
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func onSpamPress() {
        self.reportContact(type: ContactUtils.ReportType.spam)
    }
    
    func onPhishingPress() {
        self.reportContact(type: ContactUtils.ReportType.phishing)
    }
    
    func onUnsendPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow,
            let cell = emailsTableView.cellForRow(at: indexPath) as? EmailTableViewCell else {
            self.toggleGeneralOptionsView()
            return
        }
        let email = getMail(index: indexPath.row)
        self.toggleGeneralOptionsView()
        guard email.status != .unsent && email.isSent else {
            return
        }
        emailData.setState(email.key, isUnsending: true)
        emailsTableView.reloadData()
        let recipients = getEmailRecipients(contacts: email.getContacts())
        APIManager.unsendEmail(key: email.key, recipients: recipients, token: myAccount.jwt) { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.emailData.setState(email.key, isUnsending: false)
            if case .Unauthorized = responseData {
                weakSelf.showAlert(String.localize("AUTH_ERROR"), message: String.localize("AUTH_ERROR_MESSAGE"), style: .alert)
                weakSelf.emailsTableView.reloadData()
                return
            }
            if case .Removed = responseData {
                weakSelf.logout(account: weakSelf.myAccount, manually: false)
                return
            }
            if case .Forbidden = responseData {
                weakSelf.presentPasswordPopover(myAccount: weakSelf.myAccount)
                return
            }
            if case .Conflicts = responseData {
                weakSelf.showAlert(String.localize("UNSEND_FAILED"), message: String.localize("UNSEND_EXPIRED"), style: .alert)
                weakSelf.emailsTableView.reloadData()
                return
            }
            guard case .Success = responseData else {
                weakSelf.showAlert(String.localize("UNSEND_FAILED"), message: String.localize("UNABLE_UNSEND"), style: .alert)
                weakSelf.emailsTableView.reloadData()
                return
            }
            cell.isLoaded = false
            FileUtils.deleteDirectoryFromEmail(account: weakSelf.myAccount, metadataKey: "\(email.key)")
            DBManager.unsendEmail(email)
        }
    }

    func onPrintPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            return
        }
        let email = getMail(index: indexPath.row)
        let subject = "\(email.subject.lowercased().starts(with: "fw:") || email.subject.lowercased().starts(with: "fwd:") ? "" : "Fw: ")\(email.subject)"
        let image = UIImage(named: "footer_beta")
        let imageData:Data =  image!.pngData()!
        let contact = ContactUtils.checkIfFromHasName(email.fromAddress) ? email.fromAddress : "\(email.fromContact.displayName) &#60;\(email.fromContact.email)&#62;"
        let html = Constants.singleEmail(image: imageData.base64EncodedString(), subject: subject, contact: SharedUtils.replaceContactToStringChar(text: contact), completeDate: email.completeDate, contacts: SharedUtils.replaceContactToStringChar(text: email.getFullContacts()), content: self.emailData.bodies[email.key] ?? "")
        webView.frame = self.view.bounds
        webView.loadHTMLString(html, baseURL: nil)
    }
    
    func getEmailRecipients(contacts: [Contact]) -> [String]{
        return contacts.reduce([String](), { (result, contact) -> [String] in
            guard contact.email != emailData.accountEmail else {
                return result
            }
            return result + [contact.email]
        })
    }
    
    func onOverlayPress() {
        self.toggleGeneralOptionsView()
    }
    
    func onShowSourcePress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            generalOptionsContainerView.closeMoreOptions()
            return
        }
        generalOptionsContainerView.closeMoreOptions()
        deselectSelectedRow()
        let email = getMail(index: indexPath.row)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "EmailSourceViewController") as! EmailSourceViewController
        viewController.email = email
        viewController.myAccount = self.myAccount
        self.present(viewController, animated: true, completion: nil)
    }
}

extension EmailDetailViewController: UIWebViewDelegate {
    func webViewDidStartLoad(_ webView: UIWebView) {
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        let printer = UIPrintInteractionController.shared
        let printInfo = UIPrintInfo(dictionary:nil)
        
        printInfo.outputType = UIPrintInfo.OutputType.general
        printInfo.jobName = emailData.subject
        
        printer.showsPaperSelectionForLoadedPapers = true
        printer.printInfo = printInfo
        printer.printFormatter = webView.viewPrintFormatter()
        
        printer.present(animated: true, completionHandler: nil)
    }
    
    func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
    }
}

extension EmailDetailViewController: EmailDetailOptionsInterfaceDelegate {
    func onClose() {
        toggleGeneralOptionsView()
    }
    
    func onMoveToPress() {
        handleMoveTo()
    }
    
    func onAddLabesPress() {
        handleAddLabels()
    }
    
    func onRestorePress() {
        self.restoreThreads()
    }
    
    func onArchivePress() {
        self.archiveThreads()
    }

    func onPrintAllPress() {
        let emails = self.emailData.emails
        guard let email = emails?.first else{
            return
        }
        let subject = "\(email.subject.lowercased().starts(with: "fw:") || email.subject.lowercased().starts(with: "fwd:") ? "" : "Fw: ")\(email.subject)"
        var body = String()
        for mail in emails!{
            let contact = mail.fromAddress.isEmpty ? "\(mail.fromContact.displayName)</b> &lt;\(mail.fromContact.email)&gt;" : mail.fromAddress
            body = "\(body) \(Constants.bodyEmail(contact: SharedUtils.replaceContactToStringChar(text: contact), completeDate: mail.completeDate, contacts: SharedUtils.replaceContactToStringChar(text: mail.getFullContacts()), content: self.emailData.bodies[mail.key] ?? "")) <hr>"
        }
        let image = UIImage(named: "footer_beta")
        let imageData:Data =  image!.pngData()!
        let message = (emailData.emails.count) > 1 ? "\((emails?.count)!) \(String.localize("MESSAGES"))" : "1 \(String.localize("MESSAGE"))"
        let html = Constants.threadEmail(image: imageData.base64EncodedString(), subject: subject, body: body, messages: message)
        webView.frame = self.view.bounds
        webView.loadHTMLString(html, baseURL: nil)
    }
}

extension EmailDetailViewController : LabelsUIPopoverDelegate{
    
    func handleAddLabels(){
        let labelsPopover = LabelsUIPopover.instantiate(type: .addLabels, selectedLabel: emailData.selectedLabel, myAccount: myAccount)
        for label in emailData.labels {
            labelsPopover.selectedLabels[label.id] = label
        }
        presentPopover(labelsPopover, height: Constants.basePopoverHeight + labelsPopover.labels.count * Constants.labelPopoverHeight)
    }
    
    func handleMoveTo(){
        let labelsPopover = LabelsUIPopover.instantiate(type: .moveTo, selectedLabel: emailData.selectedLabel, myAccount: myAccount)
        presentPopover(labelsPopover, height: Constants.basePopoverHeight + labelsPopover.labels.count * Constants.labelPopoverHeight)
    }
    
    func presentPopover(_ popover: LabelsUIPopover, height: Int){
        popover.delegate = self
        popover.preparePopover(rootView: self, height: height)
        self.present(popover, animated: true){ [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.generalOptionsContainerView.closeMoreOptions()
            weakSelf.view.layoutIfNeeded()
        }
    }
    
    func setLabels(added: [Int], removed: [Int]) {
        setLabels(added: added, removed: removed, forceRemove: false)
    }
    
    func moveTo(labelId: Int) {
        let removeLabels = labelId == SystemLabel.all.id
            ? [SystemLabel.inbox.id]
            : emailData.selectedLabel == SystemLabel.trash.id && labelId == SystemLabel.spam.id ? [SystemLabel.trash.id] : []
        let addLabels = labelId == SystemLabel.all.id
            ? []
            : [labelId]
        setLabels(added: addLabels, removed: removeLabels, forceRemove: labelId == SystemLabel.trash.id || labelId == SystemLabel.spam.id)
    }
    
    func setLabels(added: [Int], removed: [Int], forceRemove: Bool){
        let changedLabels = getLabelNames(added: added, removed: removed)
        DBManager.addRemoveLabelsForThreads(self.emailData.threadId, addedLabelIds: added, removedLabelIds: removed, currentLabel: self.emailData.selectedLabel, account: self.myAccount)
        let emails = Array(DBManager.getThreadEmails(self.emailData.threadId, label: self.emailData.selectedLabel, account: self.myAccount))
        ContactUtils.reportContactToServer(emails: emails, addedLabelIds: added, removedLabelIds: removed, currentLabel: self.emailData.selectedLabel, account: self.myAccount)
        self.emailData.rebuildLabels()
        if(forceRemove){
            self.mailboxData.removeSelectedRow = true
            self.navigationController?.popViewController(animated: true)
        } else {
            self.myHeaderView = nil
            self.emailsTableView.reloadData()
        }
        
        let eventData = EventData.Peer.ThreadLabels(threadIds: [emailData.threadId], labelsAdded: changedLabels.0, labelsRemoved: changedLabels.1)
        DBManager.createQueueItem(params: ["params": eventData.asDictionary(), "cmd": Event.Peer.threadsLabels.rawValue], account: myAccount)
    }
    
    func getLabelNames(added: [Int], removed: [Int]) -> ([String], [String]){
        var addedNames = [String]()
        var removedNames = [String]()
        for id in added {
            guard let label = DBManager.getLabel(id) else {
                continue
            }
            addedNames.append(label.text)
        }
        for id in removed {
            guard let label = DBManager.getLabel(id) else {
                continue
            }
            removedNames.append(label.text)
        }
        return (addedNames, removedNames)
    }
}

extension EmailDetailViewController : CriptextFileDelegate, UIDocumentInteractionControllerDelegate {
    func fileError(message: String) {
        let alertPopover = GenericAlertUIPopover()
        alertPopover.myTitle = String.localize("FILE_ERROR")
        alertPopover.myMessage = message
        self.presentPopover(popover: alertPopover, height: 205)
    }
    
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func uploadProgressUpdate(file: File, progress: Int) {
        guard let attachmentCell = getCellFromFile(file) else {
            return
        }
        attachmentCell.markImageView.isHidden = true
        attachmentCell.progressView.isHidden = false
        attachmentCell.progressView.setProgress(Float(progress)/100.0, animated: true)
    }
    
    func finishRequest(file: File, success: Bool) {
        if(success){
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(file.name)
            let viewer = UIDocumentInteractionController(url: fileURL)
            viewer.delegate = self
            viewer.presentPreview(animated: true)
        }
        guard let attachmentCell = getCellFromFile(file) else {
            return
        }
        attachmentCell.setMarkIcon(success: success)
    }
    
    func getCellFromFile(_ file: File) -> AttachmentTableCell? {
        guard let emailIndex = emailData.emails.firstIndex(where: {$0.key == file.emailId}),
            let index = emailData.emails[emailIndex].files.firstIndex(where: {$0.token == file.token}),
            let emailCell = self.emailsTableView.cellForRow(at: IndexPath(row: emailIndex == 0 ? 0 : emailIndex - collapseUntilIndex, section: 0)) as? EmailTableViewCell,
            let attachmentCell = emailCell.attachmentsTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? AttachmentTableCell else {
                return nil
        }
        return attachmentCell
    }
    
}

extension EmailDetailViewController: ComposerSendMailDelegate {
    func newDraft(draft: Email) {
        
    }
    
    func deleteDraft(draftId: Int) {
    }
    
    func sendMail(email: Email, emailBody: String, password: String?) {
        guard let inboxViewController = navigationController?.viewControllers.first as? InboxViewController else {
            return
        }
        inboxViewController.sendMail(email: email, emailBody: emailBody, password: password)
    }
}

extension EmailDetailViewController {
    func onStarPressed() {
        let threadIsStarred = emailData.labels.contains(where: {$0.id == SystemLabel.starred.id})
        let addedLabels = threadIsStarred ? [] : [SystemLabel.starred.id]
        let removedLabels = threadIsStarred ? [SystemLabel.starred.id] : []
        setLabels(added: addedLabels, removed: removedLabels)
    }
}

extension EmailDetailViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let hintView = HintUIView()
        hintView.messageLabel.text = String.localize("GUIDE_UNSEND")
        hintView.rightConstraint.constant = 50
        hintView.topCenterConstraint.constant = -25
        
        return (bodyView: hintView, arrowView: nil)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        var coachMark = coachMarksController.helper.makeCoachMark(for: target) { frame in
            return UIBezierPath(ovalIn: frame.insetBy(dx: -4, dy: -4))
        }
        coachMark.allowTouchInsideCutoutPath = true
        return coachMark
    }
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
}

extension EmailDetailViewController: LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData, account: Account) {
        guard linkData.version == Env.linkVersion else {
            let popover = GenericAlertUIPopover()
            popover.myTitle = String.localize("VERSION_TITLE")
            popover.myMessage = String.localize("VERSION_MISMATCH")
            self.presentPopover(popover: popover, height: 220)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = account
        self.present(linkDeviceVC, animated: true, completion: nil)
    }
    func onCancelLinkDevice(linkData: LinkData, account: Account) {
        if case .sync = linkData.kind {
            APIManager.syncDeny(randomId: linkData.randomId, token: account.jwt, completion: {_ in })
        } else {
            APIManager.linkDeny(randomId: linkData.randomId, token: account.jwt, completion: {_ in })
        }
    }
}
