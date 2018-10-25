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
import AudioToolbox
import RealmSwift
import Instructions
import FirebaseAnalytics

class InboxViewController: UIViewController {
    let BOTTOM_PADDING : CGFloat = 18.0
    let SNACKBAR_PADDING : CGFloat = 83.0
    
    @IBOutlet weak var generalOptionsContainerView: GeneralMoreOptionsUIView!
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
    @IBOutlet weak var composeButtonBottomConstraint: NSLayoutConstraint!
    
    var myAccount: Account!
    var originalNavigationRect:CGRect!
    var mailboxData = MailboxData()
    let coachMarksController = CoachMarksController()
    var currentGuide = "guideComposer"

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let headerNib = UINib(nibName: "MailboxHeaderUITableCell", bundle: nil)
        self.tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "InboxHeaderTableViewCell")
        
        self.navigationController?.navigationBar.addSubview(self.topToolbar)
        let margins = self.navigationController!.navigationBar.layoutMarginsGuide
        self.topToolbar.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: -8.0).isActive = true
        self.topToolbar.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 8.0).isActive = true
        self.topToolbar.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: 8.0).isActive = true
        self.navigationController?.navigationBar.bringSubview(toFront: self.topToolbar)
        
        self.tableView.register(UINib(nibName: "TableEndViewCell", bundle: nil), forCellReuseIdentifier: "EndCell")
        
        self.originalNavigationRect = self.navigationController?.navigationBar.frame
        
        self.startNetworkListener()
        
        self.edgesForExtendedLayout = UIRectEdge()
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
        self.generalOptionsContainerView.delegate = self
        refreshControl.addTarget(self, action: #selector(getPendingEvents(_:completion:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        WebSocketManager.sharedInstance.delegate = self
        self.generalOptionsContainerView.handleCurrentLabel(currentLabel: mailboxData.selectedLabel)
        
        self.coachMarksController.overlay.allowTap = true
        self.coachMarksController.overlay.color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85)
        self.coachMarksController.dataSource = self
        emptyTrash(from: Date.init(timeIntervalSinceNow: -30*24*60*60), failSilently: true)
        getPendingEvents(nil)        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendFailEmail()
        presentWelcomeTour()
    }
    
    func showGuide(){
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: "guideComposer") {
            currentGuide = "guideComposer"
            self.coachMarksController.start(on: self)
            defaults.set(true, forKey: "guideComposer")
        } else if !defaults.bool(forKey: "guideFeed"),
            let feedVC = navigationDrawerController?.rightViewController as? FeedViewController,
            feedVC.feedsData.newFeeds.count > 0 {
            currentGuide = "guideFeed"
            self.coachMarksController.start(on: self)
            defaults.set(true, forKey: "guideFeed")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateBadges()
        
        guard let indexPath = self.tableView.indexPathForSelectedRow, !mailboxData.isCustomEditing else {
            mailboxData.removeSelectedRow = false
            return
        }
        
        guard !mailboxData.removeSelectedRow else {
            mailboxData.threads.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            mailboxData.removeSelectedRow = false
            updateBadges()
            showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
            return
        }
        let thread = mailboxData.threads[indexPath.row]
        guard !thread.lastEmail.isInvalidated,
            let refreshedRowThread = DBManager.getThread(threadId: thread.threadId, label: mailboxData.selectedLabel),
            thread.lastEmail.key == refreshedRowThread.lastEmail.key else {
            refreshThreadRows()
            return
        }
        mailboxData.threads[indexPath.row] = refreshedRowThread
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.tableView.reloadRows(at: [indexPath], with: .none)
        updateBadges()
        showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.coachMarksController.stop(immediately: true)
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
        
        let menuImage = #imageLiteral(resourceName: "menu_white").tint(with: .white)
        let searchImage = #imageLiteral(resourceName: "search").tint(with: UIColor(red:0.73, green:0.73, blue:0.74, alpha:1.0))
        self.menuButton = UIBarButtonItem(image: menuImage, style: .plain, target: self, action: #selector(didPressOpenMenu(_:)))
        self.searchBarButton = UIBarButtonItem(image: searchImage, style: .plain, target: self, action: #selector(didPressSearch(_:)))
        
        // Set batButtonItems
        let activityButton = MIBadgeButton(type: .custom)
        let badgeCounter = DBManager.getNewFeedsCount(since: myAccount.lastTimeFeedOpened)
        activityButton.badgeString = badgeCounter > 0 ? badgeCounter.description : ""
        activityButton.frame = CGRect(x:0, y:0, width: 16, height: 20)
        activityButton.badgeEdgeInsets = UIEdgeInsetsMake(0, 1, 2, 0)
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
    
    @objc func toggleMoreOptions(){
        guard generalOptionsContainerView.isHidden else {
            generalOptionsContainerView.closeMoreOptions()
            return
        }
        generalOptionsContainerView.showMoreOptions()
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
    
    func presentWelcomeTour(){
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "welcomeTour") else {
            self.showGuide()
            return
        }
        
        let welcomeTourVC = WelcomeTourViewController(nibName: "WelcomeTourView", bundle: nil)
        welcomeTourVC.modalPresentationStyle = .overCurrentContext
        welcomeTourVC.modalTransitionStyle = .crossDissolve
        welcomeTourVC.onDismiss = {
            self.showGuide()
            defaults.set(true, forKey: "welcomeTour")
        }
        self.present(welcomeTourVC, animated: false, completion: nil)
    }
}

extension InboxViewController: WebSocketManagerDelegate {
    func newMessage(result: EventData.Socket){
        switch(result){
        case .LinkStart(let data):
            self.handleLinkStart(data: data)
        case .NewEvent:
            self.getPendingEvents(nil)
        case .PasswordChange:
            self.presentPasswordPopover(myAccount: myAccount)
        case .Logout:
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            delegate.logout()
        case .RecoveryChanged(let address):
            guard let nav = self.presentedViewController as? UINavigationController,
                let settings = nav.childViewControllers.first as? CustomTabsController else {
                return
            }
            settings.generalData.recoveryEmail = address
            settings.generalData.recoveryEmailStatus = .pending
            settings.generalData.isTwoFactor = false
            settings.reloadChildViews()
        case .RecoveryVerified:
            guard let nav = self.presentedViewController as? UINavigationController,
                let settings = nav.childViewControllers.first as? CustomTabsController else {
                    return
            }
            settings.generalData.recoveryEmailStatus = .verified
            settings.reloadChildViews()
        default:
            break
        }
    }
    
    func handleLinkStart(data: [String: Any]){
        guard let linkData = LinkData.fromDictionary(data) else {
            return
        }
        self.presentLinkDevicePopover(linkData: linkData)
    }
}

extension InboxViewController {
    
    @objc func getPendingEvents(_ refreshControl: UIRefreshControl?, completion: ((Bool) -> Void)? = nil) {
        guard !mailboxData.updating else {
            completion?(false)
            refreshControl?.endRefreshing()
            return
        }
        self.mailboxData.updating = true
        APIManager.getEvents(token: myAccount.jwt) { (responseData) in
            refreshControl?.endRefreshing()
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                completion?(false)
                self.mailboxData.updating = false
                self.showSnackbar(error.description, attributedText: nil, buttons: "", permanent: false)
                return
            }
            
            if case .Forbidden = responseData {
                completion?(false)
                self.mailboxData.updating = false
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            
            guard case let .SuccessArray(events) = responseData else {
                self.mailboxData.updating = false
                completion?(false)
                return
            }
            let eventHandler = EventHandler(account: self.myAccount)
            eventHandler.handleEvents(events: events){ result in
                self.mailboxData.updating = false
                self.didReceiveEvents(result: result)
                completion?(true)
            }
        }
    }
    
    func didReceiveEvents(result: EventData.Result) {
        guard !result.removed else {
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            delegate.logout()
            return
        }
        
        if !result.linkStartData.isEmpty {
            handleLinkStart(data: result.linkStartData)
        }
        
        if result.updateSideMenu {
            guard let menuViewController = navigationDrawerController?.leftViewController as? MenuViewController else {
                return
            }
            menuViewController.reloadView()
        }
        
        if result.emails.contains(where: {!$0.isInvalidated && $0.status != .unsent && !$0.isSent}) {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        let pathsToUpdate = result.opens.reduce([IndexPath]()) { (result, open) -> [IndexPath] in
            guard let index = mailboxData.threads.index(where: {$0.threadId == open.email.threadId}) else {
                return result
            }
            return result + [IndexPath(row: index, section: 0)]
        }
        
        if(shouldHardReload(result: result)){
            refreshThreadRows()
        } else {
            tableView.reloadRows(at: pathsToUpdate, with: .automatic)
        }
        notifyEmailDetailController(result: result)
        
        
        guard result.opens.count > 0,
            let feedVC = self.navigationDrawerController?.rightViewController as? FeedViewController else {
            return
        }
        let badgeCounter = feedVC.feedsData.newFeeds.count
        updateFeedsBadge(counter: badgeCounter)
    }
    
    func shouldHardReload(result: EventData.Result) -> Bool{
        if(result.modifiedEmailKeys.count > 0 || result.modifiedThreadIds.count > 0){
            return true
        }
        guard !mailboxData.searchMode && result.emails.contains(where: {$0.labels.contains(where: {$0.id == mailboxData.selectedLabel})}) else {
            return false
        }
        return true
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
        let composerVC = navComposeVC.viewControllers.first as! ComposeViewController
        composerVC.delegate = self
        
        self.present(snackVC, animated: true, completion: nil)
    }
    
    func swapMailbox(labelId: Int, sender: Any?){
        if mailboxData.isCustomEditing {
            didPressEdit(reload: true)
        }
        mailboxData.selectedLabel = labelId
        mailboxData.cancelFetchWorker()
        loadMails(since: Date(), clear: true)
        titleBarButton.title = SystemLabel(rawValue: labelId)?.description.uppercased() ?? DBManager.getLabel(labelId)!.text.uppercased()
        topToolbar.swapTrashIcon(labelId: labelId)
        self.generalOptionsContainerView.handleCurrentLabel(currentLabel: mailboxData.selectedLabel)
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
    
    func updateFeedsBadge(counter: Int){
        guard let activityButton = self.activityBarButton.customView as? MIBadgeButton else {
            return
        }
        activityButton.badgeString = counter > 0 ? counter.description : ""
    }
}

//MARK: - Side menu events
extension InboxViewController {
    @objc func didPressActivityMenu(){
        self.navigationDrawerController?.openRightView()
        self.coachMarksController.stop(immediately: true)
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
        
        self.present(vc, animated: true){
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
        DBManager.update(account: myAccount, lastSeen: Date())
        feedVC.feedsTableView.isEditing = false
        feedVC.viewClosed()
        let badgeCounter = feedVC.feedsData.newFeeds.count
        updateFeedsBadge(counter: badgeCounter)
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
        
        cell.setFields(thread: thread, label: mailboxData.selectedLabel, myEmail: "\(myAccount.username)\(Constants.domain)")
        
        if mailboxData.isCustomEditing {
            if(cell.isSelected){
                cell.setAsSelected()
            } else {
                cell.setAsNotSelected()
            }
        } else {
            let initials = thread.lastEmail.fromContact.displayName
            cell.avatarImageView.setImageForName(string: initials, circular: true, textAttributes: nil)
            cell.avatarImageView.layer.borderWidth = 0.0
        }
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
                self.loadMails(since: self.mailboxData.threads.last?.date ?? Date())
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: mailboxData.fetchWorker!)
        }
        return footerView
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard mailboxData.selectedLabel == SystemLabel.trash.id && !mailboxData.threads.isEmpty else {
            return nil
        }
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "InboxHeaderTableViewCell") as! InboxHeaderUITableCell
        cell.contentView.backgroundColor = UIColor(red: 242/255, green: 248/255, blue: 1, alpha: 1)
        cell.onEmptyPress = {
            self.showEmptyTrashWarning()
        }
        return cell
    }
    
    func showEmptyTrashWarning() {
        let emptyAction = UIAlertAction(title: String.localize("Yes"), style: .destructive){ (alert : UIAlertAction!) -> Void in
            self.emptyTrash()
        }
        let cancelAction = UIAlertAction(title: String.localize("Cancel"), style: .cancel)
        showAlert(String.localize("Empty Trash"), message: String.localize("All your emails in Trash are going to be deleted PERMANENTLY. Do you want to continue?"), style: .alert, actions: [emptyAction, cancelAction])
    }
    
    func emptyTrash(from date: Date = Date(), failSilently: Bool = false){
        guard let threadIds = DBManager.getTrashThreads(from: date),
            !threadIds.isEmpty else {
            return
        }
        let eventData = EventData.Peer.ThreadDeleted(threadIds: threadIds)
        postPeerEvent(["cmd": Event.Peer.threadsDeleted.rawValue, "params": eventData.asDictionary()], failSilently: failSilently) {
            DBManager.deleteThreads(threadIds: threadIds)
            self.refreshThreadRows()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard mailboxData.selectedLabel == SystemLabel.trash.id && !mailboxData.threads.isEmpty else {
            return 0.0
        }
        return 95.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func showNoThreadsView(_ show: Bool){
        envelopeView.isHidden = !show
        guard show else {
            return
        }
        guard !mailboxData.searchMode else {
            setEnvelopeMessages(title: String.localize("No search results"), subtitle: String.localize("Trash and Spam are not displayed"))
            return
        }
        switch(mailboxData.selectedLabel){
        case SystemLabel.inbox.id:
            setEnvelopeMessages(title: String.localize("There are no emails"), subtitle: String.localize("share your email address!"))
        case SystemLabel.sent.id:
            setEnvelopeMessages(title: String.localize("You have no emails sent"), subtitle: String.localize("let's send one!"))
        case SystemLabel.draft.id:
            setEnvelopeMessages(title: String.localize("There are no drafts"), subtitle: String.localize("That's ok"))
        case SystemLabel.spam.id:
            setEnvelopeMessages(title: String.localize("There's no spam"), subtitle: String.localize("Cool!"))
        case SystemLabel.trash.id:
            setEnvelopeMessages(title: String.localize("There's no trash"), subtitle: String.localize("What a clean place!"))
        default:
            setEnvelopeMessages(title: String.localize("There are no emails"), subtitle: String.localize("It's a matter of time"))
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
        let labelsVC = storyboard.instantiateViewController(withIdentifier: "settingsLabelsViewController") as! SettingsLabelsViewController
        let devicesVC = storyboard.instantiateViewController(withIdentifier: "settingsDevicesViewController") as! SettingsDevicesViewController
        
        let tabsVC = CustomTabsController(viewControllers: [generalVC, labelsVC, devicesVC])
        tabsVC.myAccount = self.myAccount
        tabsVC.edgesForExtendedLayout = []
        tabsVC.tabBarAlignment = .top
        let tabBar = tabsVC.tabBar
        tabBar.setLineColor(.mainUI, for: .selected)
        tabBar.layer.masksToBounds = false
        
        generalVC.myAccount = self.myAccount
        labelsVC.myAccount = self.myAccount
        devicesVC.myAccount = self.myAccount
        generalVC.generalData = tabsVC.generalData
        devicesVC.deviceData = tabsVC.devicesData
        
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
        let attrs = [NSAttributedStringKey.foregroundColor: UIColor.white, NSAttributedStringKey.font: Font.bold.size(17)!] as [NSAttributedStringKey : Any]
        navSettingsVC.navigationBar.titleTextAttributes = attrs
        
        self.present(navSettingsVC, animated: true, completion: nil)
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
    
    func goToEmailDetail(selectedThread: Thread, selectedLabel: Int, message: ControllerMessage? = nil){
        self.navigationDrawerController?.closeRightView()
        
        guard mailboxData.selectedLabel != SystemLabel.draft.id else {
            continueDraft(selectedThread.lastEmail)
            return
        }
        
        let emails = DBManager.getThreadEmails(selectedThread.threadId, label: selectedLabel)
        let emailDetailData = EmailDetailData(threadId: selectedThread.threadId, label: mailboxData.searchMode ? SystemLabel.all.id : selectedLabel)
        var labelsSet = Set<Label>()
        var openKeys = [Int]()
        var peerKeys = [Int]()
        for email in emails {
            email.isExpanded = email.unread
            labelsSet.formUnion(email.labels)
            if(email.unread){
                if(email.status == .none) {
                    openKeys.append(email.key)
                } else {
                    peerKeys.append(email.key)
                }
            }
        }
        emailDetailData.emails = emails
        emailDetailData.selectedLabel = selectedLabel
        emailDetailData.labels = Array(labelsSet)
        emailDetailData.subject = emails.first!.subject
        emailDetailData.accountEmail = "\(myAccount.username)\(Constants.domain)"
        emails.last!.isExpanded = true
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmailDetailViewController") as! EmailDetailViewController
        vc.message = message
        vc.emailData = emailDetailData
        vc.mailboxData = self.mailboxData
        vc.myAccount = self.myAccount
        self.navigationController?.pushViewController(vc, animated: true)
        openEmails(openKeys: openKeys, peerKeys: peerKeys)
    }
    
    func openOwnEmails(_ peerKeys: [Int]){
        guard !peerKeys.isEmpty else {
            return
        }
        let params = ["cmd": Event.Peer.emailsUnread.rawValue,
                      "params": [
                        "unread": 0,
                        "metadataKeys": peerKeys
            ]] as [String : Any]
        self.postPeerEvent(params, failSilently: true) {
            DBManager.updateEmails(peerKeys, unread: false)
        }
    }
    
    func openEmails(openKeys: [Int], peerKeys: [Int]) {
        guard !openKeys.isEmpty else {
            openOwnEmails(peerKeys)
            return
        }
        APIManager.notifyOpen(keys: openKeys, token: myAccount.jwt) { responseData in
            guard case .Success = responseData else {
                return
            }
            DBManager.updateEmails(openKeys, unread: false)
            self.openOwnEmails(peerKeys)
        }
    }
    
    func goToEmailDetail(threadId: String, message: ControllerMessage? = nil){
        let workingLabel = SystemLabel.inbox.id
        guard let selectedThread = DBManager.getThread(threadId: threadId, label: workingLabel) else {
            return
        }
        goToEmailDetail(selectedThread: selectedThread, selectedLabel: workingLabel, message: message)
    }
    
    func continueDraft(_ draft: Email){
        let composerData = ComposerData()
        composerData.initToContacts = Array(draft.getContacts(type: .to))
        composerData.initCcContacts = Array(draft.getContacts(type: .cc))
        composerData.initSubject = draft.subject
        composerData.initContent = draft.content
        composerData.emailDraft = draft
        if(!draft.threadId.isEmpty){
            composerData.threadId = draft.threadId
        }
        openComposer(composerData: composerData, files: draft.files)
    }
    
    func openComposer(composerData: ComposerData, files: List<File>){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        let composerVC = navComposeVC.viewControllers.first as! ComposeViewController
        composerVC.composerData = composerData
        composerVC.delegate = self
        for file in files {
            file.requestStatus = .finish
            composerVC.fileManager.registeredFiles.append(file)
        }
        self.present(snackVC, animated: true, completion: {
            self.navigationDrawerController?.closeLeftView()
        })
    }
    
    func inviteFriend(){
        let textToShare = String.localize("Check out Criptext, I use it to email privately and securely with anyone! Get it free at https://www.criptext.com/dl")
        let shareObject = [textToShare] as [Any]
        let activityVC = UIActivityViewController(activityItems: shareObject, applicationActivities: nil)
        activityVC.completionWithItemsHandler = { (activity, success, items, error) in
            guard success else {
                return
            }
            Analytics.logEvent("invite_friend", parameters: ["app_source" : (activity?.rawValue ?? "Unknown") as NSObject])
        }
        activityVC.popoverPresentationController?.sourceView = self.view
        self.present(activityVC, animated: true)
    }
    
    func openSupport(){
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let supportContact = Contact()
        supportContact.displayName = "Criptext Support"
        supportContact.email = "support@criptext.com"
        let composerData = ComposerData()
        composerData.initContent = "<br/><br/><span>\(String.localize("Do not write below this line."))</span><br/><span>***************************</span><br/><span>Version: \(appVersionString)</span><br/><span>Device: \(systemIdentifier())</span><br/><span>OS: \(UIDevice.current.systemVersion)</span>"
        composerData.initToContacts = [supportContact]
        composerData.initSubject = "Customer Support - iOS"
        openComposer(composerData: composerData, files: List<File>())
        
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
        
        guard mailboxData.selectedLabel != SystemLabel.trash.id && mailboxData.selectedLabel != SystemLabel.spam.id && mailboxData.selectedLabel != SystemLabel.draft.id else {
            return []
        }
        
        let trashAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "         ") { (action, index) in
            let thread = self.mailboxData.threads[indexPath.row]
            self.moveSingleThreadTrash(threadId: thread.threadId)
        }
        
        trashAction.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "trash-action"))
        
        return [trashAction];
    }

    func moveSingleThreadTrash(threadId: String){
        let eventData = EventData.Peer.ThreadLabels(threadIds: [threadId], labelsAdded: [SystemLabel.trash.description], labelsRemoved: [])
        
        postPeerEvent(["params": eventData.asDictionary(), "cmd": Event.Peer.threadsLabels.rawValue]) {
            DBManager.addRemoveLabelsForThreads(threadId, addedLabelIds: [SystemLabel.trash.id], removedLabelIds: [], currentLabel: self.mailboxData.selectedLabel)
            self.removeThreads(threadIds: [threadId])
        }
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != mailboxData.threads.count && !mailboxData.isCustomEditing && !mailboxData.searchMode
    }
    
    func postPeerEvent(_ params: [String: Any], failSilently: Bool = false, completion: @escaping (() -> Void)){
        APIManager.postPeerEvent(params, token: myAccount.jwt) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                if (!failSilently) {
                    self.showAlert(String.localize("Request Error"), message: "\(error.description). \(String.localize("Please try again"))", style: .alert)
                }
                return
            }
            guard case .Success = responseData else {
                if (!failSilently) {
                    self.showAlert(String.localize("Something went wrong"), message: String.localize("Unable to set labels. Please try again"), style: .alert)
                }
                return
            }
            
            completion()
        }
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
        self.generalOptionsContainerView.closeMoreOptions()
        self.present(popover, animated: true)
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
        updateBadges()
        showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
    }
    
    func registerToken(fcmToken: String){
        APIManager.registerToken(fcmToken: fcmToken, token: myAccount.jwt)
    }
}

extension InboxViewController {
    func setLabels(added: [Int], removed: [Int], forceRemove: Bool = false) {
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        self.didPressEdit(reload: true)
        let threadIds = indexPaths.map({mailboxData.threads[$0.row].threadId})
        let shouldRemoveItems = removed.contains(where: {$0 == mailboxData.selectedLabel}) || forceRemove
        
        let changedLabels = getLabelNames(added: added, removed: removed)
        let eventData = EventData.Peer.ThreadLabels(threadIds: threadIds, labelsAdded: changedLabels.0, labelsRemoved: changedLabels.1)
        postPeerEvent(["params": eventData.asDictionary(), "cmd": Event.Peer.threadsLabels.rawValue]) {
            for threadId in threadIds {
                DBManager.addRemoveLabelsForThreads(threadId, addedLabelIds: added, removedLabelIds: removed, currentLabel: self.mailboxData.selectedLabel)
            }
            if(shouldRemoveItems){
                self.removeThreads(threadIds: threadIds)
            } else {
                self.updateThreads(threadIds: threadIds)
            }
        }
    }
    
    func removeThreads(threadIds: [String]){
        var indexesToRemove = [IndexPath]()
        for threadId in threadIds {
            guard let index = mailboxData.emailArray.index(where: {$0.threadId == threadId}) else {
                continue
            }
            indexesToRemove.append(IndexPath(row: index, section: 0))
        }
        let sortedIndexPaths = indexesToRemove.sorted(by: {$0.row > $1.row})
        for path in sortedIndexPaths {
            mailboxData.threads.remove(at: path.row)
        }
        tableView.deleteRows(at: indexesToRemove, with: .left)
        updateBadges()
        showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
    }
    
    func updateThreads(threadIds: [String]){
        var indexesToUpdate = [IndexPath]()
        for threadId in threadIds {
            guard let index = mailboxData.emailArray.index(where: {$0.threadId == threadId}) else {
                continue
            }
            indexesToUpdate.append(IndexPath(row: index, section: 0))
        }
        tableView.reloadRows(at: indexesToUpdate, with: .fade)
        updateBadges()
        showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
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
    
    func deleteThreads(){
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            self.didPressEdit(reload: true)
            return
        }
        self.didPressEdit(reload: true)
        let threadIds = indexPaths.map({mailboxData.threads[$0.row].threadId})
        let eventData = EventData.Peer.ThreadDeleted(threadIds: threadIds)
        postPeerEvent(["cmd": Event.Peer.threadsDeleted.rawValue, "params": eventData.asDictionary()]) {
            self.removeThreads(threadIds: threadIds)
            for threadId in threadIds {
                DBManager.deleteThreads(threadId, label: self.mailboxData.selectedLabel)
            }
        }
    }
}

extension InboxViewController: NavigationToolbarDelegate {
    func onBackPress() {
        guard !mailboxData.isCustomEditing else {
            self.didPressEdit(reload: true)
            return
        }
    }
    
    func onMoveThreads() {
        handleMoveTo()
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
        showAlert(String.localize("Delete Threads"), message: String.localize("The selected threads will be PERMANENTLY deleted"), style: .alert, actions: [archiveAction, cancelAction])
    }
    
    func onMarkThreads() {
        guard let indexPaths = tableView.indexPathsForSelectedRows else {
            return
        }
        let threadIds = indexPaths.map({mailboxData.threads[$0.row].threadId})
        let unread = self.mailboxData.unreadMails <= 0
        let params = ["cmd": Event.Peer.threadsUnread.rawValue,
                      "params": [
                        "unread": unread ? 1 : 0,
                        "threadIds": threadIds
                        ]
            ] as [String : Any]
        postPeerEvent(params) {
            for threadId in threadIds {
                guard let thread = self.mailboxData.threads.first(where: {$0.threadId == threadId}) else {
                    continue
                }
                DBManager.updateThread(threadId: threadId, currentLabel: self.mailboxData.selectedLabel, unread: unread)
                thread.unread = unread
            }
            self.updateThreads(threadIds: threadIds)
            self.didPressEdit(reload: true)
        }
    }
    
    func onMoreOptions() {
        toggleMoreOptions()
    }
    
    func archiveThreads() {
        generalOptionsContainerView.closeMoreOptions()
        setLabels(added: [], removed: [SystemLabel.inbox.id])
    }
    
    func restoreThreads() {
        generalOptionsContainerView.closeMoreOptions()
        setLabels(added: [], removed: [mailboxData.selectedLabel])
    }
}

extension InboxViewController: ComposerSendMailDelegate {
    func newDraft(draft: Email) {
        guard mailboxData.selectedLabel == SystemLabel.draft.id else {
            return
        }
        self.refreshThreadRows()
    }
    
    func sendFailEmail(){
        guard let email = DBManager.getEmailFailed() else {
            return
        }
        DBManager.updateEmail(email, status: .sending)
        sendMail(email: email)
    }
    
    func sendMail(email: Email) {
        showSendingSnackBar(message: String.localize("Sending Email..."), permanent: true)
        reloadIfSentMailbox(email: email)
        let sendMailAsyncTask = SendMailAsyncTask(account: myAccount, email: email)
        sendMailAsyncTask.start { responseData in
            if case .Unauthorized = responseData {
                self.logout()
                return
            }
            if case .Forbidden = responseData {
                self.showSnackbar(String.localize("Email Failed. It will be resent in the future"), attributedText: nil, buttons: "", permanent: false)
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            if case let .Error(error) = responseData {
                self.showSnackbar("\(error.description). \(String.localize("It will be resent in the future"))", attributedText: nil, buttons: "", permanent: false)
                return
            }
            guard case let .SuccessInt(key) = responseData,
                let newEmail = DBManager.getMail(key: key) else {
                self.showSnackbar(String.localize("Email Failed. It will be resent in the future"), attributedText: nil, buttons: "", permanent: false)
                return
            }
            if let index = self.mailboxData.threads.index(where: {!$0.lastEmail.isInvalidated && $0.threadId == newEmail.threadId}) {
                self.mailboxData.threads[index].lastEmail = newEmail
            }
            self.refreshThreadRows()
            self.notifyEmailDetailController(newEmail: newEmail)
            self.showSendingSnackBar(message: String.localize("Email Sent"), permanent: false)
            self.sendFailEmail()
        }
    }
    
    func notifyEmailDetailController(newEmail: Email){
        guard let emailDetailVC = self.navigationController?.viewControllers.first(where: {$0 is EmailDetailViewController}) as? EmailDetailViewController else {
            return
        }
        emailDetailVC.incomingEmail(newEmail: newEmail)
    }
    
    func notifyEmailDetailController(result: EventData.Result){
        guard let emailDetailVC = self.navigationController?.viewControllers.first(where: {$0 is EmailDetailViewController}) as? EmailDetailViewController else {
            return
        }
        emailDetailVC.didReceiveEvents(result: result)
    }
    
    func reloadIfSentMailbox(email: Email){
        if( SystemLabel(rawValue: self.mailboxData.selectedLabel) == .sent || mailboxData.threads.contains(where: {$0.threadId == email.threadId}) ){
            self.refreshThreadRows()
        }
    }
    
    func showSendingSnackBar(message: String, permanent: Bool) {
        let fullString = NSMutableAttributedString(string: "")
        let attrs = [NSAttributedStringKey.font : Font.regular.size(15)!, NSAttributedStringKey.foregroundColor : UIColor.white]
        fullString.append(NSAttributedString(string: message, attributes: attrs))
        self.showSnackbar("", attributedText: fullString, buttons: "", permanent: permanent)
    }
    
    func deleteDraft(draftId: Int) {
        guard let draftIndex = mailboxData.threads.index(where: {$0.lastEmail.key == draftId}) else {
                return
        }
        mailboxData.threads.remove(at: draftIndex)
        tableView.reloadData()
    }
}

extension InboxViewController: GeneralMoreOptionsViewDelegate{
    func onDismissPress() {
        self.toggleMoreOptions()
    }
    
    func onMoveToPress() {
        self.handleMoveTo()
    }
    
    func onAddLabesPress() {
        self.handleAddLabels()
    }
    
    func onArchivePress() {
        self.archiveThreads()
    }
    
    func onRestorePress() {
        self.restoreThreads()
    }
}

extension InboxViewController: SnackbarControllerDelegate {
    func snackbarController(snackbarController: SnackbarController, willShow snackbar: Snackbar) {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) {
            self.composeButtonBottomConstraint.constant = self.SNACKBAR_PADDING
            self.view.layoutIfNeeded()
        }
    }
    
    func snackbarController(snackbarController: SnackbarController, willHide snackbar: Snackbar) {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) {
            self.composeButtonBottomConstraint.constant = self.BOTTOM_PADDING
            self.view.layoutIfNeeded()
        }
    }
}

