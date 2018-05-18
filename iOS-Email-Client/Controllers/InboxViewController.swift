//
//  ViewController.swift
//  Criptext Secure Email

//
//  Created by Gianni Carlo on 3/3/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import UIKit
import Material
import SDWebImage
import SwiftWebSocket
import MIBadgeButton_Swift
import SwiftyJSON
import SignalProtocolFramework

//delete
import RealmSwift

class InboxViewController: UIViewController {
    
    @IBOutlet weak var moreOptionsOverlay: UIView!
    @IBOutlet weak var moreOptionsView: UIView!
    @IBOutlet weak var bottomMarginConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    @IBOutlet weak var topToolbar: TopbarUIView!
    @IBOutlet weak var buttonCompose: UIButton!
    
    var searchController = UISearchController(searchResultsController: nil)
    var spaceBarButton:UIBarButtonItem!
    var fixedSpaceBarButton:UIBarButtonItem!
    var flexibleSpaceBarButton:UIBarButtonItem!
    var searchBarButton:UIBarButtonItem!
    var activityBarButton:UIBarButtonItem!
    var composerBarButton:UIBarButtonItem!
    var trashBarButton:UIBarButtonItem!
    var archiveBarButton:UIBarButtonItem!
    var moveBarButton:UIBarButtonItem!
    var markBarButton:UIBarButtonItem!
    var deleteBarButton:UIBarButtonItem!
    var menuButton:UIBarButtonItem!
    var counterBarButton:UIBarButtonItem!
    var titleBarButton = UIBarButtonItem(title: "INBOX", style: .plain, target: nil, action: nil)
    var countBarButton = UIBarButtonItem(title: "(12)", style: .plain, target: nil, action: nil)
    
    let statusBarButton = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
    
    @IBOutlet weak var envelopeImageView: UIImageView!
    @IBOutlet weak var envelopeTitleView: UILabel!
    @IBOutlet weak var envelopeSubtitleView: UILabel!
    @IBOutlet weak var envelopeView: UIView!
    
