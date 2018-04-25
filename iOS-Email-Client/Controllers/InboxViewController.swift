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
    
    var myAccount: Account!
    var originalNavigationRect:CGRect!
    var mailboxData = MailboxData()
    var searchMode : Bool {
        get {
            return self.searchController.isActive && self.searchController.searchBar.text != ""
        }
    }
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
        definesPresentationContext = true
        
        self.navigationItem.searchController = self.searchController
        self.tableView.allowsMultipleSelection = true

        self.initBarButtonItems()
        
        self.setButtonItems(isEditing: false)
        
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
        updateBadges()
        
        guard !searchMode,
            let indexPath = self.tableView.indexPathForSelectedRow, !mailboxData.isCustomEditing else {
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
        mailboxData.reachedEnd = false
        mailboxData.selectedLabel = labelId
        mailboxData.fetchWorker?.cancel()
        loadMails(from: labelId, since: Date(), clear: true)
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
    
    func updateBadges(){
        guard let menuViewController = navigationDrawerController?.leftViewController as? MenuViewController else {
                return
        }
        menuViewController.refreshBadges()
        let label =  SystemLabel(rawValue: mailboxData.selectedLabel) ?? .all
        let mailboxCounter = label == .draft
            ? DBManager.getMails(from: mailboxData.selectedLabel, since: Date(), limit: 100).1.count
            : DBManager.getUnreadMails(from: mailboxData.selectedLabel).count
        countBarButton.title = mailboxCounter > 0 ? "(\(mailboxCounter.description))" : ""
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
        
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.tableView(self.tableView , didSelectRowAt: indexPath)
        
        mailboxData.threadToOpen = nil
    }
    
    func loadMails(from label: Int, since date:Date, clear: Bool = false){
        let tuple = DBManager.getMails(from: label, since: date)
        mailboxData.loading = false
        if(clear){
            mailboxData.emailArray = tuple.1
        } else {
            mailboxData.emailArray.append(contentsOf: tuple.1)
        }
        if(tuple.1.count == 0){
            mailboxData.reachedEnd = true
        }
        self.tableView.reloadData()
        updateBadges()
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
        let email:Email
        if searchMode {
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
        let fromContact = email.fromContact!
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
        if searchMode {
            return mailboxData.filteredEmailArray.count + 1
        }
        return mailboxData.emailArray.count + 1
    }
    
    func createFooterView() -> UITableViewCell {
        let footerView = tableView.dequeueReusableCell(withIdentifier: "EndCell") as! TableEndViewCell
        guard !mailboxData.reachedEnd else {
            footerView.displayMessage("No more emails to load")
            return footerView
        }
        footerView.displayLoader()
        if(!mailboxData.loading){
            mailboxData.loading = true
            mailboxData.fetchWorker = DispatchWorkItem(block: {
                if self.searchMode {
                    self.loadSearchedMails(since: self.mailboxData.filteredEmailArray.last?.date ?? Date())
                }else {
                    self.loadMails(from: self.mailboxData.selectedLabel, since: self.mailboxData.emailArray.last?.date ?? Date())
                }
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: mailboxData.fetchWorker!)
        }
        return footerView
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
            cell.setAsSelected()
            self.topToolbar.counterButton.title = "\(indexPaths.count)"
            return
        }
        
        let selectedEmail = searchMode ? mailboxData.filteredEmailArray[indexPath.row] : mailboxData.emailArray[indexPath.row]
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 79.0
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard mailboxData.selectedLabel != SystemLabel.trash.id else {
            return []
        }
        
        let trashAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "         ") { (action, index) in
            
            if self.searchMode {
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
        mailboxData.reachedEnd = false
        mailboxData.loading = false
        mailboxData.fetchWorker?.cancel()
        if(searchText != ""){
            self.loadSearchedMails(since: Date(), clear: true)
        } else {
            tableView.reloadData()
        }
    }
    
    func loadSearchedMails(since: Date, clear: Bool = false){
        guard let searchParam = self.searchController.searchBar.text else {
            return
        }
        let emails = DBManager.getMails(since: since, searchParam: searchParam)
        if(clear){
            mailboxData.filteredEmailArray = emails
        }else{
            mailboxData.filteredEmailArray.append(contentsOf: emails)
        }
        if(emails.count == 0){
            mailboxData.reachedEnd = true
        }
        mailboxData.loading = false
        tableView.reloadData()
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