extension InboxViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let hintView = HintUIView()
        hintView.messageLabel.text = String.localize("Tap to compose\na secure email")
        
        if(currentGuide == "guideFeed"){
            hintView.topCenterConstraint.constant = -10
            hintView.rightConstraint.constant = 35
            hintView.messageLabel.text = String.localize("See who's reading\nyour emails")
        }
        
        return (bodyView: hintView, arrowView: nil)
    }
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        var coachMark = coachMarksController.helper.makeCoachMark(for: getTarget()){
            (frame: CGRect) -> UIBezierPath in
            return UIBezierPath(ovalIn: frame.insetBy(dx: -4, dy: -4))
        }
        coachMark.allowTouchInsideCutoutPath = true
        return coachMark
    }
    
    func getTarget() -> UIView {
        switch(currentGuide){
        case "guideFeed":
            return self.activityBarButton.customView as! MIBadgeButton
        default:
            return buttonCompose
        }
    }
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
}

extension InboxViewController: LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = myAccount
        self.present(linkDeviceVC, animated: true, completion: nil)
    }
    func onCancelLinkDevice(linkData: LinkData) {
        APIManager.linkDeny(randomId: linkData.randomId, token: myAccount.jwt, completion: {_ in })
    }
    
    func onAcceptLinkDevice(linkData: LinkData, completion: @escaping (() -> Void)) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = myAccount
        self.getTopView().presentedViewController?.dismiss(animated: false, completion: nil)
        self.getTopView().present(linkDeviceVC, animated: true) {
            completion()
        }
    }
    func onCancelLinkDevice(linkData: LinkData, completion: @escaping (() -> Void)) {
        APIManager.linkDeny(randomId: linkData.randomId, token: myAccount.jwt, completion: {_ in
            completion()
        })
    }
}