    var myAccount: Account!
    var originalNavigationRect:CGRect!
    var mailboxData = MailboxData()

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.addSubview(self.topToolbar)
        let margins = self.navigationController!.navigationBar.layoutMarginsGuide
        self.topToolbar.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: -8.0).isActive = true
        self.topToolbar.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 8.0).isActive = true
        self.topToolbar.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: 8.0).isActive = true
        self.navigationController?.navigationBar.bringSubview(toFront: self.topToolbar)
        
        self.tableView.register(UINib(nibName: "TableEndViewCell", bundle: nil), forCellReuseIdentifier: "EndCell")
        
        self.originalNavigationRect = self.navigationController?.navigationBar.frame
        
        self.startNetworkListener()
        
        self.searchController.searchResultsUpdater = self as UISearchResultsUpdating
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.barStyle = .black
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "NunitoSans-Regular", size: 18.0)!, NSAttributedStringKey.foregroundColor: UIColor(red:0.73, green:0.73, blue:0.74, alpha:1.0)], for: .normal)
        
        self.navigationItem.searchController = self.searchController
        self.tableView.allowsMultipleSelection = true

        self.initBarButtonItems()
        
        self.setButtonItems(isEditing: false)
        
        self.navigationItem.leftBarButtonItems = [self.menuButton, self.fixedSpaceBarButton, self.titleBarButton, self.countBarButton]
        
        self.initFloatingButton()
        topToolbar.delegate = self
        self.initMoreOptionsView()
        refreshControl.addTarget(self, action: #selector(getPendingEvents(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        WebSocketManager.sharedInstance.eventDelegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(deleteDraft(notification:)), name: .onDeleteDraft, object: nil)        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBadges()
        
        guard let indexPath = self.tableView.indexPathForSelectedRow, !mailboxData.isCustomEditing else {
            return
        }
        
        guard !mailboxData.removeSelectedRow else {
            mailboxData.emails.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            mailboxData.removeSelectedRow = false
            return
        }
        let email = mailboxData.emails[indexPath.row]
        guard let refreshedRowEmail = DBManager.getThreadEmail(threadId: email.threadId, label: mailboxData.selectedLabel),
            email.key == refreshedRowEmail.key else {
            refreshEmailRows()
            return
        }
        mailboxData.emails[indexPath.row] = refreshedRowEmail
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func initBarButtonItems(){
        self.spaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        self.fixedSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        self.fixedSpaceBarButton.width = 25.0
        self.flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        self.titleBarButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "NunitoSans-Bold", size: 16.0)!, NSAttributedStringKey.foregroundColor: UIColor.white], for: .disabled)
        self.titleBarButton.isEnabled = false
        self.countBarButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "NunitoSans-Bold", size: 16.0)!, NSAttributedStringKey.foregroundColor: UIColor(red:0.73, green:0.73, blue:0.74, alpha:1.0)], for: .disabled)
        self.countBarButton.isEnabled = false
        
        self.menuButton = UIBarButtonItem(image: #imageLiteral(resourceName: "menu_white"), style: .plain, target: self, action: #selector(didPressOpenMenu(_:)))
        self.menuButton.tintColor = UIColor.white
        self.searchBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "search"), style: .plain, target: self, action: #selector(didPressSearch(_:)))
        self.searchBarButton.tintColor = UIColor(red:0.73, green:0.73, blue:0.74, alpha:1.0)
        
        // Set batButtonItems
        let activityButton = MIBadgeButton(type: .custom)
        activityButton.badgeString = ""
        activityButton.frame = CGRect(x:0, y:0, width:16.8, height:20.7)
        activityButton.badgeEdgeInsets = UIEdgeInsetsMake(25, 12, 0, 10)
        activityButton.setImage(#imageLiteral(resourceName: "activity"), for: .normal)
        activityButton.tintColor = UIColor.white
        activityButton.addTarget(self, action: #selector(didPressActivityMenu), for: UIControlEvents.touchUpInside)
        self.activityBarButton = UIBarButtonItem(customView: activityButton)
        
        self.activityBarButton.tintColor = UIColor.white
        
        let font:UIFont = Font.regular.size(13)!
        let attributes:[NSAttributedStringKey : Any] = [NSAttributedStringKey.font: font];
        self.statusBarButton.setTitleTextAttributes(attributes, for: .normal)
        self.statusBarButton.tintColor = UIColor.darkGray
    }
    
    func initFloatingButton(){
        let shadowPath = UIBezierPath(rect: CGRect(x: 15, y: 15, width: 30, height: 30))
        buttonCompose.layer.shadowColor = UIColor(red: 0, green: 145/255, blue: 255/255, alpha: 1).cgColor
        buttonCompose.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)  //Here you control x and y
        buttonCompose.layer.shadowOpacity = 1
        buttonCompose.layer.shadowRadius = 15 //Here your control your blur
        buttonCompose.layer.masksToBounds =  false
        buttonCompose.layer.shadowPath = shadowPath.cgPath
    }
    
    func initMoreOptionsView(){
        moreOptionsView.isHidden = true
        moreOptionsOverlay.isHidden = true
        moreOptionsOverlay.alpha = 0.0
        bottomMarginConstraint.constant = -98.0
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleMoreOptions))
        self.moreOptionsOverlay.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func toggleMoreOptions(){
        guard self.moreOptionsView.isHidden else {
            closeMoreOptions()
            return
        }
        showMoreOptions()
    }
    
    func showMoreOptions(){
        self.moreOptionsView.isHidden = false
        self.moreOptionsOverlay.isHidden = false
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
            self.bottomMarginConstraint.constant = 0.0
            self.moreOptionsOverlay.alpha = 1.0
            self.view.layoutIfNeeded()
        })
    }
    
    func closeMoreOptions(){
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            self.bottomMarginConstraint.constant = -98.0
            self.moreOptionsOverlay.alpha = 0.0
            self.view.layoutIfNeeded()
        }, completion: {
            finished in
            self.moreOptionsView.isHidden = true
            self.moreOptionsOverlay.isHidden = true
        })
    }
    
    func startNetworkListener(){
        APIManager.reachabilityManager.startListening()
        APIManager.reachabilityManager.listener = { status in
            
            switch status {
            case .notReachable, .unknown:
                //do nothing
                self.showSnackbar("Offline", attributedText: nil, buttons: "", permanent: false)
                break
            default:
                //try to reconnect
                //retry saving drafts and sending emails
                break
            }
        }
    }
    
    @IBAction func onMoveToPress(_ sender: Any) {
        handleMoveTo()
    }
    
    @IBAction func onAddLabelsPress(_ sender: Any) {
        handleAddLabels()
    }
    
    @objc func getPendingEvents(_ refreshControl: UIRefreshControl?) {
        APIManager.getEvents(token: myAccount.jwt) { (error, data) in
            refreshControl?.endRefreshing()
            guard error == nil else {
                print(error.debugDescription)
                return
            }
            guard let eventsArray = data as? Array<Dictionary<String, Any>> else {
                return
            }
            let eventHandler = EventHandler(account: self.myAccount)
            eventHandler.eventDelegate = self
            eventHandler.handleEvents(events: eventsArray)
        }
    }
}

