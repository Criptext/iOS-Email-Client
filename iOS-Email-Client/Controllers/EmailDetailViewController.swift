//
//  EmailDetailViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/27/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//
import Material
import Foundation

class EmailDetailViewController: UIViewController {
    var emailData : EmailDetailData!
    var mailboxData : MailboxData!
    var myAccount: Account!
    @IBOutlet weak var emailsTableView: UITableView!
    @IBOutlet weak var topToolbar: TopbarUIView!
    @IBOutlet weak var moreOptionsContainerView: DetailMoreOptionsUIView!
    @IBOutlet weak var generalOptionsContainerView: GeneralMoreOptionsUIView!
    
    var myHeaderView : UIView?
    var hasUnreadEmails : Bool {
        get {
            return emailData.emails.contains(where: {$0.unread})
        }
    }
    let fileManager = CriptextFileManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        self.setupToolbar()
        self.setupMoreOptionsViews()
        
        self.registerCellNibs()
        self.topToolbar.delegate = self
        self.generalOptionsContainerView.delegate = self
        
        fileManager.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNewEmail(notification:)), name: .onNewEmail, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteDraft(notification:)), name: .onDeleteDraft, object: nil)
        
        displayMarkIcon(asRead: hasUnreadEmails)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.topToolbar.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.topToolbar.swapLeftIcon(labelId: emailData.selectedLabel)
        self.topToolbar.isHidden = false
    }
    
    @objc func refreshNewEmail(notification: NSNotification){
        guard let data = notification.userInfo,
            let email = data["email"] as? Email,
            email.threadId == emailData.threadId else {
                return
        }
        emailData.emails.append(email)
        email.isExpanded = true
        let nib = UINib(nibName: "EmailDetailTableCell", bundle: nil)
        emailsTableView.register(nib, forCellReuseIdentifier: "emailDetail\(email.key)")
        emailsTableView.reloadData()
    }
    
    @objc func deleteDraft(notification: NSNotification){
        guard let data = notification.userInfo,
            let draftId = data["draftId"] as? String,
            let draftIndex = emailData.emails.index(where: {$0.key == draftId}) else {
                return
        }
        emailData.emails.remove(at: draftIndex)
        emailsTableView.reloadData()
    }
    
    func setupToolbar(){
        self.navigationController?.navigationBar.addSubview(self.topToolbar)
        let margins = self.navigationController!.navigationBar.layoutMarginsGuide
        self.topToolbar.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: -8.0).isActive = true
        self.topToolbar.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 8.0).isActive = true
        self.topToolbar.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: 8.0).isActive = true
        self.navigationController?.navigationBar.bringSubview(toFront: self.topToolbar)
        self.topToolbar.isHidden = true
        
        let cancelButton = UIButton(type: .custom)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        cancelButton.setImage(#imageLiteral(resourceName: "menu-back"), for: .normal)
        cancelButton.layer.backgroundColor = UIColor(red:0.31, green:0.32, blue:0.36, alpha:1.0).cgColor
        cancelButton.tintColor = UIColor(red:0.56, green:0.56, blue:0.58, alpha:1.0)
        cancelButton.layer.cornerRadius = 15.5
        let cancelBarButton = UIBarButtonItem(customView: cancelButton)
        self.navigationItem.leftBarButtonItem = cancelBarButton
    }
    
    func setupMoreOptionsViews(){
        emailsTableView.rowHeight = UITableViewAutomaticDimension
        emailsTableView.estimatedRowHeight = 108
        emailsTableView.sectionHeaderHeight = UITableViewAutomaticDimension;
        emailsTableView.estimatedSectionHeaderHeight = 56;
        moreOptionsContainerView.delegate = self
    }
    
    func registerCellNibs(){
        for email in self.emailData.emails {
            let nib = UINib(nibName: "EmailDetailTableCell", bundle: nil)
            self.emailsTableView.register(nib, forCellReuseIdentifier: "emailDetail\(email.key)")
        }
    }
    
    func displayMarkIcon(asRead: Bool){
        topToolbar.swapMarkTo(unread: !asRead)
    }
}

