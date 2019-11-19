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
    
    @IBOutlet weak var generalOptionsContainerView: MoreOptionsUIView!
    @IBOutlet weak var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    @IBOutlet weak var topToolbar: TopbarUIView!
    @IBOutlet weak var buttonCompose: UIButton!
    @IBOutlet weak var newsHeaderView: MailboxNewsHeaderUIView!
    
    var searchController = UISearchController(searchResultsController: nil)
    var spaceBarButton:UIBarButtonItem!
    var filterBarButton:UIBarButtonItem!
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
    var menuAvatarButton:UIBarButtonItem!
    var menuAvatarImageView: UIImageView!
    var circleBadgeView: UIView!
    var counterBarButton:UIBarButtonItem!
    var titleBarButton = UIBarButtonItem(title: "INBOX", style: .plain, target: nil, action: nil)
    var countBarButton = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    
    let statusBarButton = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
    
    @IBOutlet weak var envelopeImageView: UIImageView!
    @IBOutlet weak var envelopeTitleView: UILabel!
    @IBOutlet weak var envelopeSubtitleView: UILabel!
    @IBOutlet weak var envelopeView: UIView!
    @IBOutlet weak var composeButtonBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var featureHeaderHeightConstraint: NSLayoutConstraint!
    
    var myAccount: Account!
    var mailboxData = MailboxData()
    var originalNavigationRect:CGRect!
    let coachMarksController = CoachMarksController()
    var currentGuide = "guideComposer"
    var controllerMessage: ControllerMessage?
    var selectLabel = String.localize("SHOW_ALL")
    var mailboxOptionsInterface: MailboxOptionsInterface?

    var containerUrl: URL? {
        return FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent(myAccount.email)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        viewSetup()
        WebSocketManager.sharedInstance.delegate = self
        ThemeManager.shared.addListener(id: "mailbox", delegate: self)
        RequestManager.shared.delegate = self
        emptyTrash(from: Date.init(timeIntervalSinceNow: -30*24*60*60))
        getPendingEvents(nil)
        
        applyTheme()
        setQueueItemsListener()
    }
    
    func setQueueItemsListener() {
        let queueItems = DBManager.getQueueItems(account: self.myAccount)
        newsHeaderView.onClose = { [weak self] in
            self?.mailboxData.feature = nil
            self?.closeNewsHeader()
        }
        mailboxData.queueItems = queueItems
        mailboxData.queueToken = queueItems.observe({ [weak self] (changes) in
            guard !(self?.myAccount.isInvalidated ?? false),
                case .update = changes else {
                    return
            }
            self?.dequeueEvents()
        })
    }
    
    func viewSetupNews() {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String
        let version = mailboxData.feature?.version
        guard version != "" else {
            return
        }
        switch(mailboxData.feature?.symbol){
        case 1: // <
            if(appVersion!.compare(version!, options: .numeric) == .orderedAscending){
                openNewsBanner()
            }
            break
        case 2: // <=
            if(appVersion!.compare(version!, options: .numeric) == .orderedAscending || appVersion!.compare(version!, options: .numeric) == .orderedSame){
                openNewsBanner()
            }
            break
        case 3: //  ==
            if(appVersion!.compare(version!, options: .numeric) == .orderedSame){
                openNewsBanner()
            }
            break
        case 4: // >=
            if(appVersion!.compare(version!, options: .numeric) == .orderedDescending || appVersion!.compare(version!, options: .numeric) == .orderedSame){
                openNewsBanner()
            }else{
                openUpdateBanner()
            }
            break
        case 5: // >
            if(appVersion!.compare(version!, options: .numeric) == .orderedDescending){
                openNewsBanner()
            }else{
                openUpdateBanner()
            }
            break
        default:
            openNewsBanner()
            break
        }
    }
    
    func openNewsBanner(){
        if mailboxData.selectedLabel == SystemLabel.inbox.id,
            let feature = mailboxData.feature {
            newsHeaderView.fillFields(feature: feature)
            openNewsHeader()
        } else {
            closeNewsHeader()
        }
    }
    
    @objc func openAppStore(_ recognizer: UITapGestureRecognizer) {
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id1377890297"),
            UIApplication.shared.canOpenURL(url){
            UIApplication.shared.open(url, options: [:]) { (opened) in }
        }
    }
    
    func openUpdateBanner(){
        if mailboxData.selectedLabel == SystemLabel.inbox.id {
            let tap = UITapGestureRecognizer(target: self, action: #selector(self.openAppStore(_:)))
            tap.numberOfTapsRequired = 1
            newsHeaderView.subtitleLabel.isUserInteractionEnabled = true
            newsHeaderView.subtitleLabel.addGestureRecognizer(tap)
            newsHeaderView.newsImageView.image = UIImage(named: "sync")!
            newsHeaderView.fillFieldsUpdate(title: String.localize("update_now_title"), subTitle: String.localize("update_now_message"))
            openNewsHeader()
        } else {
            closeNewsHeader()
        }
    }
    
    func viewSetup(){
        let headerNib = UINib(nibName: "MailboxHeaderUITableCell", bundle: nil)
        self.tableView.register(headerNib, forHeaderFooterViewReuseIdentifier: "InboxHeaderTableViewCell")
        let newsHeaderNib = UINib(nibName: "MailboxNewsHeaderUITableCell", bundle: nil)
        self.tableView.register(newsHeaderNib, forHeaderFooterViewReuseIdentifier: "NewsHeaderTableViewCell")
        
        self.navigationController?.navigationBar.addSubview(self.topToolbar)
        let margins = self.navigationController!.navigationBar.layoutMarginsGuide
        self.topToolbar.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: -8.0).isActive = true
        self.topToolbar.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 8.0).isActive = true
        self.topToolbar.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: 8.0).isActive = true
        self.navigationController?.navigationBar.bringSubviewToFront(self.topToolbar)
        
        self.tableView.register(UINib(nibName: "TableEndViewCell", bundle: nil), forCellReuseIdentifier: "EndCell")
        
        self.originalNavigationRect = self.navigationController?.navigationBar.frame
        
        self.startNetworkListener()
        
        self.edgesForExtendedLayout = UIRectEdge()
        self.searchController.searchResultsUpdater = self as UISearchResultsUpdating
        self.searchController.dimsBackgroundDuringPresentation = false
        self.searchController.searchBar.delegate = self
        self.searchController.searchBar.barStyle = .black
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).setTitleTextAttributes([NSAttributedString.Key.font: UIFont(name: "NunitoSans-Regular", size: 18.0)!, NSAttributedString.Key.foregroundColor: UIColor(red:0.73, green:0.73, blue:0.74, alpha:1.0)], for: .normal)
        
        self.navigationItem.searchController = self.searchController
        self.definesPresentationContext = true
        self.tableView.allowsMultipleSelection = true
        
        self.initBarButtonItems()
        
        self.setButtonItems(isEditing: false)
        
        self.navigationItem.leftBarButtonItems = [self.menuAvatarButton, self.fixedSpaceBarButton, self.titleBarButton, self.countBarButton]
        self.titleBarButton.title = SystemLabel.inbox.description.uppercased()

        topToolbar.delegate = self
        refreshControl.addTarget(self, action: #selector(getPendingEvents(_:completion:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        self.coachMarksController.overlay.allowTap = true
        self.coachMarksController.overlay.color = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.85)
        self.coachMarksController.dataSource = self
        
        mailboxOptionsInterface = MailboxOptionsInterface(currentLabel: mailboxData.selectedLabel)
        mailboxOptionsInterface?.delegate = self
        self.generalOptionsContainerView.setDelegate(newDelegate: mailboxOptionsInterface!)
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        envelopeTitleView.textColor = theme.mainText
        envelopeSubtitleView.textColor = theme.secondText
        buttonCompose.backgroundColor = theme.criptextBlue
        initFloatingButton(color: theme.criptextBlue)
        refreshControl.tintColor = theme.name == "Dark" ? .white : .gray
        view.backgroundColor = theme.background
        generalOptionsContainerView.applyTheme()
        if let menuViewController = navigationDrawerController?.leftViewController as? MenuViewController {
            menuViewController.applyTheme()
        }
        
        if let feedViewController = navigationDrawerController?.rightViewController as? FeedViewController {
            feedViewController.applyTheme()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        sendFailEmail()
        viewSetupNews()
        generalOptionsContainerView.refreshView()
        
        if mailboxData.showRestore {
            mailboxData.showRestore = false
            fetchBackupData()
        } else {
            presentWelcomeTour()
        }
    }
    
    func handleControllerMessage() {
        guard let message = controllerMessage,
            case let .LinkDevice(linkData) = message else {
            return
        }
        controllerMessage = nil
        self.onAcceptLinkDevice(linkData: linkData, account: myAccount!)
    }
    
    func showGuide(){
        let defaults = CriptextDefaults()
        if !defaults.guideComposer {
            currentGuide = CriptextDefaults.Guide.composer.rawValue
            let presentationContext = PresentationContext.viewController(self)
            self.coachMarksController.start(in: presentationContext)
            defaults.guideComposer = true
        } else if !defaults.guideFeed,
            let feedVC = navigationDrawerController?.rightViewController as? FeedViewController,
            feedVC.feedsData.newFeeds.count > 0 {
            currentGuide = CriptextDefaults.Guide.feed.rawValue
            let presentationContext = PresentationContext.viewController(self)
            self.coachMarksController.start(in: presentationContext)
            defaults.guideFeed = true
        }
    }
    
    func showGuide(guide: CriptextDefaults.Guide){
        switch(guide){
        case .secureLock:
            let defaults = CriptextDefaults()
            if !defaults.guideLock {
                currentGuide = CriptextDefaults.Guide.secureLock.rawValue
                let presentationContext = PresentationContext.viewController(self)
                self.coachMarksController.start(in: presentationContext)
                defaults.guideLock = true
            }
        default:
            break
        }
    }
    
    func syncContacts() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            guard weakSelf.viewIfLoaded?.window != nil,
                !delegate.isPasslockPresented else {
                weakSelf.syncContacts()
                return
            }
            let task = RetrieveContactsTask(accountId: weakSelf.myAccount.compoundKey)
            task.start { (_) in
                
            }
        }
    }
    
    func restoreMailbox(backup: RestoreUIPopover.BackupData?) {
        mailboxData.showRestore = false
        
        let restorePopover = RestoreUIPopover()
        restorePopover.backupData = backup
        restorePopover.myAccount = self.myAccount
        restorePopover.onRestore = { [weak self] in
            self?.goToRestore()
        }
        self.presentPopover(popover: restorePopover, height: 370)
    }
    
    func fetchBackupData() {
        
        guard let url = containerUrl?.appendingPathComponent("backup.db") else {
            restoreMailbox(backup: nil)
            return
        }
        
        var keys = Set<URLResourceKey>()
        keys.insert(.ubiquitousItemIsUploadedKey)
        
        do {
            let resourceValues = try url.resourceValues(forKeys: keys)
            let hasBackup = (resourceValues.allValues[.ubiquitousItemIsUploadedKey] as? Bool) ?? false
            if hasBackup {
                let NSlastBackupDate = resourceValues.allValues[.volumeCreationDateKey] as? NSDate
                let NSlastBackupSize = resourceValues.allValues[.fileSizeKey] as? NSNumber
                let lastBackupDate = NSlastBackupDate as Date? ?? Date()
                let lastBackupSize = NSlastBackupSize?.intValue ?? 0
                
                restoreMailbox(backup: RestoreUIPopover.BackupData(url: url, size: lastBackupSize, date: lastBackupDate))
            } else {
                presentWelcomeTour()
            }
        } catch {
            presentWelcomeTour()
        }
    }
    
    func goToRestore() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let restoreVC = storyboard.instantiateViewController(withIdentifier: "restoreViewController") as! RestoreViewController
        restoreVC.myAccount = self.myAccount
        self.present(restoreVC, animated: true, completion: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard mailboxData.threads.count > 0 else {
            return
        }
        
        guard let indexPath = self.tableView.indexPathForSelectedRow, !mailboxData.isCustomEditing else {
            mailboxData.removeSelectedRow = false
            updateBadges()
            refreshThreadRows()
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
        guard let refreshedRowThread = DBManager.getThread(threadId: thread.threadId, label: mailboxData.selectedLabel, account: self.myAccount),
            thread.lastEmailKey == refreshedRowThread.lastEmailKey else {
            updateBadges()
            refreshThreadRows()
            return
        }
        mailboxData.threads[indexPath.row] = refreshedRowThread
        self.tableView.deselectRow(at: indexPath, animated: true)
        self.tableView.reloadRows(at: [indexPath], with: .none)
        updateBadges()
        showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
        
        AppStoreReviewManager.requestReviewIfAppropriate(viewController: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.coachMarksController.stop(immediately: true)
    }
    
    func initAvatarButton() {
        let containerView = UIView(frame: CGRect(x: 3, y: 0, width: 31, height: 28))
        menuAvatarImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 28, height: 28))
        circleBadgeView = UIView(frame: CGRect(x: 22, y: -2, width: 12, height: 12))
        circleBadgeView.backgroundColor = .red
        circleBadgeView.layer.cornerRadius = 6
        circleBadgeView.layer.borderWidth = 2
        circleBadgeView.layer.borderColor = UIColor.charcoal.cgColor
        circleBadgeView.isHidden = true
        
        menuAvatarImageView.contentMode = .scaleAspectFit
        menuAvatarImageView.clipsToBounds = true
        UIUtils.setProfilePictureImage(imageView: menuAvatarImageView, contact: (myAccount.email, myAccount.name))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didPressOpenMenu(_:)))
        containerView.addSubview(menuAvatarImageView)
        containerView.addSubview(circleBadgeView)
        containerView.addGestureRecognizer(tapGesture)
        self.menuAvatarButton = UIBarButtonItem(customView: containerView)
    }
    
    func initBarButtonItems(){
        self.spaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        self.fixedSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        self.fixedSpaceBarButton.width = 25.0
        self.flexibleSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        
        self.titleBarButton.setTitleTextAttributes([NSAttributedString.Key.font: Font.bold.size(16)!, NSAttributedString.Key.foregroundColor: UIColor.white], for: .disabled)
        self.titleBarButton.isEnabled = false
        self.countBarButton.setTitleTextAttributes([NSAttributedString.Key.font: Font.bold.size(16)!, NSAttributedString.Key.foregroundColor: UIColor(red:0.73, green:0.73, blue:0.74, alpha:1.0)], for: .disabled)
        self.countBarButton.isEnabled = false
        
        let menuImage = #imageLiteral(resourceName: "menu_white").tint(with: .white)
        let filterICon = #imageLiteral(resourceName: "filter").tint(with: .lightGray)
        let searchImage = #imageLiteral(resourceName: "search").tint(with: UIColor(red:0.73, green:0.73, blue:0.74, alpha:1.0))
        
        self.menuButton = UIBarButtonItem(image: menuImage, style: .plain, target: self, action: #selector(didPressOpenMenu(_:)))
        self.searchBarButton = UIBarButtonItem(image: searchImage, style: .plain, target: self, action: #selector(didPressSearch(_:)))
        self.filterBarButton = UIBarButtonItem(image: filterICon, style: .plain, target: self, action: #selector(didPressFilter(_:)))
        self.initAvatarButton()
        // Set batButtonItems
        let activityButton = MIBadgeButton(type: .custom)
        let badgeCounter = DBManager.getNewFeedsCount(since: myAccount.lastTimeFeedOpened)
        activityButton.badgeString = badgeCounter > 0 ? badgeCounter.description : ""
        activityButton.frame = CGRect(x:0, y:0, width: 16, height: 20)
        activityButton.badgeEdgeInsets = UIEdgeInsets(top: 0, left: 1, bottom: 2, right: 0)
        activityButton.setImage(#imageLiteral(resourceName: "activity"), for: .normal)
        activityButton.tintColor = UIColor.white
        activityButton.addTarget(self, action: #selector(didPressActivityMenu), for: UIControl.Event.touchUpInside)
        self.activityBarButton = UIBarButtonItem(customView: activityButton)
        
        self.activityBarButton.tintColor = UIColor.white
        
        let font:UIFont = Font.regular.size(13)!
        let attributes:[NSAttributedString.Key : Any] = [NSAttributedString.Key.font: font];
        self.statusBarButton.setTitleTextAttributes(attributes, for: .normal)
        self.statusBarButton.tintColor = UIColor.darkGray
    }
    
    func initFloatingButton(color: UIColor){
        let shadowPath = UIBezierPath(rect: CGRect(x: 15, y: 15, width: 30, height: 30))
        buttonCompose.layer.shadowColor = color.cgColor
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
        APIManager.reachabilityManager.listener = { [weak self] status in
            
            switch status {
            case .notReachable, .unknown:
                //do nothing
                self?.showSnackbar("Offline", attributedText: nil, buttons: "", permanent: false)
                break
            default:
                self?.dequeueEvents()
                break
            }
        }
    }
    
    func presentWelcomeTour(){
        let defaults = CriptextDefaults()
        guard !defaults.welcomeTour else {
            syncContacts()
            self.showGuide()
            return
        }
        
        let welcomeTourVC = WelcomeTourViewController(nibName: "WelcomeTourView", bundle: nil)
        welcomeTourVC.modalPresentationStyle = .overCurrentContext
        welcomeTourVC.modalTransitionStyle = .crossDissolve
        welcomeTourVC.onDismiss = { [weak self] in
            self?.syncContacts()
            self?.showGuide()
            defaults.welcomeTour = true
        }
        self.present(welcomeTourVC, animated: false, completion: nil)
    }
}

extension InboxViewController: WebSocketManagerDelegate {
    func newMessage(result: EventData.Socket){
        switch(result){
        case .LinkData(let data, let recipientId, let domain):
            let accountId = recipientId + "\(domain == Env.plainDomain ? "" : "@\(domain)")"
            guard let account = DBManager.getAccountById(accountId) else {
                return
            }
            self.handleLinkStart(linkData: data, account: account)
        case .LinkDismiss( _, _), .SyncDismiss( _, _):
            let topView = self.getTopView().presentedViewController
            if(topView is SignInVerificationUIPopover || topView is GenericDualAnswerUIPopover){
                topView?.dismiss(animated: false, completion: nil)
            }
        case .NewEvent(let username, let domain):
            let accountId = username + "\(domain == Env.plainDomain ? "" : "@\(domain)")"
            RequestManager.shared.getAccountEvents(accountId: accountId)
        case .PasswordChange:
            self.presentPasswordPopover(myAccount: myAccount)
        case .Logout:
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            delegate.logout(account: myAccount)
        case .RecoveryChanged(let address):
            guard let nav = self.presentedViewController as? UINavigationController,
                let settings = nav.children.first as? CustomTabsController else {
                return
            }
            settings.generalData.recoveryEmail = address
            settings.generalData.recoveryEmailStatus = .pending
            settings.generalData.isTwoFactor = false
            settings.reloadChildViews()
        case .RecoveryVerified:
            guard let nav = self.presentedViewController as? UINavigationController,
                let settings = nav.children.first as? CustomTabsController else {
                    return
            }
            settings.generalData.recoveryEmailStatus = .verified
            settings.reloadChildViews()
        case .EnterpriseSuspended(let recipientId, let domain):
            if(myAccount.email == (recipientId + "@\(domain)")){
                let accounts = DBManager.getLoggedAccounts()
                self.presentAccountSuspendedPopover(myAccount: myAccount, accounts: Array(accounts), onPressSwitch: self.swapAccount(_:), onPressLogin: self.addAccount)
            }
        case .EnterpriseUnSuspended(let recipientId, let domain):
            if(myAccount.email == (recipientId + "@\(domain)")) {
                self.getTopView().presentedViewController?.dismiss(animated: false, completion: nil)
            }
        default:
            break
        }
    }
    
    func handleLinkStart(linkData: LinkData, account: Account){
        self.presentLinkDevicePopover(linkData: linkData, account: account)
    }
}

extension InboxViewController {
    
    func beginRefreshing(){
        // Start the refresh animation
        refreshControl.beginRefreshing()
        
        // Make the refresh control send action to all targets as if a user executed
        // a pull to refresh manually
        refreshControl.sendActions(for: .valueChanged)
        
        // Apply some offset so that the refresh control can actually be seen
        let contentOffset = CGPoint(x: 0, y: -refreshControl.frame.height)
        self.tableView.setContentOffset(contentOffset, animated: true)
    }
    
    @objc func getPendingEvents(_ refreshControl: UIRefreshControl?, completion: ((Bool) -> Void)? = nil) {
        self.dequeueEvents()
        RequestManager.shared.getAccountEvents(accountId: myAccount.compoundKey, get: false)
        RequestManager.shared.getAccountsEvents()
    }
    
    func didReceiveEvents(result: EventData.Result) {
        guard !result.removed else {
            guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            delegate.logout(account: self.myAccount)
            return
        }
        
        if (result.suspended) {
            let accounts = DBManager.getLoggedAccounts()
            self.presentAccountSuspendedPopover(myAccount: myAccount, accounts: Array(accounts), onPressSwitch: self.swapAccount(_:), onPressLogin: self.addAccount)
            return
        } else {
            self.getTopView().presentedViewController?.dismiss(animated: false, completion: nil)
        }
        
        if let feature = result.feature {
            mailboxData.feature = feature
            viewSetupNews()
        }
        
        if let linkData = result.linkStartData {
            handleLinkStart(linkData: linkData, account: self.myAccount)
        }
        
        if result.updateSideMenu {
            guard let menuViewController = navigationDrawerController?.leftViewController as? MenuViewController else {
                return
            }
            menuViewController.reloadView()
        }
        
        if result.emailLabels.contains(where: {$0 == SystemLabel.inbox.nameId}) {
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
        
        let pathsToUpdate = result.opens.reduce([IndexPath]()) { (result, open) -> [IndexPath] in
            guard let index = mailboxData.threads.firstIndex(where: {$0.threadId == open}) else {
                return result
            }
            return result + [IndexPath(row: index, section: 0)]
        }
        
        if(shouldHardReload(result: result)){
            refreshThreadRows()
        } else {
            tableView.reloadRows(at: pathsToUpdate, with: .automatic)
        }        
        
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
        guard !mailboxData.searchMode && result.emailLabels.contains(where: {$0 == SystemLabel(rawValue: mailboxData.selectedLabel)?.nameId}) else {
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
            buttonCompose.isHidden = true
        }else{
            buttonCompose.isHidden = false
            self.topToolbar.isHidden = true
            self.navigationController?.navigationBar.isHidden = false
            self.navigationController?.navigationBar.frame = self.originalNavigationRect
            refreshControl.isEnabled = true
            mailboxData.unreadMails = 0
            updateBadges()
            self.mailboxData.selectedThreads.removeAll()
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
    
    func swapMailbox(labelId: Int, sender: Any?, force: Bool = false){
        if mailboxData.isCustomEditing {
            didPressEdit(reload: true)
        }
        guard labelId != mailboxData.selectedLabel || force else {
            self.navigationDrawerController?.closeLeftView()
            self.getPendingEvents(nil)
            return
        }
        let isAllMail = labelId == SystemLabel.all.id
        let fallbackLabel = DBManager.getUserLabel(labelId, account: myAccount) ?? DBManager.getLabel(SystemLabel.inbox.id)!
        let myLabelId = isAllMail ? -1 : fallbackLabel.id
        mailboxData.selectedLabel = myLabelId
        selectLabel = String.localize("SHOW_ALL")
        mailboxData.cancelFetchAsyncTask()
        mailboxData.reachedEnd = false
        mailboxData.threads.removeAll()
        titleBarButton.title = (SystemLabel(rawValue: myLabelId)?.description ?? fallbackLabel.text).uppercased()
        topToolbar.swapTrashIcon(labelId: labelId)
        
        self.filterBarButton.image =  #imageLiteral(resourceName: "filter").tint(with: .lightGray)
        self.viewSetupNews()
        self.showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
        self.tableView.reloadData()
        self.navigationDrawerController?.closeLeftView()
        
        mailboxOptionsInterface = MailboxOptionsInterface(currentLabel: mailboxData.selectedLabel)
        mailboxOptionsInterface?.delegate = self
        self.generalOptionsContainerView.setDelegate(newDelegate: mailboxOptionsInterface!)
    }
    
    func swapMarkIcon(){
        topToolbar.swapMarkTo(unread: mailboxData.unreadMails == 0)
    }
    
    func updateBadges(){
        let badgeGetterAsyncTask = GetBadgeCounterAsyncTask(accountId: myAccount.compoundKey, label: mailboxData.selectedLabel)
        badgeGetterAsyncTask.start { [weak self] (label, counter) in
            guard let weakSelf = self,
                weakSelf.mailboxData.selectedLabel == label else {
                return
            }
            weakSelf.countBarButton.title = counter
        }
        
        guard let menuViewController = navigationDrawerController?.leftViewController as? MenuViewController else {
            return
        }
        menuViewController.refreshBadges()
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
    
    @IBAction func didPressFilter(_ sender: UIBarButtonItem) {
        let filterPopover = FilterUIPopover.instantiate(initLabel: selectLabel)
        filterPopover.delegate = self
        self.presentPopover(popover: filterPopover, height: Constants.basePopoverHeight + filterPopover.labels.count * Constants.labelPopoverHeight)
    }
    
    func getUnreadThreads(clear: Bool, since: Date){
        let threads : [Thread]
        let fetchedThreads = mailboxData.threads.map({$0.threadId})
        threads = DBManager.getUnreadThreads(from: mailboxData.selectedLabel, since: since, threadIds: fetchedThreads, account: self.myAccount)
        if(clear){
            mailboxData.threads = threads
        } else {
            mailboxData.threads.append(contentsOf: threads)
        }
        mailboxData.reachedEnd = threads.isEmpty
        mailboxData.cancelFetchAsyncTask()
        self.tableView.reloadData()
        updateBadges()
        showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
    }
}

//MARK: - UIBarButton layout
extension InboxViewController{
    func setButtonItems(isEditing: Bool){
        
        guard isEditing else {
            self.navigationItem.rightBarButtonItems = [self.activityBarButton, self.filterBarButton, self.spaceBarButton]
            self.navigationItem.leftBarButtonItems = [self.menuAvatarButton, self.fixedSpaceBarButton, self.titleBarButton, self.countBarButton]
            return
        }
        
        self.navigationItem.leftBarButtonItems = []
        self.navigationItem.rightBarButtonItems = []
    }
}

//MARK: - Load mails
extension InboxViewController{
    func loadMails(since date:Date, clear: Bool = false, limit: Int = 0){
        guard clear || mailboxData.fetchAsyncTask == nil else {
            return
        }
        let searchText = searchController.searchBar.text
        let threadsAsyncTask = GetThreadsAsyncTask(accountId: myAccount.compoundKey, since: date, threads: clear ? [] : mailboxData.threads, limit: limit, searchText: mailboxData.searchMode ? searchText : nil, showAll: selectLabel == String.localize("SHOW_ALL"), selectedLabel: mailboxData.selectedLabel)
        mailboxData.fetchAsyncTask = threadsAsyncTask
        threadsAsyncTask.start { [weak self] (threads) in
            guard let weakSelf = self else {
                return
            }
            if(clear){
                let secureThread = threads.firstIndex(where: { $0.isSecure })
                if(secureThread != nil && secureThread! == 0) {
                    weakSelf.currentGuide = CriptextDefaults.Guide.secureLock.rawValue
                    weakSelf.showGuide(guide: CriptextDefaults.Guide.secureLock)
                }
                weakSelf.mailboxData.threads = threads
            } else {
                weakSelf.mailboxData.threads.append(contentsOf: threads)
            }
            weakSelf.mailboxData.reachedEnd = threads.isEmpty
            weakSelf.mailboxData.fetchAsyncTask = nil
            weakSelf.tableView.reloadData()
            weakSelf.updateBadges()
            weakSelf.showNoThreadsView(weakSelf.mailboxData.reachedEnd && weakSelf.mailboxData.threads.isEmpty)
        }
    }
}

//MARK: - Google SignIn Delegate
extension InboxViewController{
    
    func signout(){
        self.logout(account: self.myAccount, manually: true)
    }
    
    func invalidateObservers(){
        mailboxData.queueToken?.invalidate()
        mailboxData.queueToken = nil
        guard let feedVC = navigationDrawerController?.rightViewController as? FeedViewController else {
            return
        }
        feedVC.invalidateObservers()
    }
}

extension InboxViewController: FilterUIPopoverDelegate {

    func didAcceptPressed(label: String) {
        selectLabel = label
        if(selectLabel == String.localize("SHOW_ALL")){
            self.filterBarButton.image =  #imageLiteral(resourceName: "filter").tint(with: .lightGray)
            self.loadMails(since: Date(), clear: true, limit: 0)
        }else if (selectLabel == String.localize("SHOW_UNREAD")){
            self.filterBarButton.image =  #imageLiteral(resourceName: "filter").tint(with: .white)
            self.getUnreadThreads(clear: true, since: Date())
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
        cell.selectedBackgroundView?.isHidden = mailboxData.isCustomEditing
        cell.setFields(thread: thread, label: mailboxData.selectedLabel, myEmail: myAccount.email)
        if mailboxData.isCustomEditing {
            if(mailboxData.selectedThreads.contains(thread.threadId)){
                cell.setAsSelected()
                cell.isSelected = true
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableView.ScrollPosition.none)
            } else {
                cell.setAsNotSelected()
                cell.isSelected = false
            }
        } else {
            UIUtils.setProfilePictureImage(imageView: cell.avatarImageView, contact: thread.lastContact)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard !myAccount.isInvalidated else {
            return 0
        }
        return mailboxData.threads.count + 1
    }
    
    func createFooterView() -> UITableViewCell {
        let footerView = tableView.dequeueReusableCell(withIdentifier: "EndCell") as! TableEndViewCell
        guard !mailboxData.reachedEnd else {
            footerView.displayMessage("")
            return footerView
        }
        footerView.displayLoader()
        self.loadMails(since: self.mailboxData.threads.last?.date ?? Date())
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
    
    func closeNewsHeader() {
        guard !newsHeaderView.isHidden else {
            return
        }
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            self?.featureHeaderHeightConstraint.constant = 0
            self?.view.layoutIfNeeded()
        }) { [weak self] (success) in
            self?.newsHeaderView.isHidden = true
        }
    }
    
    func openNewsHeader() {
        guard newsHeaderView.isHidden else {
            return
        }
        newsHeaderView.isHidden = false
        UIView.animate(withDuration: 0.5) { [weak self] in
            self?.featureHeaderHeightConstraint.constant = 125
            self?.view.layoutIfNeeded()
        }
    }
    
    func showEmptyTrashWarning() {
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("EMPTY_TRASH")
        popover.initialMessage = String.localize("ALL_TRASH_DELETE")
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("YES")
        popover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            weakSelf.emptyTrash()
        }
        self.presentPopover(popover: popover, height: 210)
    }
    
    func emptyTrash(from date: Date = Date()){
        autoreleasepool {
            guard let threadIds = DBManager.getTrashThreads(from: date, account: myAccount),
                !threadIds.isEmpty else {
                return
            }
            let eventData = EventData.Peer.ThreadDeleted(threadIds: threadIds)
            DBManager.deleteThreads(threadIds: threadIds)
            self.refreshThreadRows()
            DBManager.createQueueItem(params: ["cmd": Event.Peer.threadsDeleted.rawValue, "params": eventData.asDictionary()], account: self.myAccount)
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
            setEnvelopeMessages(image: ThemeManager.shared.theme.name == "Dark" ? "searchSadDark" : "search_sad", title: String.localize("NO_RESULTS"), subtitle: String.localize("NOR_TRASH_SPAM"))
            return
        }
        switch(mailboxData.selectedLabel){
        case SystemLabel.inbox.id:
            setEnvelopeMessages(image: ThemeManager.shared.theme.name == "Dark" ? "inbox_dark" : "inbox_light", title: String.localize("NO_INBOXES"), subtitle: String.localize("SHARE_EMAIL"))
        case SystemLabel.sent.id:
            setEnvelopeMessages(image: ThemeManager.shared.theme.name == "Dark" ? "sent_dark" : "sent_light", title: String.localize("NO_SENTS"), subtitle: String.localize("LETS_SEND"))
        case SystemLabel.draft.id:
            setEnvelopeMessages(image: ThemeManager.shared.theme.name == "Dark" ? "draft_dark" : "draft_light", title: String.localize("NO_DRAFTS"), subtitle: String.localize("NO_DRAFTS_TEXT"))
        case SystemLabel.spam.id:
            setEnvelopeMessages(image: ThemeManager.shared.theme.name == "Dark" ? "spam_dark" : "spam_light", title: String.localize("NO_SPAM"), subtitle: String.localize("COOL"))
        case SystemLabel.trash.id:
            setEnvelopeMessages(image: ThemeManager.shared.theme.name == "Dark" ? "trash_dark" : "trash_light", title: String.localize("NO_TRASHES"), subtitle: String.localize("CLEAN_PLACE"))
        case SystemLabel.starred.id:
            setEnvelopeMessages(image: ThemeManager.shared.theme.name == "Dark" ? "starred_dark" : "starred_light", title: String.localize("NO_STARRED"), subtitle: String.localize("NO_STARRED_TEXT"))
        default:
            setEnvelopeMessages(image: ThemeManager.shared.theme.name == "Dark" ? "inbox_dark" : "inbox_light", title: String.localize("NO_ALL_EMAILS"), subtitle: String.localize("NO_ALL_EMAILS_TEXT"))
        }
    }
    
    func setEnvelopeMessages(image: String, title: String, subtitle: String){
        envelopeImageView.image = UIImage(named: image)
        envelopeTitleView.text = title
        envelopeSubtitleView.text = subtitle
    }
    
    func goToSettings(){
        self.navigationDrawerController?.closeLeftView()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let generalVC = storyboard.instantiateViewController(withIdentifier: "settingsGeneralViewController") as! SettingsGeneralViewController
        generalVC.myAccount = self.myAccount
        
        let navSettingsVC = UINavigationController(rootViewController: generalVC)
        navSettingsVC.navigationBar.isTranslucent = false
        navSettingsVC.navigationBar.barTintColor = .charcoal
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: Font.bold.size(17)!] as [NSAttributedString.Key : Any]
        navSettingsVC.navigationBar.titleTextAttributes = attrs
        
        let paddingBottom = tableView?.safeAreaInsets.bottom ?? 0.0
        let snackbarController = CriptextSnackbarController(rootViewController: navSettingsVC)
        snackbarController.setBottomPadding(padding: paddingBottom)
        snackbarController.modalPresentationStyle = .fullScreen
        
        self.present(snackbarController, animated: true, completion: nil)
    }
    
    func goToProfile(){
        self.navigationDrawerController?.closeLeftView()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let profileVC = storyboard.instantiateViewController(withIdentifier: "profileEditorView") as! ProfileEditorViewController
        profileVC.myAccount = self.myAccount
        profileVC.loadDataAtStart = true
        
        let navProfileVC = UINavigationController(rootViewController: profileVC)
        navProfileVC.navigationBar.isTranslucent = false
        navProfileVC.navigationBar.barTintColor = .charcoal
        let attrs = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: Font.bold.size(17)!] as [NSAttributedString.Key : Any]
        navProfileVC.navigationBar.titleTextAttributes = attrs
        navProfileVC.modalPresentationStyle = .fullScreen
        self.present(navProfileVC, animated: true, completion: nil)
    }
}

//MARK: - TableView Delegate
extension InboxViewController: InboxTableViewCellDelegate, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
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
        
        let thread = mailboxData.threads[indexPath.row]
        self.mailboxData.selectedThreads.insert(thread.threadId)
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
            guard tableView.indexPathsForSelectedRows != nil else {
                return
            }
            let thread = mailboxData.threads[indexPath.row]
            self.mailboxData.selectedThreads.insert(thread.threadId)
            if(thread.unread){
                mailboxData.unreadMails += 1
            }
            swapMarkIcon()
            let cell = tableView.cellForRow(at: indexPath) as! InboxTableViewCell
            cell.setAsSelected()
            self.topToolbar.counterLabel.text = "\(mailboxData.selectedThreads.count)"
            
            return
        }
        
        let selectedThread = mailboxData.threads[indexPath.row]
        goToEmailDetail(selectedThread: selectedThread, selectedLabel: mailboxData.selectedLabel)
    }
    
    func goToEmailDetail(selectedThread: Thread, selectedLabel: Int, message: ControllerMessage? = nil){
        self.navigationDrawerController?.closeRightView()
        
        autoreleasepool {
            guard mailboxData.selectedLabel != SystemLabel.draft.id else {
                if let lastEmail = SharedDB.getMail(key: selectedThread.lastEmailKey, account: self.myAccount) {
                    continueDraft(lastEmail)
                }
                return
            }
            
            let emails = DBManager.getThreadEmails(selectedThread.threadId, label: selectedLabel, account: self.myAccount)
            guard let subject = emails.first?.subject,
                let lastEmailKey = emails.last?.key else {
                    refreshThreadRows()
                return
            }
            
            let emailDetailData = EmailDetailData(threadId: selectedThread.threadId, label: mailboxData.searchMode ? SystemLabel.all.id : selectedLabel)
            var labelsSet = Set<Label>()
            var openKeys = [Int]()
            var peerKeys = [Int]()
            var bodies = [Int: String]()
            for email in emails {
                let bodyFromFile = FileUtils.getBodyFromFile(account: myAccount, metadataKey: "\(email.key)")
                bodies[email.key] = bodyFromFile.isEmpty ? email.content : bodyFromFile
                var emailState = Email.State()
                emailState.isExpanded = email.unread
                emailDetailData.emailStates[email.key] = emailState
                labelsSet.formUnion(email.labels)
                if(email.unread){
                    if(email.status == .none) {
                        openKeys.append(email.key)
                    } else if (email.canTriggerEvent) {
                        peerKeys.append(email.key)
                    }
                }
            }
            emailDetailData.emails = emails
            emailDetailData.bodies = bodies
            emailDetailData.selectedLabel = selectedLabel
            emailDetailData.labels = Array(labelsSet)
            emailDetailData.subject = subject
            emailDetailData.accountEmail = self.myAccount.email
            var emailState = Email.State()
            emailState.isExpanded = true
            emailDetailData.emailStates[lastEmailKey] = emailState
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "EmailDetailViewController") as! EmailDetailViewController
            vc.message = message
            vc.emailData = emailDetailData
            vc.mailboxData = self.mailboxData
            vc.myAccount = self.myAccount
            self.navigationController?.pushViewController(vc, animated: true)
            openEmails(openKeys: openKeys, peerKeys: peerKeys)
        }
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
        DBManager.updateEmails(peerKeys, unread: false, account: self.myAccount)
        DBManager.createQueueItem(params: params, account: self.myAccount)
    }
    
    func openEmails(openKeys: [Int], peerKeys: [Int]) {
        guard !openKeys.isEmpty else {
            openOwnEmails(peerKeys)
            return
        }
        let params = ["cmd": Event.Queue.open.rawValue, "params": EventData.Queue.EmailOpen(metadataKeys: openKeys).asDictionary()] as [String : Any]
        DBManager.updateEmails(openKeys, unread: false, account: self.myAccount)
        DBManager.createQueueItem(params: params, account: self.myAccount)
        self.openOwnEmails(peerKeys)
    }
    
    func goToEmailDetail(threadId: String, message: ControllerMessage? = nil){
        let workingLabel = SystemLabel.inbox.id
        guard let selectedThread = DBManager.getThread(threadId: threadId, label: workingLabel, account: self.myAccount) else {
            return
        }
        self.navigationController?.popToRootViewController(animated: false)
        self.dismiss(animated: false, completion: nil)
        if let index = mailboxData.threads.firstIndex(where: {$0.threadId == threadId}) {
            self.tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        }
        goToEmailDetail(selectedThread: selectedThread, selectedLabel: workingLabel, message: message)
    }
    
    func continueDraft(_ draft: Email){
        let composerData = ComposerData()
        composerData.initToContacts = Array(draft.getContacts(type: .to))
        composerData.initCcContacts = Array(draft.getContacts(type: .cc))
        composerData.initSubject = draft.subject
        let bodyFromFile = FileUtils.getBodyFromFile(account: myAccount, metadataKey: "\(draft.key)")
        composerData.initContent = bodyFromFile.isEmpty ? draft.content : bodyFromFile
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
        self.present(snackVC, animated: true, completion: { [weak self] in
            self?.navigationDrawerController?.closeLeftView()
        })
    }
    
    func inviteFriend(){
        let textToShare = String.localize("CHECKOUT_CRIPTEXT")
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
        composerData.initContent = "<br/><br/><span>\(String.localize("DONT_WRITE_BELOW"))</span><br/><span>***************************</span><br/><span>Version: \(appVersionString)</span><br/><span>Device: \(UIDevice.modelName) [\(systemIdentifier())]</span><br/><span>OS: \(UIDevice.current.systemVersion)</span>"
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
            self.mailboxData.selectedThreads.remove(thread.threadId)
            if(thread.unread){
                mailboxData.unreadMails -= 1
            }
            swapMarkIcon()
            self.topToolbar.counterLabel.text = "\(mailboxData.selectedThreads.count)"
            tableView.reloadRows(at: [indexPath], with: .none)
            return
        }
        
        self.didPressEdit(reload: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if(mailboxData.threads.count == indexPath.row && mailboxData.threads.count == 0){
            return tableView.frame.height
        }
        return 79.0
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        guard mailboxData.selectedLabel != SystemLabel.trash.id && mailboxData.selectedLabel != SystemLabel.spam.id && mailboxData.selectedLabel != SystemLabel.draft.id else {
            return []
        }
        
        let trashAction = UITableViewRowAction(style: UITableViewRowAction.Style.normal, title: "         ") { [weak self] (action, index) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.moveSingleThreadTrash(indexPath: indexPath)
        }
        trashAction.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "trash-action"))
        
        return [trashAction];
    }

    func moveSingleThreadTrash(indexPath: IndexPath){
        let threadId = mailboxData.threads[indexPath.row].threadId
        DBManager.addRemoveLabelsForThreads(threadId, addedLabelIds: [SystemLabel.trash.id], removedLabelIds: [], currentLabel: self.mailboxData.selectedLabel, account: self.myAccount)
        self.removeThreads(indexPaths: [indexPath])
        let eventData = EventData.Peer.ThreadLabels(threadIds: [threadId], labelsAdded: [SystemLabel.trash.nameId], labelsRemoved: [])
        DBManager.createQueueItem(params: ["params": eventData.asDictionary(), "cmd": Event.Peer.threadsLabels.rawValue], account: self.myAccount)
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.row != mailboxData.threads.count && !mailboxData.isCustomEditing && !mailboxData.searchMode
    }
    
    func dequeueEvents(completion: (() -> Void)? = nil) {
        guard !mailboxData.isDequeueing,
            let queueItems = mailboxData.queueItems,
            queueItems.count > 0 else {
                completion?()
                return
        }
        mailboxData.isDequeueing = true
        let maxBatch = 100
        var peerEvents = [[String: Any]]()
        var eventItems = [QueueItem]()
        for queueItem in queueItems {
            guard (peerEvents.count < maxBatch && peerEvents.count < queueItems.count) else {
                break
            }
            let currentEvent = queueItem.params
            peerEvents.append(currentEvent)
            eventItems.append(queueItem)
        }
        APIManager.postPeerEvent(["peerEvents": peerEvents], token: myAccount.jwt) { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.mailboxData.isDequeueing = false
            switch(responseData) {
            case .Unauthorized:
                completion?()
                weakSelf.logout(account: weakSelf.myAccount)
            case .Forbidden:
                completion?()
                weakSelf.presentPasswordPopover(myAccount: weakSelf.myAccount)
            case .Success, .SuccessString:
                DBManager.deleteQueueItems(eventItems)
                completion?()
            default:
                completion?()
            }
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
        mailboxData.cancelFetchAsyncTask()
        if(!mailboxData.searchMode){
            showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
            tableView.reloadData()
        } else {
            mailboxData.reachedEnd = false
            loadMails(since: Date(), clear: true)
        }
        
    }
}