extension InboxViewController: EventHandlerDelegate {
    func didReceiveNewEmails(emails: [Email]) {
        guard !mailboxData.searchMode && emails.contains(where: {$0.labels.contains(where: {$0.id == mailboxData.selectedLabel})}) else {
            return
        }
        refreshEmailRows()
    }
    
    func refreshEmailRows(){
        loadMails(since: Date(), clear: true, limit: tableView.numberOfRows(inSection: 0))
    }
}

//MARK: - Modify mails actions
extension InboxViewController{
    @objc func didPressEdit(reload: Bool) {
        mailboxData.isCustomEditing = !mailboxData.isCustomEditing
        
        if mailboxData.isCustomEditing {
            self.topToolbar.counterLabel.text = "1"
            self.topToolbar.isHidden = false
            refreshControl.isEnabled = false
        }else{
            self.topToolbar.isHidden = true
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.navigationBar.frame = self.originalNavigationRect
            refreshControl.isEnabled = true
            mailboxData.unreadMails = 0
            updateBadges()
        }
        
        self.setButtonItems(isEditing: mailboxData.isCustomEditing)
        if(reload){
            self.tableView.reloadData()
        }
    }
    
    @IBAction func didPressComposer(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func swapMailbox(labelId: Int, sender: Any?){
        if mailboxData.isCustomEditing {
            didPressEdit(reload: true)
        }
        mailboxData.selectedLabel = labelId
        mailboxData.cancelFetchWorker()
        loadMails(since: Date(), clear: true)
        titleBarButton.title = SystemLabel(rawValue: labelId)?.description.uppercased()
        self.navigationDrawerController?.closeLeftView()
    }
    
    func swapMarkIcon(){
        topToolbar.swapMarkTo(unread: mailboxData.unreadMails == 0)
    }
    
    func updateBadges(){
        guard let menuViewController = navigationDrawerController?.leftViewController as? MenuViewController else {
                return
        }
        menuViewController.refreshBadges()
        let label =  SystemLabel(rawValue: mailboxData.selectedLabel) ?? .all
        let mailboxCounter = label == .draft
            ? DBManager.getMails(from: mailboxData.selectedLabel, since: Date(), limit: 100).count
            : DBManager.getUnreadMails(from: mailboxData.selectedLabel).count
        countBarButton.title = mailboxCounter > 0 ? "(\(mailboxCounter.description))" : ""
    }
    
    @objc func deleteDraft(notification: NSNotification){
        guard let data = notification.userInfo,
            let draftId = data["draftId"] as? String,
            let draftIndex = mailboxData.emails.index(where: {$0.key == draftId}) else {
                return
        }
        mailboxData.emails.remove(at: draftIndex)
        tableView.reloadData()
    }
}

//MARK: - Side menu events
extension InboxViewController {
    @objc func didPressActivityMenu(){
        self.navigationDrawerController?.openRightView()
    }
    
    @IBAction func didPressOpenMenu(_ sender: UIBarButtonItem) {
        self.navigationDrawerController?.toggleLeftView()
    }
    