extension EmailDetailViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let email = emailData.emails[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "emailDetail\(email.key)") as! EmailTableViewCell
        cell.setContent(email)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emailData.emails.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard myHeaderView == nil else {
            return myHeaderView
        }
        let headerView = tableView.dequeueReusableCell(withIdentifier: "emailTableHeaderView") as! EmailDetailHeaderCell
        headerView.addLabels(emailData.labels)
        headerView.setSubject(emailData.subject)
        myHeaderView = headerView
        return myHeaderView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footerView = tableView.dequeueReusableCell(withIdentifier: "emailTableFooterView") as! EmailDetailFooterCell
        footerView.delegate = self
        return footerView
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 78.0
    }
}

extension EmailDetailViewController: EmailTableViewCellDelegate {
    func tableViewCellDidLoadContent(_ cell: EmailTableViewCell, email: Email) {
        guard email.unread else {
            emailsTableView.reloadData()
            return
        }
        DBManager.updateEmail(email, unread: false)
        displayMarkIcon(asRead: hasUnreadEmails)
        emailsTableView.reloadData()
        if(email.fromContact.email != emailData.accountEmail){
            APIManager.notifyOpen(key: Int(email.key)!, token: myAccount.jwt)
        }
    }
    
    func tableViewCellDidTap(_ cell: EmailTableViewCell) {
        guard let indexPath = self.emailsTableView.indexPath(for: cell) else {
            return
        }
        let email = emailData.emails[indexPath.row]
        email.isExpanded = !email.isExpanded
        emailsTableView.reloadData()
    }
    
    func tableViewCellDidTapAttachment(file: File) {
        fileManager.registerFile(file: file)
    }
    
    func tableViewCellDidTapIcon(_ cell: EmailTableViewCell, _ sender: UIView, _ iconType: EmailTableViewCell.IconType) {
        switch(iconType){
        case .attachment:
            handleAttachmentTap(cell, sender)
        case .read:
            handleReadTap(cell, sender)
        case .contacts:
            handleContactsTap(cell, sender)
        case .unsend:
            handleUnsendTap(cell, sender)
        case .options:
            handleOptionsTap(cell, sender)
        case .reply:
            handleReplyTap(cell, sender)
        case .edit:
            handleEditTap(cell, sender)
        }
    }
    
    func handleEditTap(_ cell: EmailTableViewCell, _ sender: UIView){
        guard let indexPath = emailsTableView.indexPath(for: cell) else {
            return
        }
        let email = emailData.emails[indexPath.row]
        let contactsTo = Array(email.getContacts(type: .to))
        let contactsCc = Array(email.getContacts(type: .cc))
        presentComposer(email: email, contactsTo: contactsTo, contactsCc: contactsCc, subjectPrefix: "")
    }
    
    func handleAttachmentTap(_ cell: EmailTableViewCell, _ sender: UIView){
        let historyPopover = HistoryUIPopover()
        historyPopover.historyCellName = "AttachmentHistoryTableCell"
        historyPopover.historyTitleText = "Attachments History"
        historyPopover.emptyMessage = "Your files have not been opened/downloaded yet"
        historyPopover.historyImage = #imageLiteral(resourceName: "attachment")
        historyPopover.cellHeight = 81.0
        presentPopover(historyPopover, sender, height: 130)
    }
    
    func handleReadTap(_ cell: EmailTableViewCell, _ sender: UIView){
        let historyPopover = HistoryUIPopover()
        historyPopover.historyCellName = "ReadHistoryTableCell"
        historyPopover.historyTitleText = "Read History"
        historyPopover.emptyMessage = "Your email has not been opened yet"
        historyPopover.historyImage = #imageLiteral(resourceName: "read")
        historyPopover.cellHeight = 39.0
        presentPopover(historyPopover, sender, height: 130)
    }
    
    func handleContactsTap(_ cell: EmailTableViewCell, _ sender: UIView){
        guard let indexPath = emailsTableView.indexPath(for: cell) else {
            return
        }
        let email = emailData.emails[indexPath.row]
        let contactsPopover = ContactsDetailUIPopover()
        contactsPopover.email = email
        presentPopover(contactsPopover, sender, height: CGFloat(50 + 2 * email.emailContacts.count * 20))
    }
    
    func handleReplyTap(_ cell: EmailTableViewCell, _ sender: UIView){
        guard let indexPath = emailsTableView.indexPath(for: cell) else {
            return
        }
        emailsTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        onReplyPress()
    }
    