extension InboxViewController : LabelsUIPopoverDelegate{
    
    func handleAddLabels(){
        let labelsPopover = LabelsUIPopover.instantiate(type: .addLabels, selectedLabel: mailboxData.selectedLabel, myAccount: myAccount)
        if let indexPaths = mailboxData.selectedIndexPaths {
            for indexPath in indexPaths {
                let thread = mailboxData.threads[indexPath.row]
                guard let email = DBManager.getMail(key: thread.lastEmailKey, account: self.myAccount) else {
                    continue
                }
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
        let labelsPopover = LabelsUIPopover.instantiate(type: .moveTo, selectedLabel: mailboxData.selectedLabel, myAccount: myAccount)
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
        guard let indexPaths = mailboxData.selectedIndexPaths else {
            return
        }
        self.didPressEdit(reload: true)
        let threadIds = indexPaths.map({mailboxData.threads[$0.row].threadId})
        let eventThreadIds = indexPaths.filter({mailboxData.threads[$0.row].canTriggerEvent}).map({mailboxData.threads[$0.row].threadId})
        let shouldRemoveItems = removed.contains(where: {$0 == mailboxData.selectedLabel}) || forceRemove
        
        let addStarred = added.contains(SystemLabel.starred.id)
        let removeStarred = removed.contains(SystemLabel.starred.id)
        if(shouldRemoveItems){
            self.removeThreads(indexPaths: indexPaths)
        } else {
            for indexPath in indexPaths {
                let thread = mailboxData.threads[indexPath.row]
                if addStarred {
                    thread.isStarred = true
                } else if removeStarred {
                    thread.isStarred = false
                }
            }
            tableView.reloadRows(at: indexPaths, with: .automatic)
            updateBadges()
        }
        
        let threadLabelsAsyncTask = ThreadsLabelsAsyncTask(accountId: self.myAccount.compoundKey, threadIds: threadIds, eventThreadIds: eventThreadIds, added: added, removed: removed, currentLabel: mailboxData.selectedLabel)
        threadLabelsAsyncTask.start() { [weak self] in
            self?.updateBadges()
        }
    }
    
    func removeThreads(indexPaths: [IndexPath]){
        let sortedIndexPaths = indexPaths.sorted(by: {$0.row > $1.row})
        for indexPath in sortedIndexPaths {
            mailboxData.threads.remove(at: indexPath.row)
        }
        tableView.deleteRows(at: sortedIndexPaths, with: .left)
        showNoThreadsView(mailboxData.reachedEnd && mailboxData.threads.isEmpty)
    }
    
    func deleteThreads(){
        guard let indexPaths = mailboxData.selectedIndexPaths else {
            self.didPressEdit(reload: true)
            return
        }
        self.didPressEdit(reload: true)
        let threadIds = indexPaths.map({mailboxData.threads[$0.row].threadId})
        let eventThreadIds = indexPaths.filter({mailboxData.threads[$0.row].canTriggerEvent}).map({mailboxData.threads[$0.row].threadId})
        self.removeThreads(indexPaths: indexPaths)
        
        let deleteThreadsAsyncTask = DeleteThreadsAsyncTask(accountId: myAccount.compoundKey, threadIds: threadIds, eventThreadIds: eventThreadIds, currentLabel: mailboxData.selectedLabel)
        deleteThreadsAsyncTask.start() { [weak self] in
            self?.updateBadges()
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
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("DELETE_THREADS")
        popover.initialMessage = String.localize("SELECTED_DELETE_PERMANENTLY")
        popover.leftOption = String.localize("CANCEL")
        popover.rightOption = String.localize("OK")
        popover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            weakSelf.deleteThreads()
        }
        self.presentPopover(popover: popover, height: 220)
    }
    
    func onMarkThreads() {
        guard let indexPaths = mailboxData.selectedIndexPaths else {
            return
        }
        var threadIds = [String]()
        var eventThreadIds = [String]()
        let unread = self.mailboxData.unreadMails <= 0
        for indexPath in indexPaths {
            let thread = mailboxData.threads[indexPath.row]
            thread.unread = unread
            
            threadIds.append(thread.threadId)
            if thread.canTriggerEvent {
                eventThreadIds.append(thread.threadId)
            }
        }
        self.didPressEdit(reload: true)
        let markThreadAsyncTask = MarkThreadsAsyncTask(accountId: self.myAccount.compoundKey, threadIds: threadIds, eventThreadIds: eventThreadIds, unread: unread, currentLabel: mailboxData.selectedLabel)
        markThreadAsyncTask.start() { [weak self] in
            self?.updateBadges()
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
        self.showSendingSnackBar(message: String.localize("DRAFT_SAVED"), permanent: false)
    }
    
    func sendFailEmail(){
        guard let email = DBManager.getEmailFailed(account: self.myAccount) else {
            return
        }
        DBManager.updateEmail(email, status: .sending)
        let bodyFromFile = FileUtils.getBodyFromFile(account: myAccount, metadataKey: "\(email.key)")
        sendMail(email: email,
                 emailBody: bodyFromFile.isEmpty ? email.content : bodyFromFile,
                 password: nil)
    }
    
    func sendMail(email: Email, emailBody: String, password: String?) {
        showSendingSnackBar(message: String.localize("SENDING_MAIL"), permanent: true)
        reloadIfSentMailbox(email: email)
        let sendMailAsyncTask = SendMailAsyncTask(email: email, emailBody: emailBody, password: password)
        sendMailAsyncTask.start { [weak self] responseData in
            guard let weakSelf = self else {
                return
            }
            if case .Unauthorized = responseData {
                weakSelf.logout(account: weakSelf.myAccount)
                return
            }
            if case .Forbidden = responseData {
                weakSelf.showSnackbar(String.localize("EMAIL_FAILED"), attributedText: nil, buttons: "", permanent: false)
                weakSelf.presentPasswordPopover(myAccount: weakSelf.myAccount)
                return
            }
            if case let .Error(error) = responseData {
                weakSelf.showSnackbar("\(error.description). \(String.localize("RESENT_FUTURE"))", attributedText: nil, buttons: "", permanent: false)
                return
            }
            guard case let .SuccessInt(key) = responseData else {
                weakSelf.showSnackbar(String.localize("EMAIL_FAILED"), attributedText: nil, buttons: "", permanent: false)
                return
            }
            let sentEmail = DBManager.getMail(key: key, account: weakSelf.myAccount)
            guard sentEmail != nil else {
                weakSelf.showSendingSnackBar(message: String.localize("EMAIL_SENT"), permanent: false)
                return
            }
            weakSelf.refreshThreadRows()
            let message = sentEmail!.secure ? String.localize("EMAIL_SENT_SECURE") : String.localize("EMAIL_SENT")
            weakSelf.showSendingSnackBar(message: message, permanent: false)
            weakSelf.sendFailEmail()
        }
    }
    
    func reloadIfSentMailbox(email: Email){
        if( SystemLabel(rawValue: self.mailboxData.selectedLabel) == .sent || mailboxData.threads.contains(where: {$0.threadId == email.threadId}) ){
            self.refreshThreadRows()
        }
    }
    
    func showSendingSnackBar(message: String, permanent: Bool) {
        let fullString = NSMutableAttributedString(string: "")
        let attrs = [NSAttributedString.Key.font : Font.regular.size(15)!, NSAttributedString.Key.foregroundColor : UIColor.white]
        fullString.append(NSAttributedString(string: message, attributes: attrs))
        self.showSnackbar("", attributedText: fullString, buttons: "", permanent: permanent)
    }
    
    func deleteDraft(draftId: Int) {
        guard let draftIndex = mailboxData.threads.firstIndex(where: {$0.lastEmailKey == draftId}) else {
                return
        }
        mailboxData.threads.remove(at: draftIndex)
        tableView.reloadData()
    }
}

extension InboxViewController: MailboxOptionsInterfaceDelegate {
    func onClose() {
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
    
    func onPrintAllPress() {
        return
    }
}

extension InboxViewController: SnackbarControllerDelegate {
    func snackbarController(snackbarController: SnackbarController, willShow snackbar: Snackbar) {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.composeButtonBottomConstraint.constant = weakSelf.SNACKBAR_PADDING
            weakSelf.view.layoutIfNeeded()
        }
    }
    
    func snackbarController(snackbarController: SnackbarController, willHide snackbar: Snackbar) {
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.composeButtonBottomConstraint.constant = weakSelf.BOTTOM_PADDING
            weakSelf.view.layoutIfNeeded()
        }
    }
}

extension InboxViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    
    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: CoachMarkBodyView, arrowView: CoachMarkArrowView?) {
        let hintView = HintUIView()
        
        switch(currentGuide){
        case "guideFeed":
            hintView.topCenterConstraint.constant = -10
            hintView.rightConstraint.constant = 35
            hintView.messageLabel.text = String.localize("GUIDE_FEEDS")
        case "guideSecure":
            hintView.topCenterConstraint.constant = -10
            hintView.rightConstraint.constant = 35
            hintView.messageLabel.text = String.localize("GUIDE_SECURE_LOCK")
        default:
            hintView.messageLabel.text = String.localize("GUIDE_TAP_COMPOSE")
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
    
    func getTarget() -> UIView? {
        switch(currentGuide){
        case "guideFeed":
            return self.activityBarButton.customView as! MIBadgeButton
        case "guideSecure":
            let index = IndexPath(row: mailboxData.threads.firstIndex(where: { $0.isSecure }) ?? -1, section: 0)
            if(index.row != -1) {
                return (self.tableView.cellForRow(at: index) as! InboxTableViewCell).secureLockImageView
            }
            return nil
        default:
            return buttonCompose
        }
    }
    
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 1
    }
}

extension InboxViewController: LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData, account: Account) {
        guard linkData.version == Env.linkVersion else {
            let popover = GenericAlertUIPopover()
            popover.myTitle = String.localize("VERSION_TITLE")
            popover.myMessage = String.localize("VERSION_MISMATCH")
            self.presentPopover(popover: popover, height: 220)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = account
        self.getTopView().presentedViewController?.dismiss(animated: false, completion: nil)
        self.getTopView().present(linkDeviceVC, animated: true, completion: nil)
    }
    
