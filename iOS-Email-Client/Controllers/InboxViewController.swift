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
        self.definesPresentationContext = true
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
        NotificationCenter.default.addObserver(self, selector: #selector(refreshNewEmail(notification:)), name: .onNewEmail, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBadges()
        
        guard let indexPath = self.tableView.indexPathForSelectedRow, !mailboxData.isCustomEditing else {
            return
        }
        
        guard !mailboxData.removeSelectedRow else {
            mailboxData.threads.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            mailboxData.removeSelectedRow = false
            return
        }
        let thread = mailboxData.threads[indexPath.row]
        guard let refreshedRowThread = DBManager.getThread(threadId: thread.threadId, label: mailboxData.selectedLabel),
            thread.lastEmail.key == refreshedRowThread.lastEmail.key else {
            refreshThreadRows()
            return
        }
        mailboxData.threads[indexPath.row] = refreshedRowThread
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
    func didReceiveOpens(opens: [FeedItem]) {
        guard let feedVC = self.navigationDrawerController?.rightViewController as? FeedViewController else {
                return
        }
        feedVC.loadFeeds(clear: true)
    }
    
    func didReceiveNewEmails(emails: [Email]) {
        guard !mailboxData.searchMode && emails.contains(where: {$0.labels.contains(where: {$0.id == mailboxData.selectedLabel})}) else {
            return
        }
        refreshThreadRows()
    }
    
    func refreshThreadRows(){
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
        topToolbar.swapLeftIcon(labelId: labelId)
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
            ? DBManager.getThreads(from: mailboxData.selectedLabel, since: Date(), limit: 100).count
            : DBManager.getUnreadMails(from: mailboxData.selectedLabel).count
        countBarButton.title = mailboxCounter > 0 ? "(\(mailboxCounter.description))" : ""
    }
    
    @objc func deleteDraft(notification: NSNotification){
        guard let data = notification.userInfo,
            let draftId = data["draftId"] as? String,
            let draftIndex = mailboxData.threads.index(where: {$0.lastEmail.key == draftId}) else {
                return
        }
        mailboxData.threads.remove(at: draftIndex)
        tableView.reloadData()
    }
    
    @objc func refreshNewEmail(notification: NSNotification){
        guard let data = notification.userInfo,
            let email = data["email"] as? Email,
            email.labels.contains(where: {$0.id == mailboxData.selectedLabel}) else {
                return
        }
        refreshThreadRows()
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
    func loadMails(since date:Date, clear: Bool = false, limit: Int = 0){
        let threads : [Thread]
        if (mailboxData.searchMode) {
            guard let searchParam = self.searchController.searchBar.text else {
                return
            }
            threads = DBManager.getThreads(since: date, searchParam: searchParam)
        } else {
            threads = DBManager.getThreads(from: mailboxData.selectedLabel, since: date, limit: limit)
        }
        if(clear){
            mailboxData.threads = threads
        } else {
            mailboxData.threads.append(contentsOf: threads)
        }
        mailboxData.reachedEnd = threads.isEmpty
        mailboxData.fetchWorker = nil
        self.tableView.reloadData()
        updateBadges()
        showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
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
        feedVC.viewClosed()
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
        let thread = mailboxData.threads[indexPath.row]
        
        let isSentFolder = mailboxData.selectedLabel == SystemLabel.sent.id
        
        cell.secureAttachmentImageView.isHidden = true
        cell.secureAttachmentImageView.tintColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0)
        
        //Set row status
        if !thread.unread || isSentFolder {
            cell.backgroundColor = UIColor(red:244/255, green:244/255, blue:244/255, alpha:1.0)
            cell.senderLabel.font = Font.regular.size(15)
        }else{
            cell.backgroundColor = UIColor.white
            cell.senderLabel.font = Font.bold.size(15)
        }
        
        let participants = thread.getContactsString()
        let useTo = mailboxData.selectedLabel == SystemLabel.sent.id || mailboxData.selectedLabel == SystemLabel.draft.id
        cell.senderLabel.text = participants.isEmpty ? "<Empty Contact List>" : "\(useTo ? "To: " : "")\(participants)"
        cell.subjectLabel.text = thread.subject == "" ? "(No Subject)" : thread.subject
        cell.previewLabel.text = thread.preview
        cell.dateLabel.text = thread.getFormattedDate()
        cell.setReadStatus(status: thread.status)
        
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
        
        cell.setBadge(thread.counter)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mailboxData.threads.count + 1
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
                self.loadMails(since: self.mailboxData.threads.last?.lastEmail.date ?? Date())
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: mailboxData.fetchWorker!)
        }
        return footerView
    }
    
    func showNoThreadsView(_ show: Bool){
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
    
    func goToSettings(){
        self.navigationDrawerController?.closeLeftView()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let generalVC = storyboard.instantiateViewController(withIdentifier: "settingsGeneralViewController") as! SettingsGeneralViewController
        let labelsVC = storyboard.instantiateViewController(withIdentifier: "settingsLabelsViewController")
        let devicesVC = storyboard.instantiateViewController(withIdentifier: "settingsDevicesViewController")
        generalVC.myAccount = self.myAccount
        let tabsVC = CustomTabsController(viewControllers: [generalVC, labelsVC, devicesVC])
        tabsVC.edgesForExtendedLayout = []
        tabsVC.tabBarAlignment = .top
        let tabBar = tabsVC.tabBar
        tabBar.setLineColor(.mainUI, for: .selected)
        tabBar.layer.masksToBounds = false
        
        let frame = CGRect(x: 0, y: tabBar.layer.height/2, width: self.view.frame.width, height: 6)
        let backgroundView = UIView(frame: frame)
        tabBar.addSubview(backgroundView)
        
        let topColor = UIColor.black
        let bottomColor = UIColor.clear
        let gradientColors: [CGColor] = [topColor.cgColor, bottomColor.cgColor]
        let gradientLocations: [CGFloat] = [0.0, 1.0]
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = gradientColors
        gradientLayer.locations = gradientLocations as [NSNumber]?
        gradientLayer.frame = frame
        gradientLayer.opacity = 0.23
        backgroundView.layer.insertSublayer(gradientLayer, at: 0)
        backgroundView.layer.zPosition = 100
        
        let navSettingsVC = UINavigationController(rootViewController: tabsVC)
        navSettingsVC.navigationBar.barStyle = .blackTranslucent
        navSettingsVC.navigationBar.barTintColor = .lightText
        let attrs = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: Font.regular.size(17)!] as [NSAttributedStringKey : Any]
        navSettingsVC.navigationBar.titleTextAttributes = attrs
        self.navigationController?.childViewControllers.last!.present(navSettingsVC, animated: true, completion: nil)
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
            let thread = mailboxData.threads[indexPath.row]
            if(thread.unread){
                mailboxData.unreadMails += 1
            }
            swapMarkIcon()
            let cell = tableView.cellForRow(at: indexPath) as! InboxTableViewCell
            cell.setAsSelected()
            self.topToolbar.counterLabel.text = "\(indexPaths.count)"
            return
        }
        
        let selectedThread = mailboxData.threads[indexPath.row]
        goToEmailDetail(selectedThread: selectedThread, selectedLabel: mailboxData.selectedLabel)
    }
    
    func goToEmailDetail(selectedThread: Thread, selectedLabel: Int){
        self.navigationDrawerController?.closeRightView()
        
        guard mailboxData.selectedLabel != SystemLabel.draft.id else {
            continueDraft(selectedThread.lastEmail)
            return
        }
        
        let emails = DBManager.getThreadEmails(selectedThread.threadId, label: selectedLabel)
        let emailDetailData = EmailDetailData(threadId: selectedThread.threadId, label: mailboxData.searchMode ? SystemLabel.all.id : selectedLabel)
        emailDetailData.emails = emails
        var labelsSet = Set<Label>()
        for email in emails {
            email.isExpanded = email.unread
            labelsSet.formUnion(email.labels)
        }
        emailDetailData.selectedLabel = selectedLabel
        emailDetailData.labels = Array(labelsSet)
        emailDetailData.subject = emails.first!.subject
        emailDetailData.accountEmail = "\(myAccount.username)\(Constants.domain)"
        emails[emails.count - 1].isExpanded = true
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmailDetailViewController") as! EmailDetailViewController
        vc.emailData = emailDetailData
        vc.mailboxData = self.mailboxData
        vc.myAccount = self.myAccount
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
        if(!draft.threadId.isEmpty){
            composerData.threadId = draft.threadId
        }
        composerVC.composerData = composerData
        for file in draft.files {
            file.requestStatus = .finish
            composerVC.fileManager.registeredFiles.append(file)
        }
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        guard mailboxData.isCustomEditing else {
            return
        }
        
        guard tableView.indexPathsForSelectedRows == nil else {
            let thread = mailboxData.threads[indexPath.row]
            if(thread.unread){
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
            let thread = self.mailboxData.threads[indexPath.row]
            DBManager.setLabelsForEmail(thread.lastEmail, labels: [SystemLabel.trash.id])
            self.mailboxData.threads.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
        }
        
        trashAction.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "trash-action"))
        
        return [trashAction];
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != mailboxData.threads.count && !mailboxData.isCustomEditing && !mailboxData.searchMode
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
            showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
            tableView.reloadData()
        } else {
            mailboxData.reachedEnd = false
            self.loadMails(since: Date(), clear: true)
        }
    }
}