    func handleUnsendTap(_ cell: EmailTableViewCell, _ sender: UIView){
        let unsentPopover = UnsentUIPopover()
        unsentPopover.date = "Coming Soon!"
        presentPopover(unsentPopover, sender, height: 68)
    }
    
    func presentPopover(_ popover: UIViewController, _ sender: UIView, height: CGFloat){
        popover.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: height)
        popover.popoverPresentationController?.sourceView = sender
        popover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width/1.0001, height: sender.frame.size.height)
        popover.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        popover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(popover, animated: true, completion: nil)
    }
    
    func handleOptionsTap(_ cell: EmailTableViewCell, _ sender: UIView){
        guard let indexPath = emailsTableView.indexPath(for: cell) else {
            return
        }
        moreOptionsContainerView.spamButton.setTitle(emailData.selectedLabel == SystemLabel.spam.id ? "Remove from Spam" : "Mark as Spam", for: .normal)
        emailsTableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        toggleMoreOptionsView()
    }
    
    func deselectSelectedRow(){
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            return
        }
        emailsTableView.deselectRow(at: indexPath, animated: false)
    }
    
    @objc func toggleMoreOptionsView(){
        guard moreOptionsContainerView.isHidden else {
            moreOptionsContainerView.closeMoreOptions()
            deselectSelectedRow()
            return
        }
        moreOptionsContainerView.showMoreOptions()
    }
    
    @objc func toggleGeneralOptionsView(){
        guard generalOptionsContainerView.isHidden else {
            generalOptionsContainerView.closeMoreOptions()
            return
        }
        generalOptionsContainerView.showMoreOptions()
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
    
    func presentComposer(email: Email, contactsTo: [Contact], contactsCc: [Contact], subjectPrefix: String){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composerVC = navComposeVC.viewControllers.first as! ComposeViewController
        let composerData = ComposerData()
        composerData.initToContacts.append(contentsOf: contactsTo)
        composerData.initCcContacts.append(contentsOf: contactsCc)
        composerData.initSubject = email.isDraft ? email.subject : email.subject.starts(with: "\(subjectPrefix) ") ? email.subject : "\(subjectPrefix) \(email.subject)"
        let replyBody = email.isDraft ? email.content : ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(email.getFullDate()), \(email.fromContact.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + email.content + "</blockquote>")
        composerData.initContent = replyBody
        composerData.threadId = emailData.threadId
        composerData.emailDraft = email.isDraft ? email : nil
        composerVC.composerData = composerData
        if(email.isDraft){
            for file in email.files {
                file.requestStatus = .finish
                composerVC.fileManager.registeredFiles.append(file)
            }
        }
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func onFooterReplyPress() {
        guard let lastEmail = emailData.emails.last,
            let lastContact = emailData.emails.last?.fromContact else {
                return
        }
        let contactsTo = (lastContact.email == emailData.accountEmail) ? Array(lastEmail.getContacts(type: .to)) : [lastContact]
        presentComposer(email: lastEmail, contactsTo: contactsTo, contactsCc: [], subjectPrefix: "RE:")
    }
    
    func onFooterReplyAllPress() {
        guard let lastEmail = emailData.emails.last else {
                return
        }
        var contactsTo = [Contact]()
        var contactsCc = [Contact]()
        let myEmail = emailData.accountEmail
        for email in emailData.emails {
            contactsTo.append(contentsOf: email.getContacts(type: .from, notEqual: myEmail))
            contactsTo.append(contentsOf: email.getContacts(type: .to, notEqual: myEmail))
            contactsCc.append(contentsOf: email.getContacts(type: .cc, notEqual: myEmail))
        }
        presentComposer(email: lastEmail, contactsTo: contactsTo, contactsCc: contactsCc, subjectPrefix: "RE:")
    }
    
    func onFooterForwardPress() {
        guard let lastEmail = emailData.emails.last else {
                return
        }
        presentComposer(email: lastEmail, contactsTo: [], contactsCc: [], subjectPrefix: "FW:")
    }
}

extension EmailDetailViewController: NavigationToolbarDelegate {
    func onBackPress() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func onArchiveThreads() {
        guard emailData.selectedLabel == SystemLabel.trash.id || emailData.selectedLabel == SystemLabel.draft.id || emailData.selectedLabel == SystemLabel.spam.id || emailData.selectedLabel == SystemLabel.all.id else {
            self.moveTo(labelId: SystemLabel.all.id)
            return
        }
        guard emailData.selectedLabel != SystemLabel.draft.id && emailData.selectedLabel != SystemLabel.all.id else {
            setLabels(added: [SystemLabel.inbox.id], removed: [])
            return
        }
        setLabels(added: [], removed: [emailData.selectedLabel])
    }
    
    func onTrashThreads() {
        guard emailData.selectedLabel == SystemLabel.trash.id || emailData.selectedLabel == SystemLabel.spam.id || emailData.selectedLabel == SystemLabel.draft.id else {
            self.setLabels(added: [SystemLabel.trash.id], removed: [], forceRemove: true)
            return
        }
        let archiveAction = UIAlertAction(title: "Ok", style: .destructive){ (alert : UIAlertAction!) -> Void in
            DBManager.delete(self.emailData.emails)
            self.mailboxData.removeSelectedRow = true
            self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        showAlert("Delete Threads", message: "The selected threads will be PERMANENTLY deleted", style: .alert, actions: [archiveAction, cancelAction])
    }
    
    func onMarkThreads() {
        let unread = !hasUnreadEmails
        for email in emailData.emails {
            if(email.unread){
                email.isExpanded = !unread
            }
            DBManager.updateEmail(email, unread: unread)
        }
        if(unread){
            self.navigationController?.popViewController(animated: true)
        } else {
            self.emailsTableView.reloadData()
        }
    }
    
    func onMoreOptions() {
        toggleGeneralOptionsView()
    }
}

extension EmailDetailViewController: DetailMoreOptionsViewDelegate {
    func onReplyPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleMoreOptionsView()
            self.onFooterReplyPress()
            return
        }
        moreOptionsContainerView.closeMoreOptions()
        deselectSelectedRow()
        let email = emailData.emails[indexPath.row]
        let fromContact = email.fromContact
        let contactsTo = (fromContact.email == emailData.accountEmail) ? Array(email.getContacts(type: .to)) : [fromContact]
        presentComposer(email: email, contactsTo: contactsTo, contactsCc: [], subjectPrefix: "RE:")
    }
    
    func onReplyAllPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleMoreOptionsView()
            self.onFooterReplyAllPress()
            return
        }
        self.toggleMoreOptionsView()
        let email = emailData.emails[indexPath.row]
        var contactsTo = [Contact]()
        var contactsCc = [Contact]()
        let myEmail = emailData.accountEmail
        contactsTo.append(contentsOf: email.getContacts(type: .from, notEqual: myEmail))
        contactsTo.append(contentsOf: email.getContacts(type: .to, notEqual: myEmail))
        contactsCc.append(contentsOf: email.getContacts(type: .cc, notEqual: myEmail))
        presentComposer(email: email, contactsTo: contactsTo, contactsCc: contactsCc, subjectPrefix: "RE:")
    }
    
    func onForwardPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleMoreOptionsView()
            self.onFooterReplyPress()
            return
        }
        self.toggleMoreOptionsView()
        let email = emailData.emails[indexPath.row]
        presentComposer(email: email, contactsTo: [], contactsCc: [], subjectPrefix: "Fw:")
    }
    
    func onDeletePress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleMoreOptionsView()
            return
        }
        self.toggleMoreOptionsView()
        let email = emailData.emails[indexPath.row]
        guard emailData.selectedLabel == SystemLabel.trash.id || emailData.selectedLabel == SystemLabel.spam.id || emailData.selectedLabel == SystemLabel.draft.id else {
            DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: [SystemLabel.trash.id], removedLabelIds: [])
            self.removeEmail(indexPath: indexPath)
            return
        }
        
        let deleteAction = UIAlertAction(title: "Ok", style: .destructive){ (alert : UIAlertAction!) -> Void in
            DBManager.delete(email)
            self.removeEmail(indexPath: indexPath)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        showAlert("Delete Email", message: "The selected email will be PERMANENTLY deleted", style: .alert, actions: [deleteAction, cancelAction])
    }
    
    func removeEmail(indexPath: IndexPath){
        emailData.emails.remove(at: indexPath.row)
        if(emailData.emails.isEmpty){
            mailboxData.removeSelectedRow = true
            navigationController?.popViewController(animated: true)
        }else{
            emailsTableView.reloadData()
        }
    }
    
    func onMarkPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleMoreOptionsView()
            return
        }
        self.toggleMoreOptionsView()
        let email = emailData.emails[indexPath.row]
        DBManager.updateEmail(email, unread: true)
        email.isExpanded = false
        emailsTableView.reloadData()
        displayMarkIcon(asRead: true)
    }
    
    func onSpamPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleMoreOptionsView()
            return
        }
        self.toggleMoreOptionsView()
        let isSpam = emailData.selectedLabel == SystemLabel.spam.id
        let isTrash = emailData.selectedLabel == SystemLabel.trash.id
        let removeLabel = isSpam ? [SystemLabel.spam.id] : isTrash ? [SystemLabel.trash.id] : []
        let addLabel = isSpam ? [] : [SystemLabel.spam.id]
        let email = emailData.emails[indexPath.row]
        DBManager.addRemoveLabelsFromEmail(email, addedLabelIds: addLabel, removedLabelIds: removeLabel)
        self.removeEmail(indexPath: indexPath)
    }
    
    func onPrintPress() {
        //TO DO
    }
    
    func onOverlayPress() {
        self.toggleMoreOptionsView()
    }
}