    @IBAction func didPressSearch(_ sender: UIBarButtonItem) {
        self.searchController.searchBar.becomeFirstResponder()
    }
}

//MARK: - UIBarButton layout
extension InboxViewController{
    func setButtonItems(isEditing: Bool){
        
        guard isEditing else {
            self.navigationItem.rightBarButtonItems = [self.activityBarButton, self.searchBarButton, self.spaceBarButton]
            self.navigationItem.leftBarButtonItems = [self.menuButton, self.fixedSpaceBarButton, self.titleBarButton, self.countBarButton]
            return
        }
        
        self.navigationItem.leftBarButtonItems = []
        self.navigationItem.rightBarButtonItems = []
    }
}

//MARK: - Load mails
extension InboxViewController{
    func open(threadId:String) {
        
        guard let threadArray = mailboxData.threadHash[threadId],
            let firstMail = threadArray.first,
            let index = mailboxData.emails.index(of: firstMail) else {
                mailboxData.threadToOpen = threadId
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.tableView(self.tableView , didSelectRowAt: indexPath)
        
        mailboxData.threadToOpen = nil
    }
    
    func loadMails(since date:Date, clear: Bool = false, limit: Int = 0){
        let emails : [Email]
        if (mailboxData.searchMode) {
            guard let searchParam = self.searchController.searchBar.text else {
                return
            }
            emails = DBManager.getMails(since: date, searchParam: searchParam)
        } else {
            emails = DBManager.getMails(from: mailboxData.selectedLabel, since: date, limit: limit)
        }
        if(clear){
            mailboxData.emails = emails
        } else {
            mailboxData.emails.append(contentsOf: emails)
        }
        mailboxData.reachedEnd = emails.isEmpty
        mailboxData.fetchWorker = nil
        self.tableView.reloadData()
        updateBadges()
        showNoEmailsView(mailboxData.reachedEnd && mailboxData.emails.isEmpty)
    }
}

//MARK: - Google SignIn Delegate
extension InboxViewController{
    
    func signout(){
        DBManager.signout()
        UIApplication.shared.applicationIconBadgeNumber = 0
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let vc = storyboard.instantiateInitialViewController()!
        
        self.navigationController?.childViewControllers.last!.present(vc, animated: true){
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.replaceRootViewController(vc)
        }
    }
}

//MARK: - GestureRecognizer Delegate
extension InboxViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        let touchPt = touch.location(in: self.view)
        
        guard self.view.hitTest(touchPt, with: nil) != nil else {
            return true
        }
        
        return true
    }
}

//MARK: - NavigationDrawerController Delegate
extension InboxViewController: NavigationDrawerControllerDelegate {
    func navigationDrawerController(navigationDrawerController: NavigationDrawerController, didClose position: NavigationDrawerPosition) {
        guard position == .right,
            let feedVC = navigationDrawerController.rightViewController as? FeedViewController else {
            return
        }
        feedVC.feedsTableView.isEditing = false
    }
    
}

//MARK: - TableView Datasource
extension InboxViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(tableView.numberOfRows(inSection: 0) == indexPath.row + 1){
            return createFooterView()
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "InboxTableViewCell", for: indexPath) as! InboxTableViewCell
        cell.delegate = self
        let email = mailboxData.emails[indexPath.row]
        
        let isSentFolder = mailboxData.selectedLabel == SystemLabel.sent.id
        
        cell.secureAttachmentImageView.isHidden = true
        cell.secureAttachmentImageView.tintColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0)
        
        //Set row status
        if !email.unread || isSentFolder {
            cell.backgroundColor = UIColor(red:244/255, green:244/255, blue:244/255, alpha:1.0)
            cell.senderLabel.font = Font.regular.size(15)
        }else{
            cell.backgroundColor = UIColor.white
            cell.senderLabel.font = Font.bold.size(15)
        }
        let fromContact = email.fromContact
        if(fromContact.email == "\(myAccount.username)@jigl.com"){
            cell.senderLabel.text = email.getContactsString()
        }else{
            cell.senderLabel.text = fromContact.displayName
        }
        cell.subjectLabel.text = email.subject == "" ? "(No Subject)" : email.subject
        cell.previewLabel.text = email.preview
        cell.dateLabel.text = DateUtils.conversationTime(email.date)
        
        let size = cell.dateLabel.sizeThatFits(CGSize(width: 130, height: 21))
        cell.dateWidthConstraint.constant = size.width
        
        if mailboxData.isCustomEditing {
            if(cell.isSelected){
                cell.setAsSelected()
            } else {
                cell.setAsNotSelected()
            }
        } else {
            let initials = cell.senderLabel.text!.replacingOccurrences(of: "\"", with: "")
            cell.avatarImageView.setImageForName(string: initials, circular: true, textAttributes: nil)
            cell.avatarImageView.layer.borderWidth = 0.0
        }
        
        cell.setBadge(email.counter)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mailboxData.emails.count + 1
    }
    
    func createFooterView() -> UITableViewCell {
        let footerView = tableView.dequeueReusableCell(withIdentifier: "EndCell") as! TableEndViewCell
        guard !mailboxData.reachedEnd else {
            footerView.displayMessage("")
            return footerView
        }
        footerView.displayLoader()
        if(mailboxData.fetchWorker == nil){
            mailboxData.fetchWorker = DispatchWorkItem(block: {
                self.loadMails(since: self.mailboxData.emails.last?.date ?? Date())
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: mailboxData.fetchWorker!)
        }
        return footerView
    }
    
    func showNoEmailsView(_ show: Bool){
        envelopeView.isHidden = !show
        guard show else {
            return
        }
        guard !mailboxData.searchMode else {
            setEnvelopeMessages(title: "No search results", subtitle: "Trash and Spam are not displayed")
            return
        }
        switch(mailboxData.selectedLabel){
        case SystemLabel.inbox.id:
            setEnvelopeMessages(title: "There are no emails in your inbox", subtitle: "share your email address with a friend")
        case SystemLabel.sent.id:
            setEnvelopeMessages(title: "You have no emails sent", subtitle: "let's send one!")
        case SystemLabel.draft.id:
            setEnvelopeMessages(title: "There are no drafts", subtitle: "That's ok")
        case SystemLabel.spam.id:
            setEnvelopeMessages(title: "There's no spam", subtitle: "Cool!")
        case SystemLabel.trash.id:
            setEnvelopeMessages(title: "There's no trash", subtitle: "What a clean place!")
        default:
            setEnvelopeMessages(title: "There are no emails", subtitle: "It's a matter of time")
        }
    }
    
    func setEnvelopeMessages(title: String, subtitle: String){
        envelopeTitleView.text = title
        envelopeSubtitleView.text = subtitle
    }
}