    func onCancelLinkDevice(linkData: LinkData, account: Account) {
        if case .sync = linkData.kind {
            APIManager.syncDeny(randomId: linkData.randomId, token: account.jwt, completion: {_ in })
        } else {
            APIManager.linkDeny(randomId: linkData.randomId, token: account.jwt, completion: {_ in })
        }
    }
    
    func onAcceptLinkDevice(username: String, domain: String, linkData: LinkData, completion: @escaping (() -> Void)) {
        self.navigationDrawerController?.closeLeftView()
        guard linkData.version == Env.linkVersion else {
            let popover = GenericAlertUIPopover()
            popover.myTitle = String.localize("VERSION_TITLE")
            popover.myMessage = String.localize("VERSION_MISMATCH")
            self.presentPopover(popover: popover, height: 220)
            return
        }
        
        let accountId = domain == Env.plainDomain ? username : "\(username)@\(domain)"
        if myAccount.email != "\(username)@\(domain)",
            let account = DBManager.getAccountById(accountId) {
            self.dismiss(animated: false, completion: nil)
            self.swapAccount(account)
        }
        
        guard let delegate = UIApplication.shared.delegate as? AppDelegate,
            !delegate.passcodeLockPresenter.isPasscodePresented else {
                controllerMessage = ControllerMessage.LinkDevice(linkData)
                return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = myAccount
        self.getTopView().presentedViewController?.dismiss(animated: false, completion: nil)
        self.getTopView().present(linkDeviceVC, animated: true) {
            completion()
        }
    }
    func onCancelLinkDevice(username: String, domain: String, linkData: LinkData, completion: @escaping (() -> Void)) {
        let accountId = domain == Env.plainDomain ? username : "\(username)@\(domain)"
        guard let account = DBManager.getAccountById(accountId) else {
            completion()
            return
        }
        if case .sync = linkData.kind {
            APIManager.syncDeny(randomId: linkData.randomId, token: account.jwt, completion: {_ in
                completion()
            })
        } else {
            APIManager.linkDeny(randomId: linkData.randomId, token: account.jwt, completion: {_ in
                completion()
            })
        }
    }
}

extension InboxViewController {
    func markAsRead(username: String, domain: String, emailKey: Int, completion: @escaping (() -> Void)){
        let accountId = domain == Env.plainDomain ? username : "\(username)@\(domain)"
        guard let account = DBManager.getAccountById(accountId),
            DBManager.getMail(key: emailKey, account: account) != nil else {
            completion()
            return
        }
        DBManager.markAsUnread(emailKeys: [emailKey], unread: false)
        self.refreshThreadRows()
        let eventData = EventData.Peer.EmailUnreadRaw(metadataKeys: [emailKey], unread: 0)
        let eventParams = ["cmd": Event.Peer.emailsUnread.rawValue, "params": eventData.asDictionary()] as [String : Any]
        APIManager.postPeerEvent(["peerEvents": [eventParams]], token: account.jwt) { (responseData) in
            if case .Success = responseData {
                self.refreshThreadRows()
                completion()
                return
            }
            DBManager.createQueueItem(params: eventParams, account: account)
            completion()
        }
    }
    
