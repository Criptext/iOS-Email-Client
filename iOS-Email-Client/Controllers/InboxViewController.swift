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
        WebSocketManager.sharedInstance.eventDelegate = self
        self.generalOptionsContainerView.handleCurrentLabel(currentLabel: mailboxData.selectedLabel)
        
        self.coachMarksController.overlay.allowTap = true
        self.coachMarksController.overlay.color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85)
        self.coachMarksController.dataSource = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendFailEmail()
        showGuide()
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
        
        self.menuButton = UIBarButtonItem(image: #imageLiteral(resourceName: "menu_white"), style: .plain, target: self, action: #selector(didPressOpenMenu(_:)))
        self.menuButton.tintColor = UIColor.white
        self.searchBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "search"), style: .plain, target: self, action: #selector(didPressSearch(_:)))
        self.searchBarButton.tintColor = UIColor(red:0.73, green:0.73, blue:0.74, alpha:1.0)
        
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
    
    @objc func getPendingEvents(_ refreshControl: UIRefreshControl?, completion: (() -> Void)? = nil) {
        guard !mailboxData.updating else {
            completion?()
            return
        }
        APIManager.getEvents(token: myAccount.jwt) { (responseData) in
            refreshControl?.endRefreshing()
            guard case let .Events(events) = responseData else {
                completion?()
                return
            }
            let eventHandler = EventHandler(account: self.myAccount)
            eventHandler.eventDelegate = self
            eventHandler.handleEvents(events: events)
            completion?()
        }
    }
}

extension InboxViewController: EventHandlerDelegate {
    func didReceiveEvents(result: EventData.Result) {
        mailboxData.updating = result.fromWS ? mailboxData.updating : false
        
        guard !result.removed else {
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            delegate.logout()
            return
        }
        
        if result.emails.contains(where: {$0.status != .unsent}) {
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
        
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
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
            setEnvelopeMessages(title: "There are no emails", subtitle: "share your email address!")
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
        var labelsSet = Set<Label>()
        var openKeys = [Int]()
        for email in emails {
            email.isExpanded = email.unread
            labelsSet.formUnion(email.labels)
            if(email.unread){
                openKeys.append(email.key)
            }
            DBManager.updateEmail(email, unread: false)
        }
        emailDetailData.emails = emails
        emailDetailData.selectedLabel = selectedLabel
        emailDetailData.labels = Array(labelsSet)
        emailDetailData.subject = emails.first!.subject
        emailDetailData.accountEmail = "\(myAccount.username)\(Constants.domain)"
        emails.last!.isExpanded = true
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "EmailDetailViewController") as! EmailDetailViewController
        vc.emailData = emailDetailData
        vc.mailboxData = self.mailboxData
        vc.myAccount = self.myAccount
        self.navigationController?.pushViewController(vc, animated: true)
        if(!openKeys.isEmpty) {
            APIManager.notifyOpen(keys: openKeys, token: myAccount.jwt)
        }
    }
    
    func goToEmailDetail(threadId: String){
        let workingLabel = SystemLabel.inbox.id
        guard let selectedThread = DBManager.getThread(threadId: threadId, label: workingLabel) else {
            return
        }
        goToEmailDetail(selectedThread: selectedThread, selectedLabel: workingLabel)
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
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func openSupport(){
        let supportContact = Contact()
        supportContact.displayName = "Criptext Support"
        supportContact.email = "support@criptext.com"
        let composerData = ComposerData()
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
        
        postPeerEvent(["params": eventData.asDictionary(), "cmd": Event.Peer.threadsLabels.rawValue]) { (responseData) in
            guard case .Success = responseData else {
                self.showAlert("Something went wrong", message: "Unable to set labels. Please try again", style: .alert)
                return
            }
            DBManager.addRemoveLabelsForThreads(threadId, addedLabelIds: [SystemLabel.trash.id], removedLabelIds: [], currentLabel: self.mailboxData.selectedLabel)
            self.removeThreads(threadIds: [threadId])
        }
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != mailboxData.threads.count && !mailboxData.isCustomEditing && !mailboxData.searchMode
    }
    
    func postPeerEvent(_ params: [String: Any], completion: @escaping ((ResponseData) -> Void)){
        APIManager.postPeerEvent(params, token: myAccount.jwt) { (responseData) in
            completion(responseData)
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
        postPeerEvent(["params": eventData.asDictionary(), "cmd": Event.Peer.threadsLabels.rawValue]) { (responseData) in
            guard case .Success = responseData else {
                self.showAlert("Something went wrong", message: "Unable to set labels. Please try again", style: .alert)
                return
            }
            for threadId in threadIds {
                DBManager.addRemoveLabelsForThreads(threadId, addedLabelIds: added, removedLabelIds: removed, currentLabel: self.mailboxData.selectedLabel)
            }
            if(shouldRemoveItems){
                self.removeThreads(threadIds: threadIds)
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
        postPeerEvent(["cmd": Event.Peer.threadsDeleted.rawValue, "params": eventData.asDictionary()]) { (responseData) in
            guard case .Success = responseData else {
                self.showAlert("Something went wrong", message: "Unable to delete threads. Please try again", style: .alert)
                return
            }
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
        showAlert("Delete Threads", message: "The selected threads will be PERMANENTLY deleted", style: .alert, actions: [archiveAction, cancelAction])
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
        postPeerEvent(params) { (responseData) in
            guard case .Success = responseData else {
                self.showAlert("Something went wrong", message: "Unable to change read status. Please try again", style: .alert)
                return
            }
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
        showSendingSnackBar(message: "Sending Email...", permanent: true)
        reloadIfSentMailbox(email: email)
        let sendMailAsyncTask = SendMailAsyncTask(account: myAccount, email: email)
        sendMailAsyncTask.start { data in
            guard let key = data,
                let newEmail = DBManager.getMail(key: key) else {
                self.showAlert("Network Error", message: "Unable to send email. Don't worry, it will be automatically resent.", style: .alert)
                self.hideSnackbar()
                return
            }
            if let index = self.mailboxData.threads.index(where: {!$0.lastEmail.isInvalidated && $0.threadId == newEmail.threadId}) {
                self.mailboxData.threads[index].lastEmail = newEmail
            }
            self.refreshThreadRows()
            self.notifyEmailDetailController(newEmail: newEmail)
            self.showSendingSnackBar(message: "Email Sent", permanent: false)
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
        hintView.messageLabel.text = "Tap to compose\na secure email"
        
        if(currentGuide == "guideFeed"){
            hintView.topCenterConstraint.constant = -10
            hintView.rightConstraint.constant = 35
            hintView.messageLabel.text = "See who's reading\nyour emails"
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