//MARK: - TableView Delegate
extension InboxViewController: InboxTableViewCellDelegate, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    func tableViewCellDidLongPress(_ cell: InboxTableViewCell) {
        
        if mailboxData.isCustomEditing {
            return
        }
        
        self.didPressEdit(reload: false)
        
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        
        if self.tableView.indexPathsForSelectedRows == nil {
            tableView.reloadData()
        }
        
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.tableView(self.tableView , didSelectRowAt: indexPath)
    }
    
    func tableViewCellDidTap(_ cell: InboxTableViewCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        if cell.isSelected {
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.tableView(tableView, didDeselectRowAt: indexPath)
            return
        }
        
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.tableView(self.tableView , didSelectRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if mailboxData.isCustomEditing {
            guard let indexPaths = tableView.indexPathsForSelectedRows else {
                return
            }
            let email = mailboxData.emails[indexPath.row]
            if(email.unread){
                mailboxData.unreadMails += 1
            }
            swapMarkIcon()
            let cell = tableView.cellForRow(at: indexPath) as! InboxTableViewCell
            cell.setAsSelected()
            self.topToolbar.counterLabel.text = "\(indexPaths.count)"
            return
        }
        
        let selectedEmail = mailboxData.emails[indexPath.row]
        let showOnlyDraft = selectedEmail.threadId.isEmpty && selectedEmail.labels.contains(where: {$0.id == SystemLabel.draft.id})
        let emails = DBManager.getThreadEmails(selectedEmail.threadId, label: mailboxData.selectedLabel)
        let emailDetailData = EmailDetailData(threadId: selectedEmail.threadId, label: mailboxData.searchMode ? SystemLabel.all.id : mailboxData.selectedLabel)
        emailDetailData.emails = showOnlyDraft ? [selectedEmail] : emails
        var labelsSet = Set<Label>()
        for email in emails {
            email.isExpanded = email.unread
            labelsSet.formUnion(email.labels)
        }
        emailDetailData.labels = Array(labelsSet)
        emailDetailData.subject = emails.first!.subject
        emailDetailData.accountEmail = "\(myAccount.username)\(Constants.domain)"
        emails[emails.count - 1].isExpanded = true
        
        guard mailboxData.selectedLabel != SystemLabel.draft.id else {
            continueDraft(selectedEmail)
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmailDetailViewController") as! EmailDetailViewController
        vc.emailData = emailDetailData
        vc.mailboxData = self.mailboxData
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func continueDraft(_ draft: Email){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composerVC = navComposeVC.viewControllers.first as! ComposeViewController
        let composerData = ComposerData()
        composerData.initToContacts = Array(draft.getContacts(type: .to))
        composerData.initCcContacts = Array(draft.getContacts(type: .cc))
        composerData.initSubject = draft.subject
        composerData.initContent = draft.content
        composerData.emailDraft = draft
        composerVC.composerData = composerData
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        guard mailboxData.isCustomEditing else {
            return
        }
        
        guard tableView.indexPathsForSelectedRows == nil else {
            let email = mailboxData.emails[indexPath.row]
            if(email.unread){
                mailboxData.unreadMails -= 1
            }
            swapMarkIcon()
            self.topToolbar.counterLabel.text = "\(tableView.indexPathsForSelectedRows!.count)"
            tableView.reloadRows(at: [indexPath], with: .none)
            return
        }
        
        self.didPressEdit(reload: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 79.0
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard mailboxData.selectedLabel != SystemLabel.trash.id else {
            return []
        }
        
        let trashAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "         ") { (action, index) in
            let email = self.mailboxData.emails[indexPath.row]
            DBManager.setLabelsForEmail(email, labels: [SystemLabel.trash.id])
            self.mailboxData.emails.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        trashAction.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "trash-action"))
        
        return [trashAction];
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !mailboxData.isCustomEditing && !mailboxData.searchMode
    }
}



//MARK: - Search Delegate
extension InboxViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        mailboxData.searchMode = self.searchController.isActive && !searchController.searchBar.text!.isEmpty
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(searchText: String) {
        mailboxData.cancelFetchWorker()
        if(!mailboxData.searchMode){
            showNoEmailsView(mailboxData.reachedEnd && mailboxData.emails.isEmpty)
            tableView.reloadData()
        } else {
            mailboxData.reachedEnd = false
            self.loadMails(since: Date(), clear: true)
        }
    }
}