extension InboxViewController {
    func markAsRead(emailKey: Int, completion: @escaping (() -> Void)){
        guard DBManager.getMail(key: emailKey) != nil else {
            completion()
            return
        }
        let eventData = [
            "metadataKeys": [emailKey],
            "unread": 0
            ] as [String : Any]
        postPeerEvent(["params": eventData, "cmd": Event.Peer.emailsUnread.rawValue], failSilently: true) {
            DBManager.markAsUnread(emailKeys: [emailKey], unread: false)
            self.refreshThreadRows()
            completion()
        }
    }
    
    func reply(emailKey: Int, completion: @escaping (() -> Void)){
        guard let email = DBManager.getMail(key: emailKey) else {
            completion()
            return
        }
        self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
        self.navigationController?.popToRootViewController(animated: true)
        goToEmailDetail(threadId: email.threadId, message: ControllerMessage.ReplyThread(emailKey))
        completion()
    }
    
    func moveToTrash(emailKey: Int, completion: @escaping (() -> Void)){
        guard let email = DBManager.getMail(key: emailKey) else {
            completion()
            return
        }
        let eventData = EventData.Peer.EmailLabels(metadataKeys: [emailKey], labelsAdded: [SystemLabel.trash.description], labelsRemoved: [])
        postPeerEvent(["params": eventData.asDictionary(), "cmd": Event.Peer.emailsLabels.rawValue], failSilently: true) {
            DBManager.setLabelsForEmail(email, labels: [SystemLabel.trash.id])
            self.refreshThreadRows()
            completion()
        }
    }
}