    func reply(username: String, domain: String, emailKey: Int, completion: @escaping (() -> Void)){
        self.navigationDrawerController?.closeLeftView()
        let accountId = domain == Env.plainDomain ? username : "\(username)@\(domain)"
        if self.myAccount.compoundKey != accountId,
            let account = DBManager.getAccountById(accountId){
            self.dismiss(animated: false, completion: nil)
            self.swapAccount(account)
        }
        
        guard let email = DBManager.getMail(key: emailKey, account: self.myAccount) else {
            completion()
            return
        }
        self.view.window?.rootViewController?.dismiss(animated: false, completion: nil)
        self.navigationController?.popToRootViewController(animated: true)
        goToEmailDetail(threadId: email.threadId, message: ControllerMessage.ReplyThread(emailKey))
        completion()
    }
    
    func moveToTrash(username: String, domain: String, emailKey: Int, completion: @escaping (() -> Void)){
        let accountId = domain == Env.plainDomain ? username : "\(username)@\(domain)"
        guard let account = DBManager.getAccountById(accountId),
            let email = DBManager.getMail(key: emailKey, account: account) else {
            completion()
            return
        }
        DBManager.setLabelsForEmail(email, labels: [SystemLabel.trash.id])
        self.refreshThreadRows()
        let eventData = EventData.Peer.EmailLabels(metadataKeys: [emailKey], labelsAdded: [SystemLabel.trash.nameId], labelsRemoved: [])
        let eventParams = ["cmd": Event.Peer.emailsLabels.rawValue, "params": eventData.asDictionary()] as [String : Any]
        APIManager.postPeerEvent(["peerEvents": [eventParams]], token: account.jwt) { (responseData) in
            if case .Success = responseData {
                self.refreshThreadRows()
                completion()
                return
            }
            DBManager.createQueueItem(params: eventParams, account: account)
            completion()
        }
    }
    