extension InboxViewController : LabelsUIPopoverDelegate{
    
    func getMoveableLabels() -> [Label] {
        let labels = DBManager.getLabels()
        return labels.reduce([Label](), { (moveableLabels, label) -> [Label] in
            guard let systemLabel = SystemLabel.init(rawValue: label.id) else {
                return moveableLabels + [label]
            }
            guard systemLabel != .draft && systemLabel != .sent else {
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
        if let indexPaths = tableView.indexPathsForSelectedRows{
            for indexPath in indexPaths {
                let email = mailboxData.emails[indexPath.row]
                for label in email.labels {
                    labelsPopover.selectedLabels[label.id] = label
                }
            }
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
            self.bottomMarginConstraint.constant = -98.0
            self.moreOptionsView.isHidden = true
            self.moreOptionsOverlay.alpha = 0.0
            self.moreOptionsOverlay.isHidden = true
            self.view.layoutIfNeeded()
        }
    }
    
    func setLabels(_ labels: [Int]) {
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        self.didPressEdit(reload: true)
        var indexPathsToRemove = [IndexPath]()
        for indexPath in indexPaths {
            let email = mailboxData.emails[indexPath.row]
            if !(labels.contains(mailboxData.selectedLabel) || (labels.isEmpty && mailboxData.selectedLabel != SystemLabel.all.id)) {
                indexPathsToRemove.append(indexPath)
                mailboxData.emails.remove(at: indexPath.row)
            }
            DBManager.setLabelsForThread(email.threadId, labels: labels, currentLabel: mailboxData.selectedLabel)
        }
        self.tableView.deleteRows(at: indexPathsToRemove, with: .left)
    }
    
    func moveTo(labelId: Int) {
        guard labelId != mailboxData.selectedLabel,
            let indexPaths = tableView.indexPathsForSelectedRows else {
            self.didPressEdit(reload: true)
            return
        }
        self.didPressEdit(reload: true)
        for indexPath in indexPaths {
            let email = mailboxData.emails[indexPath.row]
            DBManager.setLabelsForThread(email.threadId, labels: [labelId], currentLabel: mailboxData.selectedLabel)
            mailboxData.emails.remove(at: indexPath.row)
        }
        self.tableView.deleteRows(at: indexPaths, with: .left)
    }
}

extension InboxViewController: NavigationToolbarDelegate {
    func onBackPress() {
        guard !mailboxData.isCustomEditing else {
            self.didPressEdit(reload: true)
            return
        }
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
            self.setLabels([SystemLabel.trash.id])
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        showAlert("Delete Threads", message: "The selected threads will be moved to Trash", style: .alert, actions: [archiveAction, cancelAction])
    }
    
    func onMarkThreads() {
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        let unread = mailboxData.unreadMails <= 0
        for indexPath in indexPaths {
            let email = mailboxData.emails[indexPath.row]
            DBManager.updateEmail(email, unread: unread)
        }
        self.didPressEdit(reload: true)
    }
    
    func onMoreOptions() {
        toggleMoreOptions()
    }
}
