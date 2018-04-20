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
    @IBOutlet weak var emailsTableView: UITableView!
    @IBOutlet weak var topToolbar: NavigationToolbarView!
    @IBOutlet weak var moreOptionsContainerView: DetailMoreOptionsUIView!
    
    var myHeaderView : UIView?
    var optionsEmail : Email?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        self.setupToolbar()
        self.setupMoreOptionsViews()
        
        self.registerCellNibs()
        self.topToolbar.toolbarDelegate = self
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
    func onPressReply() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composeVC = navComposeVC.viewControllers.first as! ComposeViewController
        
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
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func onPressReplyAll() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composeVC = navComposeVC.viewControllers.first as! ComposeViewController
        
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
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func onPressForward() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composeVC = navComposeVC.viewControllers.first as! ComposeViewController
        
        guard let lastEmail = emailData.emails.last,
            let lastContact = emailData.emails.last?.fromContact else {
                return
        }
        composeVC.initSubject = emailData.subject.starts(with: "Fw: ") ? emailData.subject : "Fw: \(emailData.subject)"
        let replyBody = ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(lastEmail.getFullDate()), \(lastContact.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + lastEmail.content + "</blockquote>")
        
        composeVC.initContent = replyBody
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
}

extension EmailDetailViewController: NavigationToolbarDelegate {
    func onBackPress() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func onArchiveThreads() {
        //TO DO
    }
    
    func onTrashThreads() {
        //TO DO
    }
    
    func onMarkThreads() {
        //TO DO
    }
    
    func onMoreOptions() {
        toggleMoreOptionsView()
    }
}

extension EmailDetailViewController: DetailMoreOptionsViewDelegate {
    func onReplyPress() {
        self.toggleMoreOptionsView()
        guard let email = optionsEmail else {
            self.onPressReply()
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composeVC = navComposeVC.viewControllers.first as! ComposeViewController

        if(email.fromContact!.email == "myaccount\(Constants.domain)"){
            composeVC.initToContacts.append(contentsOf: email.getContacts(type: .to))
        } else {
            composeVC.initToContacts.append(email.fromContact!)
        }
        composeVC.initSubject = email.subject.starts(with: "Re: ") ? email.subject : "Re: \(email.subject)"
        let replyBody = ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(email.getFullDate()), \(email.fromContact!.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + email.content + "</blockquote>")
        
        composeVC.initContent = replyBody
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true)
    }
    
    func onReplyAllPress() {
        self.toggleMoreOptionsView()
        guard let email = optionsEmail else {
            self.onPressReply()
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composeVC = navComposeVC.viewControllers.first as! ComposeViewController
        
        for email in emailData.emails {
            if(email.fromContact!.email != "myaccount\(Constants.domain)"){
                composeVC.initToContacts.append(email.fromContact!)
            }
            composeVC.initCcContacts.append(contentsOf: email.getContacts(type: .cc))
        }
        composeVC.initSubject = email.subject.starts(with: "Re: ") ? email.subject : "Re: \(email.subject)"
        let replyBody = ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(email.getFullDate()), \(email.fromContact!.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + email.content + "</blockquote>")
        
        composeVC.initContent = replyBody
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true)
    }
    
    func onForwardPress() {
        self.toggleMoreOptionsView()
        guard let email = optionsEmail else {
            self.onPressReply()
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composeVC = navComposeVC.viewControllers.first as! ComposeViewController

        composeVC.initSubject = email.subject.starts(with: "Fw: ") ? email.subject : "Fw: \(email.subject)"
        let replyBody = ("<br><pre class=\"criptext-remove-this\"></pre>" + "On \(email.getFullDate()), \(email.fromContact!.email) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + email.content + "</blockquote>")
        
        composeVC.initContent = replyBody
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true)
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
