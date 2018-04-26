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
    @IBOutlet weak var topToolbar: NavigationToolbarView!
    @IBOutlet weak var buttonCompose: UIButton!
    
    var searchController = UISearchController(searchResultsController: nil)
    var spaceBarButton:UIBarButtonItem!
    var fixedSpaceBarButton:UIBarButtonItem!
    var flexibleSpaceBarButton:UIBarButtonItem!
    var cancelBarButton:UIBarButtonItem!
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
    
    var footerView:UIView!
    var footerActivity:UIActivityIndicatorView!
    
    let statusBarButton = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
    
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
        
        self.footerView = UIView(frame: CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 40.0))
        self.footerView.backgroundColor = UIColor.clear
        self.footerActivity = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        self.footerActivity.hidesWhenStopped = true
        self.footerView.addSubview(self.footerActivity)
        self.footerActivity.center = self.footerView.center
        self.tableView.tableFooterView = self.footerView
        
        self.originalNavigationRect = self.navigationController?.navigationBar.frame
        
        self.startNetworkListener()
        
        self.searchController.searchResultsUpdater = self as UISearchResultsUpdating
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        definesPresentationContext = true
        
        self.navigationItem.searchController = self.searchController
        self.tableView.allowsMultipleSelection = true

        self.initBarButtonItems()
        
        self.setButtonItems(isEditing: false)
        self.loadMails(from: mailboxData.selectedLabel, since: Date())
        
        self.navigationItem.leftBarButtonItems = [self.menuButton, self.fixedSpaceBarButton, self.titleBarButton, self.countBarButton]
        
        self.initFloatingButton()
        topToolbar.toolbarDelegate = self
        self.initMoreOptionsView()
        refreshControl.addTarget(self, action: #selector(getPendingEvents(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
        WebSocketManager.sharedInstance.addListener(identifier: "mailbox", listener: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let indexPath = self.tableView.indexPathForSelectedRow, !mailboxData.isCustomEditing else {
            return
        }
        
        if(mailboxData.removeSelectedRow){
            mailboxData.emailArray.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            mailboxData.removeSelectedRow = false
        }else{
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.tableView.reloadRows(at: [indexPath], with: .none)
        }
        
        guard let indexArray = self.tableView.indexPathsForVisibleRows,
            let index = indexArray.first,
            index.row == 0,
            !self.searchController.isActive else {
            return
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        self.footerView.frame = CGRect(origin: self.footerView.frame.origin, size: CGSize(width: size.width, height: self.footerView.frame.size.height) )
        
        self.footerActivity.frame = CGRect(origin: self.footerActivity.frame.origin, size: CGSize(width: size.width / 2, height: self.footerActivity.frame.size.height) )
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
            let eventsArray = data as! Array<Dictionary<String, Any>>
            let eventHandler = EventHandler(account: self.myAccount)
            eventHandler.eventDelegate = self
            eventHandler.handleEvents(events: eventsArray)
        }
    }
}

extension InboxViewController: EventHandlerDelegate {
    func didReceiveNewEmails() {
        loadMails(from: mailboxData.selectedLabel, since: Date())
    }
}