extension InboxViewController : LabelsUIPopoverDelegate{
    
    func handleAddLabels(){
        let labelsPopover = LabelsUIPopover.instantiate(type: .addLabels, selectedLabel: mailboxData.selectedLabel)
        if let indexPaths = tableView.indexPathsForSelectedRows{
            for indexPath in indexPaths {
                let email = mailboxData.threads[indexPath.row].lastEmail!
                for label in email.labels {
                    guard labelsPopover.labels.contains(where: {$0.id == label.id}) else {
                        continue
                    }
                    labelsPopover.selectedLabels[label.id] = label
                }
            }
        }
        presentPopover(labelsPopover, height: Constants.basePopoverHeight + labelsPopover.labels.count * Constants.labelPopoverHeight)
    }
    
    func handleMoveTo(){
        let labelsPopover = LabelsUIPopover.instantiate(type: .moveTo, selectedLabel: mailboxData.selectedLabel)
        presentPopover(labelsPopover, height: Constants.basePopoverHeight + labelsPopover.labels.count * Constants.labelPopoverHeight)
    }
    
    func presentPopover(_ popover: LabelsUIPopover, height: Int){
        popover.delegate = self
        popover.preparePopover(rootView: self, height: height)
        self.present(popover, animated: true){
            self.bottomMarginConstraint.constant = -98.0
            self.moreOptionsView.isHidden = true
            self.moreOptionsOverlay.alpha = 0.0
            self.moreOptionsOverlay.isHidden = true
            self.view.layoutIfNeeded()
        }
    }
    
