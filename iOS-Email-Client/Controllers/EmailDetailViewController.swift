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
    @IBOutlet weak var emailsTableView: UITableView!
    @IBOutlet weak var topToolbar: NavigationToolbarView!
    @IBOutlet weak var moreOptionsContainerView: DetailMoreOptionsUIView!
    @IBOutlet weak var generalOptionsContainerView: GeneralMoreOptionsUIView!
    
    var myHeaderView : UIView?
    var hasUnreadEmails : Bool {
        get {
            return emailData.emails.contains(where: {$0.unread})
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        self.setupToolbar()
        self.setupMoreOptionsViews()
        
        self.registerCellNibs()
        self.topToolbar.toolbarDelegate = self
        self.generalOptionsContainerView.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNewEmail(notification:)), name: .onNewEmail, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(deleteDraft(notification:)), name: .onDeleteDraft, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.topToolbar.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
        if(asRead){
            topToolbar.setupMarkAsRead()
        } else {
            topToolbar.setupMarkAsUnread()
        }
        topToolbar.setItemsMenu()
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

extension EmailDetailViewController: EmailTableViewCellDelegate{
    func tableViewCellDidLoadContent(_ cell: EmailTableViewCell) {
        guard let indexPath = self.emailsTableView.indexPath(for: cell) else {
            return
        }
        let email = emailData.emails[indexPath.row]
        DBManager.updateEmail(email, unread: false)
        displayMarkIcon(asRead: hasUnreadEmails)
        emailsTableView.reloadData()
    }
    
    func tableViewCellDidTap(_ cell: EmailTableViewCell) {
        guard let indexPath = self.emailsTableView.indexPath(for: cell) else {
            return
        }
        let email = emailData.emails[indexPath.row]
        email.isExpanded = !email.isExpanded
        emailsTableView.reloadData()
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
        historyPopover.historyImage = #imageLiteral(resourceName: "attachment")
        historyPopover.cellHeight = 81.0
        presentPopover(historyPopover, sender, height: 233)
    }
    
    func handleReadTap(_ cell: EmailTableViewCell, _ sender: UIView){
        let historyPopover = HistoryUIPopover()
        historyPopover.historyCellName = "ReadHistoryTableCell"
        historyPopover.historyTitleText = "Read History"
        historyPopover.historyImage = #imageLiteral(resourceName: "read")
        historyPopover.cellHeight = 39.0
        presentPopover(historyPopover, sender, height: 233)
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
        moreOptionsContainerView.spamButton.setTitle(mailboxData.selectedLabel == SystemLabel.spam.id ? "Remove from Spam" : "Mark as Spam", for: .normal)
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
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func onFooterReplyPress() {
        guard let lastEmail = emailData.emails.last,
            let lastContact = emailData.emails.last?.fromContact else {
                return
        }
        let contactsTo = (lastContact.email == emailData.accountEmail) ? Array(lastEmail.getContacts(type: .to)) : [lastContact]
        presentComposer(email: lastEmail, contactsTo: contactsTo, contactsCc: [], subjectPrefix: "Re:")
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
        presentComposer(email: lastEmail, contactsTo: contactsTo, contactsCc: contactsCc, subjectPrefix: "Re:")
    }
    
    func onFooterForwardPress() {
        guard let lastEmail = emailData.emails.last else {
                return
        }
        presentComposer(email: lastEmail, contactsTo: [], contactsCc: [], subjectPrefix: "Fw:")
    }
}

extension EmailDetailViewController: NavigationToolbarDelegate {
    func onBackPress() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func onArchiveThreads() {
        let archiveAction = UIAlertAction(title: "Yes", style: .default){ (alert : UIAlertAction!) -> Void in
            self.setLabels([])
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        showAlert("Archive Threads", message: "The selected threads will be displayed only in ALL MAIL", style: .alert, actions: [archiveAction, cancelAction])
    }
    
    func onTrashThreads() {
        let archiveAction = UIAlertAction(title: "Yes", style: .destructive){ (alert : UIAlertAction!) -> Void in
            self.moveTo(labelId: SystemLabel.trash.id)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        showAlert("Delete Threads", message: "The selected threads will be moved to Trash", style: .alert, actions: [archiveAction, cancelAction])
    }
    
    func onMarkThreads() {
        let unread = !hasUnreadEmails
        for email in emailData.emails {
            DBManager.updateEmail(email, unread: unread)
        }
        if(unread){
            self.navigationController?.popViewController(animated: true)
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
        presentComposer(email: email, contactsTo: contactsTo, contactsCc: [], subjectPrefix: "Re:")
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
        presentComposer(email: email, contactsTo: contactsTo, contactsCc: contactsCc, subjectPrefix: "Re:")
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
        moveEmail(to: SystemLabel.trash.id, indexPath: indexPath, title: "Delete Email", message: "Send the selected email to Trash")
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
    }
    
    func onSpamPress() {
        guard let indexPath = emailsTableView.indexPathForSelectedRow else {
            self.toggleMoreOptionsView()
            return
        }
        self.toggleMoreOptionsView()
        let isSpam = mailboxData.selectedLabel == SystemLabel.spam.id
        let title = isSpam ? "Remove from Spam" : "Mark as Spam"
        let message = "Send the selected email to \(isSpam ? "Inbox" : "Spam")"
        moveEmail(to: isSpam ? SystemLabel.inbox.id : SystemLabel.spam.id, indexPath: indexPath, title: title, message: message)
    }
    
    func moveEmail(to label: Int, indexPath: IndexPath, title: String, message: String){
        let email = emailData.emails[indexPath.row]
        let archiveAction = UIAlertAction(title: "Yes", style: .default){ (alert : UIAlertAction!) -> Void in
            DBManager.setLabelsForEmail(email, labels: [label])
            self.emailData.emails.remove(at: indexPath.row)
            guard !self.emailData.emails.isEmpty else{
                self.mailboxData.removeSelectedRow = true
                self.navigationController?.popViewController(animated: true)
                return
            }
            self.emailsTableView.reloadData()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        showAlert(title, message: message, style: .alert, actions: [archiveAction, cancelAction])
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
    
    func getMoveableLabels() -> [Label] {
        let labels = DBManager.getLabels()
        return labels.reduce([Label](), { (moveableLabels, label) -> [Label] in
            guard label.id != SystemLabel.draft.id && label.id != SystemLabel.sent.id else {
                return moveableLabels
            }
            return moveableLabels + [label]
        })
    }
    
    func handleAddLabels(){
        let labelsPopover = LabelsUIPopover()
        labelsPopover.headerTitle = "Add Labels"
        labelsPopover.type = .addLabels
        labelsPopover.labels.append(contentsOf: getMoveableLabels())
        labelsPopover.delegate = self
        for label in emailData.labels {
            labelsPopover.selectedLabels[label.id] = label
        }
        presentPopover(labelsPopover)
    }
    
    func handleMoveTo(){
        let labelsPopover = LabelsUIPopover()
        labelsPopover.headerTitle = "Move To"
        labelsPopover.type = .moveTo
        labelsPopover.labels.append(contentsOf: getMoveableLabels())
        labelsPopover.delegate = self
        presentPopover(labelsPopover)
    }
    
    func presentPopover(_ popover: UIViewController){
        popover.preferredContentSize = CGSize(width: 269, height: 300)
        popover.popoverPresentationController?.sourceView = self.view
        popover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        popover.popoverPresentationController?.permittedArrowDirections = []
        popover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(popover, animated: true){
            self.toggleGeneralOptionsView()
            self.view.layoutIfNeeded()
        }
    }
    
    func setLabels(_ labels: [Int]) {
        let myLabels = emailData.labels
        let labelsToRemove = myLabels.reduce([Int]()) { (removeLabels, label) -> [Int] in
            guard !labels.contains(label.id) && label.id != SystemLabel.draft.id && label.id != SystemLabel.sent.id else {
                return removeLabels
            }
            return removeLabels + [label.id]
        }
        DBManager.addRemoveLabelsFromThread(emailData.emails.first!.threadId, addedLabelIds: labels, removedLabelIds: labelsToRemove)
        if !(labels.contains(mailboxData.selectedLabel) || (labels.isEmpty && mailboxData.selectedLabel != SystemLabel.all.id)) {
            mailboxData.removeSelectedRow = true
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    func moveTo(labelId: Int) {
        let removeLabelsArray = (mailboxData.selectedLabel == SystemLabel.draft.id
            || mailboxData.selectedLabel == SystemLabel.sent.id) ? [] : [mailboxData.selectedLabel]
        DBManager.addRemoveLabelsFromThread(emailData.emails.first!.threadId, addedLabelIds: [labelId], removedLabelIds: removeLabelsArray)
        if(labelId != mailboxData.selectedLabel){
            mailboxData.removeSelectedRow = true
        }
        self.navigationController?.popViewController(animated: true)
    }
}