//MARK: - Modify mails actions
extension InboxViewController{
    @objc func didPressEdit(reload: Bool) {
        mailboxData.isCustomEditing = !mailboxData.isCustomEditing
        
        if mailboxData.isCustomEditing {
            self.topToolbar.counterButton.title = "1"
            self.topToolbar.isHidden = false
            refreshControl.isEnabled = false
        }else{
            self.topToolbar.isHidden = true
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.navigationBar.frame = self.originalNavigationRect
            refreshControl.isEnabled = true
            mailboxData.unreadMails = 0
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
        mailboxData.selectedLabel = labelId
        loadMails(from: labelId, since: Date())
        titleBarButton.title = SystemLabel(rawValue: labelId)?.description.uppercased()
        self.navigationDrawerController?.closeLeftView()
    }
    
    func swapMarkIcon(){
        if(mailboxData.unreadMails > 0){
            topToolbar.setupMarkAsRead()
        }else{
            topToolbar.setupMarkAsUnread()
        }
        topToolbar.setItemsMenu()
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
            let index = mailboxData.emailArray.index(of: firstMail) else {
                mailboxData.threadToOpen = threadId
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        print("selecting cell")
        
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.tableView(self.tableView , didSelectRowAt: indexPath)
        
        mailboxData.threadToOpen = nil
    }
    
    func loadMails(from label: Int, since date:Date){
        let tuple = DBManager.getMails(from: label, since: date)
        mailboxData.emailArray = tuple.1
        self.tableView.reloadData()
        
        //@TODO: remove return statement and paginate mails from db
        return
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
    func navigationDrawerController(navigationDrawerController: NavigationDrawerController, willOpen position: NavigationDrawerPosition) {
        self.updateAppIcon()
    }
    
    func updateAppIcon() {
        //check mails for badge
    }
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "InboxTableViewCell", for: indexPath) as! InboxTableViewCell
        cell.delegate = self
        let email:Email
        if self.searchController.isActive && self.searchController.searchBar.text != "" {
            email = mailboxData.filteredEmailArray[indexPath.row]
        }else {
            email = mailboxData.emailArray[indexPath.row]
        }
        
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
        
        cell.subjectLabel.text = email.subject == "" ? "(No Subject)" : email.subject
        cell.senderLabel.text = email.fromContact?.displayName ?? "Unknown"
        cell.previewLabel.text = email.preview
        cell.dateLabel.text = DateUtils.conversationTime(email.date)
        
        let size = cell.dateLabel.sizeThatFits(CGSize(width: 130, height: 21))
        cell.dateWidthConstraint.constant = size.width
        
        if mailboxData.isCustomEditing {
            if(cell.isSelected){
                cell.backgroundColor = UIColor(red:253/255, green:251/255, blue:235/255, alpha:1.0)
                cell.avatarImageView.layer.backgroundColor = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.0).cgColor
                cell.avatarImageView.image = #imageLiteral(resourceName: "check")
                cell.avatarImageView.tintColor = UIColor.white
            } else {
                cell.avatarImageView.image = nil
                cell.avatarImageView.layer.borderWidth = 1.0
                cell.avatarImageView.layer.borderColor = UIColor.lightGray.cgColor
                cell.avatarImageView.layer.backgroundColor = UIColor.lightGray.cgColor
            }
        } else {
            let initials = cell.senderLabel.text!.replacingOccurrences(of: "\"", with: "")
            cell.avatarImageView.setImageForName(string: initials, circular: true, textAttributes: nil)
            cell.avatarImageView.layer.borderWidth = 0.0
        }
        
        guard let emailArrayHash = mailboxData.threadHash[email.threadId], emailArrayHash.count > 1 else{
            cell.containerBadge.isHidden = true
            cell.badgeWidthConstraint.constant = 0
            return cell
        }
        
        //check if unread among thread mails
        if emailArrayHash.contains(where: { return $0.unread }) {
            cell.backgroundColor = UIColor(red:0.96, green:0.98, blue:1.00, alpha:1.0)
            cell.senderLabel.font = Font.bold.size(17)
            cell.subjectLabel.font = Font.bold.size(17)
        }
        
        cell.containerBadge.isHidden = false
        
        switch emailArrayHash.count {
        case _ where emailArrayHash.count > 9:
            cell.badgeWidthConstraint.constant = 20
            break
        case _ where emailArrayHash.count > 99:
            cell.badgeWidthConstraint.constant = 25
            break
        default:
            cell.badgeWidthConstraint.constant = 20
            break
        }
        
        cell.badgeLabel.text = String(emailArrayHash.count)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchController.isActive && self.searchController.searchBar.text != "" {
            return mailboxData.filteredEmailArray.count
        }
        return mailboxData.emailArray.count
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
            let email = mailboxData.emailArray[indexPath.row]
            if(email.unread){
                mailboxData.unreadMails += 1
            }
            swapMarkIcon()
            let cell = tableView.cellForRow(at: indexPath) as! InboxTableViewCell
            cell.backgroundColor = UIColor(red:253/255, green:251/255, blue:235/255, alpha:1.0)
            cell.avatarImageView.layer.backgroundColor = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.0).cgColor
            cell.avatarImageView.image = #imageLiteral(resourceName: "check")
            cell.avatarImageView.tintColor = UIColor.white
            self.topToolbar.counterButton.title = "\(indexPaths.count)"
            return
        }
        
        let selectedEmail = mailboxData.emailArray[indexPath.row]
        let emails = DBManager.getMailsbyThreadId(selectedEmail.threadId)
        let emailDetailData = EmailDetailData()
        emailDetailData.emails = emails
        emailDetailData.labels += emails.first!.labels
        emailDetailData.subject = emails.first!.subject
        emailDetailData.accountEmail = "\(myAccount.username)\(Constants.domain)"
        
        emails.last?.isExpanded = true
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if mailboxData.selectedLabel != SystemLabel.draft.id {
            let vc = storyboard.instantiateViewController(withIdentifier: "EmailDetailViewController") as! EmailDetailViewController
            vc.emailData = emailDetailData
            vc.mailboxData = self.mailboxData
            self.navigationController?.pushViewController(vc, animated: true)
            return
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        guard mailboxData.isCustomEditing else {
            return
        }
        
        guard tableView.indexPathsForSelectedRows == nil else {
            let email = mailboxData.emailArray[indexPath.row]
            if(email.unread){
                mailboxData.unreadMails -= 1
            }
            swapMarkIcon()
            self.topToolbar.counterButton.title = "\(tableView.indexPathsForSelectedRows!.count)"
            tableView.reloadRows(at: [indexPath], with: .none)
            return
        }
        
        self.didPressEdit(reload: true)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let lastEmail = (self.searchController.isActive  && self.searchController.searchBar.text != "") ? mailboxData.filteredEmailArray.last : mailboxData.emailArray.last,
            let threadEmailArray = mailboxData.threadHash[lastEmail.threadId], let firstThreadEmail = threadEmailArray.first else {
                return
        }
        
        let email:Email
        if self.searchController.isActive && self.searchController.searchBar.text != "" {
            email = mailboxData.filteredEmailArray[indexPath.row]
        }else {
            email = mailboxData.emailArray[indexPath.row]
        }
        if email == lastEmail {
            if(searchController.searchBar.text == ""){
                self.loadMails(from: mailboxData.selectedLabel, since: firstThreadEmail.date!)
            }
            else{
                self.loadSearchedMails()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 79.0
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard mailboxData.selectedLabel != SystemLabel.trash.id else {
            return []
        }
        
        let trashAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "         ") { (action, index) in
            
            if self.searchController.isActive && self.searchController.searchBar.text != "" {
                let emailRemoved = self.mailboxData.filteredEmailArray.remove(at: indexPath.row)
                guard let index = self.mailboxData.emailArray.index(of: emailRemoved) else {
                    return
                }
                self.mailboxData.emailArray.remove(at: index)
            }else {
                self.mailboxData.emailArray.remove(at: indexPath.row)
            }
            
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        trashAction.backgroundColor = UIColor(patternImage: UIImage(named: "trash-action")!)
        
        return [trashAction];
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}



//MARK: - Search Delegate
extension InboxViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
    
    func filterContentForSearchText(searchText: String, scope: String = "All") {
        mailboxData.filteredEmailArray = mailboxData.emailArray.filter { email in
            return email.content.lowercased().contains(searchText.lowercased())
                || email.subject.lowercased().contains(searchText.lowercased())
        }
        
        self.tableView.reloadData()
        
        if(searchText != ""){
            self.loadSearchedMails()
        }
    }
    
    func loadSearchedMails(){
        //search emails
    }
    
    func addSearchedFetched(_ emails:[Email]){
        mailboxData.filteredEmailArray.removeAll()
        for email in emails {
            DBManager.store(email)
            
            if mailboxData.threadHash[email.threadId] == nil {
                mailboxData.threadHash[email.threadId] = []
            }
            
            var threadArray = mailboxData.threadHash[email.threadId]!
            
            if !threadArray.contains(email){
                mailboxData.threadHash[email.threadId]!.append(email)
            }
            
            threadArray.sort(by: { $0.date?.compare($1.date!) == ComparisonResult.orderedDescending })
            
            if !mailboxData.filteredEmailArray.contains(where: { $0.threadId == email.threadId }) {
                mailboxData.filteredEmailArray.append(email)
            }
            
            if let dummyEmail = mailboxData.filteredEmailArray.first(where: { $0.threadId == email.threadId }),
                let index = mailboxData.filteredEmailArray.index(of: dummyEmail), email.date! > dummyEmail.date! {
                mailboxData.filteredEmailArray[index] = email
            }
        }
        
        mailboxData.filteredEmailArray.sort(by: { $0.date?.compare($1.date!) == ComparisonResult.orderedDescending })
        
        self.tableView.reloadData()
    }
}

extension InboxViewController : LabelsUIPopoverDelegate{
    
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
        if let indexPaths = tableView.indexPathsForSelectedRows{
            for indexPath in indexPaths {
                let email = mailboxData.emailArray[indexPath.row]
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
    
    func setLabels(labels: [Int]) {
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        self.didPressEdit(reload: true)
        var indexPathsToRemove = [IndexPath]()
        for indexPath in indexPaths {
            var removeEmail = false
            let email = mailboxData.emailArray[indexPath.row]
            let labelsToRemove = email.labels.reduce([Int]()) { (removeLabels, label) -> [Int] in
                guard !labels.contains(label.id) else {
                    return removeLabels
                }
                if(label.id == mailboxData.selectedLabel){
                    removeEmail = true
                }
                return removeLabels + [label.id]
            }
            if(removeEmail){
                indexPathsToRemove.append(indexPath)
                mailboxData.emailArray.remove(at: indexPath.row)
            }
            DBManager.addRemoveLabelsFromThread(email.threadId, addedLabelIds: labels, removedLabelIds: labelsToRemove)
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
            let email = mailboxData.emailArray[indexPath.row]
            DBManager.addRemoveLabelsFromThread(email.threadId, addedLabelIds: [labelId], removedLabelIds: [mailboxData.selectedLabel])
            mailboxData.emailArray.remove(at: indexPath.row)
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
            self.archiveSelectedThreads()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        showAlert("Archive Threads", message: "The selected threads will be displayed only in ALL MAIL", style: .alert, actions: [archiveAction, cancelAction])
    }
    
    func onTrashThreads() {
        let archiveAction = UIAlertAction(title: "Yes", style: .destructive){ (alert : UIAlertAction!) -> Void in
            self.deleteSelectedThreads()
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
            let email = mailboxData.emailArray[indexPath.row]
            DBManager.updateEmail(email, unread: unread)
        }
        self.didPressEdit(reload: true)
    }
    
    func deleteSelectedThreads() {
        handleSelectedThreads(addedLabelIds: [SystemLabel.trash.id])
    }
    
    func archiveSelectedThreads(){
        handleSelectedThreads(addedLabelIds: [])
    }
    
    func handleSelectedThreads(addedLabelIds: [Int]){
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        self.didPressEdit(reload: true)
        for indexPath in indexPaths {
            let email = mailboxData.emailArray[indexPath.row]
            let labelsToRemove = email.labels.reduce([Int]()) { (labels, label) -> [Int] in
                guard label.id != SystemLabel.sent.id && label.id != SystemLabel.draft.id else {
                    return labels
                }
                return labels + [label.id]
            }
            DBManager.addRemoveLabelsFromThread(email.threadId, addedLabelIds: [], removedLabelIds: labelsToRemove)
            mailboxData.emailArray.remove(at: indexPath.row)
        }
        self.tableView.deleteRows(at: indexPaths, with: .left)
    }
    
    func onMoreOptions() {
        toggleMoreOptions()
    }
}