    func setLabels(added: [Int], removed: [Int]) {
        setLabels(added: added, removed: removed, forceRemove: false)
    }
    
    func moveTo(labelId: Int) {
        let removeLabels = labelId == SystemLabel.all.id
            ? [SystemLabel.inbox.id]
            : mailboxData.selectedLabel == SystemLabel.trash.id && labelId == SystemLabel.spam.id ? [SystemLabel.trash.id] : []
        let addLabels = labelId == SystemLabel.all.id
            ? []
            : [labelId]
        setLabels(added: addLabels, removed: removeLabels, forceRemove: labelId == SystemLabel.trash.id || labelId == SystemLabel.spam.id)
    }
}

extension InboxViewController {
    func setLabels(added: [Int], removed: [Int], forceRemove: Bool = false) {
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        self.didPressEdit(reload: true)
        let orderedIndexPaths = indexPaths.sorted{$0.row > $1.row}
        let shouldRemoveItems = removed.contains(where: {$0 == mailboxData.selectedLabel}) || forceRemove
        for indexPath in orderedIndexPaths {
            let thread = mailboxData.threads[indexPath.row]
            DBManager.addRemoveLabelsForThreads(thread.threadId, addedLabelIds: added, removedLabelIds: removed, currentLabel: mailboxData.selectedLabel)
            if shouldRemoveItems {
                mailboxData.threads.remove(at: indexPath.row)
            }
        }
        if shouldRemoveItems {
            self.tableView.deleteRows(at: indexPaths, with: .left)
        }
        updateBadges()
        showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
    }
    
    func deleteThreads(){
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            self.didPressEdit(reload: true)
            return
        }
        self.didPressEdit(reload: true)
        let orderedIndexPaths = indexPaths.sorted{$0.row > $1.row}
        for indexPath in orderedIndexPaths {
            let thread = mailboxData.threads[indexPath.row]
            DBManager.deleteThreads(thread.threadId, label: mailboxData.selectedLabel)
            mailboxData.threads.remove(at: indexPath.row)
        }
        self.tableView.deleteRows(at: indexPaths, with: .left)
        updateBadges()
        showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
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
        guard mailboxData.selectedLabel == SystemLabel.trash.id || mailboxData.selectedLabel == SystemLabel.draft.id || mailboxData.selectedLabel == SystemLabel.spam.id || mailboxData.selectedLabel == SystemLabel.all.id else {
            self.moveTo(labelId: SystemLabel.all.id)
            return
        }
        guard mailboxData.selectedLabel != SystemLabel.draft.id && mailboxData.selectedLabel != SystemLabel.all.id else {
            setLabels(added: [SystemLabel.inbox.id], removed: [])
            return
        }
        setLabels(added: [], removed: [mailboxData.selectedLabel])
    }
    
    func onTrashThreads() {
        guard mailboxData.selectedLabel == SystemLabel.trash.id || mailboxData.selectedLabel == SystemLabel.spam.id || mailboxData.selectedLabel == SystemLabel.draft.id else {
            self.setLabels(added: [SystemLabel.trash.id], removed: [], forceRemove: true)
            return
        }
        let archiveAction = UIAlertAction(title: "Ok", style: .destructive){ (alert : UIAlertAction!) -> Void in
            self.deleteThreads()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        showAlert("Delete Threads", message: "The selected threads will be PERMANENTLY deleted", style: .alert, actions: [archiveAction, cancelAction])
    }
    
    func onMarkThreads() {
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        let unread = mailboxData.unreadMails <= 0
        for indexPath in indexPaths {
            let thread = mailboxData.threads[indexPath.row]
            DBManager.updateEmail(thread.lastEmail, unread: unread)
        }
        self.didPressEdit(reload: true)
    }
    
    func onMoreOptions() {
        toggleMoreOptions()
    }
}