    func openThread(username: String, domain: String, threadId: String) {
        let accountId = domain == Env.plainDomain ? username : "\(username)@\(domain)"
        self.navigationDrawerController?.closeLeftView()
        if self.myAccount.username != username,
            let account = DBManager.getAccountById(accountId){
            self.dismiss(animated: false, completion: nil)
            self.swapAccount(account)
        }
        self.goToEmailDetail(threadId: threadId)
    }
}

extension InboxViewController: ThemeDelegate {
    func swapTheme(_ theme: Theme) {
        applyTheme()
        tableView.reloadData()
        generalOptionsContainerView.refreshView()
        if let menuViewController = navigationDrawerController?.leftViewController as? MenuViewController {
            menuViewController.reloadView()
        }
    }
}

extension InboxViewController {
    func addAccount(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "loginNavController") as! UINavigationController
        let loginVC = controller.topViewController as! NewLoginViewController
        loginVC.multipleAccount = true
        controller.modalPresentationStyle = .fullScreen
        self.present(controller, animated: true, completion: nil)
    }
    
    func createAccount(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "signupview") as! SignUpViewController
        controller.multipleAccount = true
        self.present(controller, animated: true, completion: nil)
    }
    
    func swapAccount(_ account: Account) {
        loadViewIfNeeded()
        let defaults = CriptextDefaults()
        DBManager.swapAccount(current: self.myAccount, active: account)
        self.myAccount = account
        defaults.activeAccount = account.compoundKey
        WebSocketManager.sharedInstance.connect(accounts: [account])
        self.invalidateObservers()
        self.swapMailbox(labelId: mailboxData.selectedLabel, sender: nil, force: true)
        if let menuViewController = navigationDrawerController?.leftViewController as? MenuViewController {
            menuViewController.reloadView()
            menuViewController.hideAccounts()
        }
        if let feedsViewController = navigationDrawerController?.rightViewController as? FeedViewController {
            feedsViewController.loadFeeds()
            let badgeCounter = feedsViewController.feedsData.newFeeds.count
            updateFeedsBadge(counter: badgeCounter)
        }
        self.setQueueItemsListener()
        UIUtils.setProfilePictureImage(imageView: menuAvatarImageView, contact: (myAccount.email, myAccount.name))
        self.showSnackbar("\(String.localize("NOW_LOGGED"))\(account.email)", attributedText: nil, buttons: "", permanent: false)
        RequestManager.shared.getAccountEvents(accountId: account.compoundKey)
    }
}

extension InboxViewController: RequestDelegate {
    func finishRequest(accountId: String, result: EventData.Result) {
        if !RequestManager.shared.isInQueue(accountId: myAccount.compoundKey) {
            self.refreshControl.endRefreshing()
        }
        guard myAccount.compoundKey == accountId else {
            if let menuViewController = navigationDrawerController?.leftViewController as? MenuViewController {
                menuViewController.refreshBadges()
            }
            return
        }
        self.didReceiveEvents(result: result)
    }
    
    func errorRequest(accountId: String, response: ResponseData) {
        if !RequestManager.shared.isInQueue(accountId: accountId) {
            self.refreshControl.endRefreshing()
        }
        guard !myAccount.isInvalidated && myAccount.compoundKey == accountId else {
            return
        }
        
        switch response {
            case .Unauthorized:
                self.logout(account: self.myAccount)
                return
            case .Error(let error):
                if(error.code != .custom) {
                    self.showSnackbar(error.description, attributedText: nil, buttons: "", permanent: false)
                    return
                }
            case .Forbidden:
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            case .Success:
                let topView = self.getTopView().presentedViewController
                if(topView is GenericAlertUIPopover){
                    topView?.dismiss(animated: false, completion: nil)
                }
            default:
                return
        }
    }
}