extension EmailDetailViewController : GeneralMoreOptionsViewDelegate {
    func onDismissPress() {
        toggleGeneralOptionsView()
    }
    
    func onMoveToPress() {
        handleMoveTo()
    }
    
    func onAddLabesPress() {
        handleAddLabels()
    }
}

extension EmailDetailViewController : LabelsUIPopoverDelegate{
    
    func handleAddLabels(){
        let labelsPopover = LabelsUIPopover.instantiate(type: .addLabels, selectedLabel: emailData.selectedLabel)
        for label in emailData.labels {
            labelsPopover.selectedLabels[label.id] = label
        }
        presentPopover(labelsPopover, height: Constants.basePopoverHeight + labelsPopover.labels.count * Constants.labelPopoverHeight)
    }
    
    func handleMoveTo(){
        let labelsPopover = LabelsUIPopover.instantiate(type: .moveTo, selectedLabel: emailData.selectedLabel)
        presentPopover(labelsPopover, height: Constants.basePopoverHeight + labelsPopover.labels.count * Constants.labelPopoverHeight)
    }
    
    func presentPopover(_ popover: LabelsUIPopover, height: Int){
        popover.delegate = self
        popover.preparePopover(rootView: self, height: height)
        self.present(popover, animated: true){
            self.toggleGeneralOptionsView()
            self.view.layoutIfNeeded()
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
        DBManager.addRemoveLabelsForThreads(emailData.threadId, addedLabelIds: added, removedLabelIds: removed, currentLabel: emailData.selectedLabel)
        if(removed.contains(where: {$0 == emailData.selectedLabel}) || forceRemove){
            mailboxData.removeSelectedRow = true
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension EmailDetailViewController : CriptextFileDelegate, UIDocumentInteractionControllerDelegate {
    
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
            var wholeFile = Data()
            for chunk in file.chunks {
                wholeFile.append(chunk)
            }
            let tmpPath = NSTemporaryDirectory() + file.name
            try! wholeFile.write(to: URL(fileURLWithPath: tmpPath))
            
            let viewer = UIDocumentInteractionController(url: URL(fileURLWithPath: tmpPath))
            viewer.delegate = self
            viewer.presentPreview(animated: true)
        }
        guard let attachmentCell = getCellFromFile(file) else {
            return
        }
        attachmentCell.setMarkIcon(success: success)
    }
    
    func getCellFromFile(_ file: File) -> AttachmentTableCell? {
        guard let emailIndex = emailData.emails.index(where: {$0.key == file.emailId}),
            let index = emailData.emails[emailIndex].files.index(where: {$0.token == file.token}),
            let emailCell = self.emailsTableView.cellForRow(at: IndexPath(row: emailIndex, section: 0)) as? EmailTableViewCell,
            let attachmentCell = emailCell.attachmentsTableView.cellForRow(at: IndexPath(row: index, section: 0)) as? AttachmentTableCell else {
                return nil
        }
        return attachmentCell
    }
}
