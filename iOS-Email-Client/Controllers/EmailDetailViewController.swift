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
    var mailboxData : MailboxData?
    @IBOutlet weak var emailsTableView: UITableView!
    @IBOutlet weak var topToolbar: NavigationToolbarView!
    @IBOutlet weak var moreOptionsContainerView: DetailMoreOptionsUIView!
    @IBOutlet weak var generalOptionsContainerView: GeneralMoreOptionsUIView!
    
    var myHeaderView : UIView?
    var optionsEmail : Email?
    var markAsRead : Bool {
        get {
            var value = false
            for email in emailData.emails {
                if(email.unread){
                    value = true
                }
            }
            return value
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.topToolbar.isHidden = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.topToolbar.isHidden = false
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
        for index in 0..<self.emailData.emails.count{
            let nib = UINib(nibName: "EmailDetailTableCell", bundle: nil)
            self.emailsTableView.register(nib, forCellReuseIdentifier: "emailDetail\(index)")
        }
    }
    
    func displayMarkIcon(){
        if(markAsRead){
            topToolbar.setupMarkAsRead()
        } else {
            topToolbar.setupMarkAsUnread()
        }
        topToolbar.setItemsMenu()
    }
}

extension EmailDetailViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "emailDetail\(indexPath.row)") as! EmailTableViewCell
        let email = emailData.emails[indexPath.row]
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
        displayMarkIcon()
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
        default:
            return
        }
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
        optionsEmail = emailData.emails[indexPath.row]
        onReplyPress()
    }
    
    func handleUnsendTap(_ cell: EmailTableViewCell, _ sender: UIView){
        let unsentPopover = UnsentUIPopover()
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
        optionsEmail = emailData.emails[indexPath.row]
        toggleMoreOptionsView()
    }
    
    @objc func toggleMoreOptionsView(){
        guard moreOptionsContainerView.isHidden else {
            moreOptionsContainerView.closeMoreOptions()
            optionsEmail = nil
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
    
    func transitionToComposer(initParamsHandler: (ComposeViewController) -> Void){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composeVC = navComposeVC.viewControllers.first as! ComposeViewController
        initParamsHandler(composeVC)
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func onPressReply() {
        transitionToComposer { (composeVC) in
            guard let lastEmail = emailData.emails.last,
                let lastContact = emailData.emails.last?.fromContact else {
                    return
            }
            if(lastContact.email == "myaccount\(Constants.domain)"){
                composeVC.initToContacts.append(contentsOf: emailData.emails.last!.getContacts(type: .to))
            } else {
                composeVC.initToContacts.append(lastContact)
            }
            composeVC.initSubject = emailData.subject.starts(with: "Re: ") ? emailData.subject : "Re: \(emailData.subject)"
            let replyBody = ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(lastEmail.getFullDate()), \(lastContact.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + lastEmail.content + "</blockquote>")
            
            composeVC.initContent = replyBody
        }
    }
    
    func onPressReplyAll() {
        transitionToComposer { (composeVC) in
            guard let lastEmail = emailData.emails.last,
                let lastContact = emailData.emails.last?.fromContact else {
                    return
            }
            for email in emailData.emails {
                if(email.fromContact!.email != "myaccount\(Constants.domain)"){
                    composeVC.initToContacts.append(email.fromContact!)
                }
                composeVC.initToContacts.append(email.fromContact!)
            }
            composeVC.initSubject = emailData.subject.starts(with: "Re: ") ? emailData.subject : "Re: \(emailData.subject)"
            let replyBody = ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(lastEmail.getFullDate()), \(lastContact.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + lastEmail.content + "</blockquote>")
            
            composeVC.initContent = replyBody
        }
    }
    
    func onPressForward() {
        transitionToComposer { (composeVC) in
            guard let lastEmail = emailData.emails.last,
                let lastContact = emailData.emails.last?.fromContact else {
                    return
            }
            composeVC.initSubject = emailData.subject.starts(with: "Fw: ") ? emailData.subject : "Fw: \(emailData.subject)"
            let replyBody = ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(lastEmail.getFullDate()), \(lastContact.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + lastEmail.content + "</blockquote>")
            
            composeVC.initContent = replyBody
        }
    }
}

extension EmailDetailViewController: NavigationToolbarDelegate {
    func onBackPress() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func onArchiveThreads() {
        let archiveAction = UIAlertAction(title: "Yes", style: .default){ (alert : UIAlertAction!) -> Void in
            self.setLabels(labels: [])
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        showAlert("Archive Threads", message: "The selected threads will be displayed only in ALL MAIL", style: .alert, actions: [archiveAction, cancelAction])
    }
    
    func onTrashThreads() {
        let archiveAction = UIAlertAction(title: "Yes", style: .destructive){ (alert : UIAlertAction!) -> Void in
            self.setLabels(labels: [SystemLabel.trash.id])
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        showAlert("Delete Threads", message: "The selected threads will be moved to Trash", style: .alert, actions: [archiveAction, cancelAction])
    }
    
    func onMarkThreads() {
        let unread = !markAsRead
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
        moreOptionsContainerView.closeMoreOptions()
        optionsEmail = nil
        guard let email = optionsEmail else {
            self.onPressReply()
            return
        }
        transitionToComposer { (composeVC) in
            if(email.fromContact!.email == "myaccount\(Constants.domain)"){
                composeVC.initToContacts.append(contentsOf: email.getContacts(type: .to))
            } else {
                composeVC.initToContacts.append(email.fromContact!)
            }
            composeVC.initSubject = email.subject.starts(with: "Re: ") ? email.subject : "Re: \(email.subject)"
            let replyBody = ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(email.getFullDate()), \(email.fromContact!.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + email.content + "</blockquote>")
            
            composeVC.initContent = replyBody
        }
    }
    
    func onReplyAllPress() {
        self.toggleMoreOptionsView()
        guard let email = optionsEmail else {
            self.onPressReply()
            return
        }
        transitionToComposer { (composeVC) in
            for email in emailData.emails {
                if(email.fromContact!.email != "myaccount\(Constants.domain)"){
                    composeVC.initToContacts.append(email.fromContact!)
                }
                composeVC.initCcContacts.append(contentsOf: email.getContacts(type: .cc))
            }
            composeVC.initSubject = email.subject.starts(with: "Re: ") ? email.subject : "Re: \(email.subject)"
            let replyBody = ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(email.getFullDate()), \(email.fromContact!.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + email.content + "</blockquote>")
            
            composeVC.initContent = replyBody
        }
    }
    
    func onForwardPress() {
        self.toggleMoreOptionsView()
        guard let email = optionsEmail else {
            self.onPressReply()
            return
        }
        transitionToComposer { (composeVC) in
            composeVC.initSubject = email.subject.starts(with: "Fw: ") ? email.subject : "Fw: \(email.subject)"
            let replyBody = ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(email.getFullDate()), \(email.fromContact!.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + email.content + "</blockquote>")
            
            composeVC.initContent = replyBody
        }
    }
    
    func onDeletePress() {
        //TO DO
    }
    
    func onMarkPress() {
        //TO DO
    }
    
    func onSpamPress() {
        //TO DO
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
    
    func setLabels(labels: [Int]) {
        let myLabels = emailData.labels
        var removeMailboxRow = false
        let labelsToRemove = myLabels.reduce([Int]()) { (removeLabels, label) -> [Int] in
            guard !labels.contains(where: {$0 == label.id}) else {
                return removeLabels
            }
            if(label.id == mailboxData?.selectedLabel){
                removeMailboxRow = true
            }
            return removeLabels + [label.id]
        }
        DBManager.addRemoveLabelsFromThread(emailData.emails.first!.threadId, addedLabelIds: labels, removedLabelIds: labelsToRemove)
        mailboxData?.removeSelectedRow = removeMailboxRow
        self.navigationController?.popViewController(animated: true)
    }
    
    func moveTo(labelId: Int) {
        DBManager.addRemoveLabelsFromThread(emailData.emails.first!.threadId, addedLabelIds: [labelId], removedLabelIds: [mailboxData!.selectedLabel])
        mailboxData?.removeSelectedRow = true
        self.navigationController?.popViewController(animated: true)
    }
}
