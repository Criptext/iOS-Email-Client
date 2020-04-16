//
//  AppDelegate.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/3/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import UIKit
import Crashlytics
import Material
import UserNotifications
import RealmSwift
import IQKeyboardManagerSwift
import CLTokenInputView
import Firebase
import FirebaseMessaging
import FirebaseInstanceID
import PasscodeLock

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static let RESUME_APP_TIMER: Double = 180000.0
    
    var window: UIWindow?
    var goneTimestamp: TimeInterval {
        get {
            let defaults = CriptextDefaults()
            return defaults.goneTimestamp
        }
        set (value) {
            let defaults = CriptextDefaults()
            defaults.goneTimestamp = value
        }
    }
    var shouldSendResumeEvent: Bool {
        get {
            let defaults = CriptextDefaults()
            let lastResume = defaults.lastTimeAppResume
            let currentTimestamp = Date().timeIntervalSince1970
            return (currentTimestamp - lastResume) > AppDelegate.RESUME_APP_TIMER
        }
    }
    
    lazy var passcodeLockPresenter: PasscodeLockPresenter = {
        let configuration = PasscodeConfig()
        let vc = CustomPasscodeViewController(state: PasscodeLockViewController.LockState.enter, configuration: configuration)
        vc.showSignOut = true
        vc.successCallback = { [weak self] lock in
            guard let weakSelf = self,
                let mailboxVC = weakSelf.getInboxVC() else {
                    return
            }
            mailboxVC.handleControllerMessage()
        }
        let presenter = PasscodeLockPresenter(mainWindow: self.window, configuration: configuration, viewController: vc)
        return presenter
    }()
    
    var isPasslockPresented: Bool {
        return passcodeLockPresenter.isPasscodePresented
    }
    
    func shouldShowPinLock() -> Bool {
        let defaults = CriptextDefaults()
        guard defaults.hasPIN else {
            return false
        }
        guard defaults.lockTimer != PIN.time.immediately.rawValue else {
            return true
        }
        let timestamp = goneTimestamp
        let currentTimestamp = Date().timeIntervalSince1970
        switch(PIN.time(rawValue: defaults.lockTimer) ?? .immediately) {
        case .oneminute:
            return currentTimestamp - timestamp >= Time.ONE_MINUTE
        case .fiveminutes:
            return currentTimestamp - timestamp >= Time.FIVE_MINUTES
        case .fifteenminutes:
            return currentTimestamp - timestamp >= Time.FIFTEEN_MINUTES
        case .onehour:
            return currentTimestamp - timestamp >= Time.ONE_HOUR
        case .oneday:
            return currentTimestamp - timestamp >= Time.ONE_DAY
        default:
            return true
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Initialize sign-in
        
        let realmURL = self.relocateDatabase()
        
        let config = Realm.Configuration(
            fileURL: realmURL,
            schemaVersion: Env.databaseVersion,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 3) {
                    migration.enumerateObjects(ofType: FeedItem.className()){ oldObject, newObject in
                        if oldObject?["email"] == nil,
                            let newFeed = newObject {
                            migration.delete(newFeed)
                        }
                    }
                }
                if (oldSchemaVersion < 4) {
                    migration.deleteData(forType: "Device")
                }
                if (oldSchemaVersion < 5) {
                    migration.enumerateObjects(ofType: Contact.className()){ oldObject, newObject in
                        if let contact = newObject,
                            let email = contact["email"] as? String,
                            !email.contains("@") {
                            migration.delete(contact)
                        }
                    }
                    var keysMap: Set<String> = []
                    migration.enumerateObjects(ofType: EmailContact.className()){ oldObject, newObject in
                        guard let emailContact = newObject else {
                            return
                        }
                        guard let emailObject = emailContact["email"] as? MigrationObject,
                            let contact = emailContact["contact"] as? MigrationObject,
                            (contact["email"] as? String)?.contains("@") ?? false else {
                            migration.delete(emailContact)
                            return
                        }
                        let key = emailObject["key"] as! Int
                        let email = contact["email"] as! String
                        let type = (emailContact["type"] as! String)
                        let compoundKey = "\(key):\(email):\(type)"
                        
                        guard !keysMap.contains(compoundKey) else {
                            migration.delete(emailContact)
                            return
                        }
                        
                        emailContact["compoundKey"] = compoundKey
                        keysMap.insert(compoundKey)
                    }
                }
                if (oldSchemaVersion < 6) {
                    migration.enumerateObjects(ofType: Email.className()){ oldObject, newObject in
                        guard let oldEmail = oldObject,
                            let oldLabels = oldEmail["labels"] as? List<DynamicObject> else {
                            return
                        }
                        let isTrash = oldLabels.contains(where: { (oldLabel) -> Bool in
                            guard let labelId = oldLabel["id"] as? Int else {
                                return false
                            }
                            return labelId == SystemLabel.trash.id
                        })
                        newObject?["trashDate"] = isTrash ? Date() : nil
                    }
                }
                if (oldSchemaVersion < 8) {
                    var existingEmails = [String: MigrationObject]()
                    var mapFailureEmails = [String: String]()
                    migration.enumerateObjects(ofType: Contact.className(), { (oldObject, newObject) in
                        guard let newContact = newObject,
                            let oldContact = oldObject,
                            let email = oldContact["email"] as? String else {
                            return
                        }
                        let emailSplit = email.split(separator: " ")
                        guard emailSplit.count > 1 else {
                            existingEmails[email] = newContact
                            return
                        }
                        let correctedEmail = String(emailSplit.last!)
                        mapFailureEmails[email] = correctedEmail
                        migration.delete(newContact)
                    })
                    migration.enumerateObjects(ofType: EmailContact.className(), { (oldObject, newObject) in
                        guard let oldEmailContact = oldObject,
                            let emailContact = newObject else {
                            return
                        }
                        guard let contact = oldEmailContact["contact"] as? MigrationObject,
                            let email = contact["email"] as? String,
                            let correctedEmail = mapFailureEmails[email] else {
                            return
                        }
                        if let existingContact = existingEmails[correctedEmail] {
                            emailContact["contact"] = existingContact
                            return
                        }
                        let newContact = migration.create(Contact.className())
                        newContact["email"] = correctedEmail
                        newContact["displayName"] = email.replacingOccurrences(of: correctedEmail, with: "").trimmed
                        emailContact["contact"] = newContact
                        existingEmails[correctedEmail] = newContact
                    })
                    migration.enumerateObjects(ofType: FeedItem.className(), { (oldObject, newObject) in
                        guard let oldFeed = oldObject,
                            let newFeed = newObject else {
                                return
                        }
                        guard let contact = oldFeed["contact"] as? MigrationObject,
                            let email = contact["email"] as? String,
                            let correctedEmail = mapFailureEmails[email] else {
                                return
                        }
                        if let existingContact = existingEmails[correctedEmail] {
                            newFeed["contact"] = existingContact
                            return
                        }
                        migration.delete(newFeed)
                    })
                }
                if (oldSchemaVersion < 13) {
                    var fileKeys = [Int: String]()
                    migration.enumerateObjects(ofType: FileKey.className()){ (oldObject, newObject) in
                        guard let _ = oldObject,
                            let newFileKey = newObject else{
                                return
                        }
                        fileKeys[newFileKey["emailId"] as! Int] = (newFileKey["key"] as! String)
                    }
                    migration.enumerateObjects(ofType: File.className()){ (oldObject, newObject) in
                        guard let oldFile = oldObject,
                            let newFile = newObject else{
                                return
                        }
                        guard let fileKey = fileKeys[oldFile["emailId"] as! Int] else{
                            return
                        }
                        newFile["fileKey"] = fileKey
                    }
                    migration.deleteData(forType: FileKey.className())
                }
                if (oldSchemaVersion < 14) {
                    var contacts = [Int:String]()
                    migration.enumerateObjects(ofType: EmailContact.className()){ (oldObject, newObject) in
                        guard let oldEmailContact = oldObject,
                            let _ = newObject else{
                                return
                        }
                        guard let contact = oldEmailContact["contact"] as? MigrationObject,
                            let email = oldEmailContact["email"] as? MigrationObject else {
                                return
                        }
                        if(oldEmailContact["type"] as! String == "from"){
                            contacts[email["key"] as! Int] = "\(contact["displayName"]!) <\(contact["email"]!)>"
                        }
                    }
                    migration.enumerateObjects(ofType: Email.className()){ (oldObject, newObject) in
                        guard let oldEmail = oldObject,
                            let newEmail = newObject else{
                                return
                        }
                        guard let key = oldEmail["key"],  let fromAddress = contacts[key as! Int] else{
                            return
                        }
                        newEmail["fromAddress"] = fromAddress 
                    }
                    migration.enumerateObjects(ofType: Label.className()){ (oldObject, newObject) in
                        guard let oldLabel = oldObject,
                            let newLabel = newObject else{
                                return
                        }
                        switch(oldLabel["id"] as! Int){
                        case 1:
                            newLabel["uuid"] = "00000000-0000-0000-0000-00000000001"
                            break
                        case 2:
                            newLabel["uuid"] = "00000000-0000-0000-0000-00000000002"
                            break
                        case 3:
                            newLabel["uuid"] = "00000000-0000-0000-0000-00000000003"
                            break
                        case 5:
                            newLabel["uuid"] = "00000000-0000-0000-0000-00000000005"
                            break
                        case 6:
                            newLabel["uuid"] = "00000000-0000-0000-0000-00000000006"
                            break
                        case 7:
                            newLabel["uuid"] = "00000000-0000-0000-0000-00000000007"
                            break
                        default:
                            let name = oldLabel["text"] as! String
                            let hashName = name.sha256()?.prefix(4).lowercased()
                            newLabel["uuid"] = "00000000-0000-0000-0000-0000000\(hashName!)"
                            break
                        }
                    }
                }
                if (oldSchemaVersion < 16) {
                    migration.enumerateObjects(ofType: Label.className()){ (oldObject, newObject) in
                        guard let oldLabel = oldObject,
                            let newLabel = newObject,
                            let id = oldLabel["id"] as? Int,
                            let systemLabel = SystemLabel.init(rawValue: id) else{
                                return
                        }
                        newLabel["text"] = systemLabel.nameId
                    }
                    migration.enumerateObjects(ofType: Contact.className()){ (oldObject, newObject) in
                        guard let newContact = newObject else{
                            return
                        }
                        newContact["score"] = 0
                    }
                }
                if (oldSchemaVersion < 17) {
                    var account: MigrationObject? = nil
                    migration.enumerateObjects(ofType: Account.className()){ (oldObject, newObject) in
                        guard let newAccount = newObject else {
                            return
                        }
                        newAccount["compoundKey"] = "\(newAccount["username"]!)"
                        newAccount["isActive"] = true
                        newAccount["isLoggedIn"] = true
                        if account == nil {
                            account = newAccount
                        }
                    }
                    if let myAccount = account {
                        migration.enumerateObjects(ofType: Email.className()){ (oldObject, newObject) in
                            guard let newEmail = newObject else{
                                return
                            }
                            newEmail["account"] = myAccount
                            newEmail["compoundKey"] = "\(myAccount["compoundKey"]!):\(newEmail["key"]!)"
                        }
                        migration.enumerateObjects(ofType: CRSignedPreKeyRecord.className()){ (oldObject, newObject) in
                            guard let newRecord = newObject else{
                                return
                            }
                            newRecord["account"] = myAccount
                            newRecord["compoundKey"] = "\(myAccount["compoundKey"]!):\(newRecord["signedPreKeyId"]!)"
                        }
                        migration.enumerateObjects(ofType: CRPreKeyRecord.className()){ (oldObject, newObject) in
                            guard let newRecord = newObject else{
                                return
                            }
                            newRecord["account"] = myAccount
                            newRecord["compoundKey"] = "\(myAccount["compoundKey"]!):\(newRecord["preKeyId"]!)"
                        }
                        migration.enumerateObjects(ofType: CRTrustedDevice.className()){ (oldObject, newObject) in
                            guard let newRecord = newObject else{
                                return
                            }
                            newRecord["account"] = myAccount
                        }
                        migration.enumerateObjects(ofType: CRSessionRecord.className()){ (oldObject, newObject) in
                            guard let newRecord = newObject else{
                                return
                            }
                            newRecord["account"] = myAccount
                            newRecord["compoundKey"] = "\(myAccount["compoundKey"]!):\(newRecord["contactId"]!):\(newRecord["deviceId"]!)"
                        }
                        migration.enumerateObjects(ofType: Label.className()){ (oldObject, newObject) in
                            guard let newLabel = newObject else{
                                return
                            }
                            newLabel["account"] = myAccount
                        }
                        migration.enumerateObjects(ofType: QueueItem.className()){ (oldObject, newObject) in
                            guard let newQueue = newObject else{
                                return
                            }
                            newQueue["account"] = myAccount
                        }
                        migration.enumerateObjects(ofType: Contact.className()){ (oldObject, newObject) in
                            guard let newContact = newObject else{
                                return
                            }
                            let newAccountContact = migration.create(AccountContact.className())
                            newAccountContact["account"] = myAccount
                            newAccountContact["contact"] = newContact
                            newAccountContact["compoundKey"] = "\(myAccount["username"]!):\(newContact["email"]!)"
                        }
                    }
                }
                if (oldSchemaVersion < 19 && oldSchemaVersion >= 12) {
                    migration.enumerateObjects(ofType: Account.className()){ (oldObject, newObject) in
                        guard let newAccount = newObject,
                            let oldAccount = oldObject,
                            let refreshToken = oldAccount["refreshToken"] as? String,
                            let refreshDic = Utils.convertToDictionary(text: refreshToken),
                            let rToken = refreshDic["refreshToken"] as? String else {
                            return
                        }
                        newAccount["refreshToken"] = rToken
                    }
                }
                if(oldSchemaVersion < 23) {
                    migration.enumerateObjects(ofType: Account.className()){ (oldObject, newObject) in
                        guard let newAccount = newObject else {
                            return
                        }
                        newAccount["showCriptextFooter"] = true
                    }
                    migration.enumerateObjects(ofType: Label.className()){ (oldObject, newObject) in
                        guard let newLabel = newObject,
                        let labelId = newLabel["id"] as? Int else {
                            return
                        }
                        if(labelId < 8) {
                            newLabel["account"] = nil
                        }
                    }
                }
            })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        self.window?.tintColor = UIColor.black
        
        var initialVC:UIViewController!
        
        let defaults = CriptextDefaults()
        defaults.migrate()
        defaults.appStateActive = true
        
        if (defaults.themeMode == "Dark") {
            UITextField.appearance().keyboardAppearance = .dark
        }
        
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().backgroundColor = ThemeManager.shared.theme.toolbar
        UINavigationBar.appearance().tintColor = ThemeManager.shared.theme.criptextBlue
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
                
        if let myAccount = DBManager.getActiveAccount() {
            //Go to inbox
            initialVC = initMailboxRootVC(launchOptions, myAccount)
            BackupManager.shared.checkAccounts()
        } else if DBManager.getLoggedAccounts().count > 0 {
            //Go to inbox
            let loggedAccounts = DBManager.getLoggedAccounts()
            initialVC = initMailboxRootVC(launchOptions, loggedAccounts.first!)
            BackupManager.shared.checkAccounts()
        } else {
            //Go to login
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let loginVC = storyboard.instantiateInitialViewController()!
            initialVC = loginVC
        }
        
        self.replaceRootViewController(initialVC)
        IQKeyboardManager.shared.enable = true
        
        passcodeLockPresenter.present()
        return true
    }
    
    func relocateDatabase() -> URL? {
        let fileManager = FileManager.default
        
        //Cache original realm path (documents directory)
        guard let originalDefaultRealmPath = Realm.Configuration.defaultConfiguration.fileURL,
            let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: Env.groupApp) else {
                return nil
        }
        let realmPath = appGroupURL.appendingPathComponent("default.realm")
        if (fileManager.fileExists(atPath: originalDefaultRealmPath.path) && !fileManager.fileExists(atPath: realmPath.path)) {
            
            do {
                try fileManager.moveItem(at: originalDefaultRealmPath, to: realmPath)
            } catch {
                print(error)
            }
        }
        
        var config = Realm.Configuration.defaultConfiguration
        config.fileURL = realmPath
        Realm.Configuration.defaultConfiguration = config
        
        return realmPath
    }
    
    func registerPushNotifications() {
        guard FirebaseApp.app() == nil else {
            return
        }
        
        let filepath = Env.googleFileName
        if let fileOps = FirebaseOptions(contentsOfFile: filepath) {
            FirebaseApp.configure(options: fileOps)
        } else {
            FirebaseApp.configure()
        }
        
        Messaging.messaging().delegate = self
        
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        UIApplication.shared.registerForRemoteNotifications()
        UNUserNotificationCenter.current().setNotificationCategories([setupLinkDeviceNotification(), setupNewEmailNotification(), setupSyncDeviceNotification()])
    }
    
    func setupLinkDeviceNotification() -> UNNotificationCategory {
        let linkAccept = UNNotificationAction(identifier: "LINK_ACCEPT", title: String.localize("APPROVE"), options: .foreground)
        let linkDeny = UNNotificationAction(identifier: "LINK_DENY", title: String.localize("REJECT"), options: .destructive)
        return UNNotificationCategory(identifier: "LINK_DEVICE", actions: [linkAccept, linkDeny], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
    }
    
    func setupSyncDeviceNotification() -> UNNotificationCategory {
        let syncAccept = UNNotificationAction(identifier: "SYNC_ACCEPT", title: String.localize("APPROVE"), options: .foreground)
        let syncDeny = UNNotificationAction(identifier: "SYNC_DENY", title: String.localize("REJECT"), options: .destructive)
        return UNNotificationCategory(identifier: "SYNC_DEVICE", actions: [syncAccept, syncDeny], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
    }
    
    func setupNewEmailNotification() -> UNNotificationCategory {
        let emailMark = UNNotificationAction(identifier: "EMAIL_MARK", title: String.localize("MARK_READ"), options: .authenticationRequired)
        let emailReply = UNNotificationAction(identifier: "EMAIL_REPLY", title: String.localize("REPLY"), options: .foreground)
        let emailTrash = UNNotificationAction(identifier: "EMAIL_TRASH", title: String.localize("DELETE"), options: .destructive)
        return UNNotificationCategory(identifier: "OPEN_THREAD", actions: [emailMark, emailReply, emailTrash], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
    }
    
    func logout(account: Account, manually: Bool = false, message: String = String.localize("REMOVED_REMOTELY")){
        if let mailboxVC = getInboxVC() {
            mailboxVC.invalidateObservers()
        }
        BackupManager.shared.clearAccount(accountId: account.compoundKey)
        APIManager.cancelAllRequests()
        WebSocketManager.sharedInstance.close()
        WebSocketManager.sharedInstance.delegate = nil
        if let activateAccount = DBManager.getInactiveAccounts().first,
            let inboxVC = getInboxVC() {
            DBManager.activateAccount(activateAccount)
            inboxVC.swapAccount(activateAccount)
            inboxVC.dismiss(animated: true)
        } else {
            DBManager.disableAccount(account)
            self.setloginAsRoot(manually: manually, message: message)
            ThemeManager.shared.swapTheme(theme: Theme.init())
            self.clearDefaults()
        }
        
        if (!manually) {
            FileUtils.deleteAccountDirectory(account: account)
            DBManager.signout(account: account)
            DBManager.clearMailbox(account: account)
            DBManager.delete(account: account)
        } else {
            DBManager.signout(account: account)
        }
    }
    
    func setloginAsRoot(manually: Bool, message: String) {
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let initialVC = storyboard.instantiateInitialViewController() as! UINavigationController
        if !manually,
            let loginVC = initialVC.topViewController as? NewLoginViewController {
            loginVC.loggedOutRemotely = message
        }
        var options = UIWindow.TransitionOptions()
        options.direction = .toTop
        options.duration = 0.4
        options.style = .easeOut
        UIApplication.shared.keyWindow?.setRootViewController(initialVC, options: options)
    }
    
    func clearDefaults() {
        let defaults = CriptextDefaults()
        defaults.removeConfig()
    }
    
    func swapAccount(account: Account, showRestore: Bool = false) {
        guard let inboxVC = getInboxVC() else {
            return
        }
        inboxVC.mailboxData.showRestore = showRestore
        inboxVC.swapAccount(account)
        inboxVC.dismiss(animated: true)
    }
    
    func replaceRootViewController(_ viewController:UIViewController){
        self.window?.rootViewController = nil
        self.window?.rootViewController = viewController
        self.window?.makeKeyAndVisible()
    }
    
    func initMailboxRootVC(_ launchOptions: [UIApplication.LaunchOptionsKey: Any]?, _ myAccount: Account, showRestore: Bool = false) -> UIViewController{
        Crashlytics.sharedInstance().recordError(CriptextError.init(message: "GG"), withAdditionalUserInfo: ["Test": "Test"] as [String: Any])
        let accounts = DBManager.getLoggedAccounts()
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootVC = storyboard.instantiateViewController(withIdentifier: "InboxNavigationController") as! UINavigationController
        let sidemenuVC = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        sidemenuVC.menuData = MenuData()
        let inboxVC = rootVC.children.first as! InboxViewController
        
        inboxVC.myAccount = myAccount
        inboxVC.mailboxData.showRestore = showRestore
        let feedsRightView = storyboard.instantiateViewController(withIdentifier: "FeedsViewController") as! FeedViewController
    
        let drawerVC = CriptextDrawerController(rootViewController: rootVC, leftViewController: sidemenuVC, rightViewController: feedsRightView)
        drawerVC.delegate = inboxVC
        WebSocketManager.sharedInstance.connect(accounts: Array(accounts))
        let paddingBottom = window?.safeAreaInsets.bottom ?? 0.0
        let snackbarController = CriptextSnackbarController(rootViewController: drawerVC)
        snackbarController.setBottomPadding(padding: paddingBottom)
        snackbarController.delegate = inboxVC
        self.registerPushNotifications()
        return snackbarController
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        UIApplication.shared.applicationIconBadgeNumber = SharedDB.getUnreadCounters()
        RequestManager.shared.clearPending()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        WebSocketManager.sharedInstance.pause()
        if !self.passcodeLockPresenter.isPasscodePresented {
            goneTimestamp = Date().timeIntervalSince1970
        }
        let defaults = CriptextDefaults()
        defaults.appStateActive = false
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        self.triggerRefresh()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        WebSocketManager.sharedInstance.reconnect()
        let defaults = CriptextDefaults()
        let showBiometrics = shouldShowPinLock()
        defaults.appStateActive = true
        passcodeLockPresenter.passcodeLockVC.passcodeConfiguration.isTouchIDAllowed = defaults.hasPIN && (defaults.hasFingerPrint || defaults.hasFaceID)
        passcodeLockPresenter.passcodeLockVC.passcodeConfiguration.shouldRequestTouchIDImmediately = showBiometrics
        if showBiometrics {
            passcodeLockPresenter.present()
        }
        BackupManager.shared.checkAccounts()
    }
    
    func triggerRefresh(){
        guard let inboxVC = getInboxVC() else {
            return
        }
        
        inboxVC.beginRefreshing()
        inboxVC.getPendingEvents(nil)
        inboxVC.dequeueEvents()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        guard let activeAccount = DBManager.getActiveAccount() else {
            return
        }
        if(shouldSendResumeEvent){
            APIManager.postUserEvent(event: Int(Event.UserEvent.resumeApp.rawValue), token: activeAccount.jwt, completion: {_ in })
        }
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    }
}

extension AppDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return false
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func getInboxVC() -> InboxViewController? {
        guard let snackVC = self.window?.rootViewController?.snackbarController,
            let rootVC = snackVC.children.first as? NavigationDrawerController,
            let navVC = rootVC.children.first as? UINavigationController,
            let inboxVC = navVC.children.first as? InboxViewController else {
                return nil
        }
        return inboxVC
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    }
        
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let inboxVC = getInboxVC(),
            let accountUser = (userInfo["account"] as? String ?? userInfo["recipientId"] as? String),
            let accountDomain = userInfo["domain"] as? String else {
                return
        }
        DBManager.refresh()
        switch response.actionIdentifier {
        case "LINK_ACCEPT":
            guard let randomId = userInfo["randomId"] as? String,
                let version = userInfo["version"] as? String else {
                break
            }
            let linkData = LinkData(deviceName: "", deviceType: 1, randomId: randomId, kind: .link)
            linkData.version = Int(version)!
            inboxVC.onAcceptLinkDevice(username: accountUser, domain: accountDomain, linkData: linkData) {
                completionHandler()
            }
        case "LINK_DENY":
            guard let randomId = userInfo["randomId"] as? String else {
                break
            }
            inboxVC.onCancelLinkDevice(username: accountUser, domain: accountDomain, linkData: LinkData(deviceName: "", deviceType: 1, randomId: randomId, kind: .link)) {
                completionHandler()
            }
        case "SYNC_ACCEPT":
            guard let randomId = userInfo["randomId"] as? String,
                let deviceType = userInfo["deviceType"] as? String,
                let deviceName = userInfo["deviceName"] as? String,
                let deviceId = userInfo["deviceId"] as? String,
                let version = userInfo["version"] as? String else {
                break
            }
            let linkData = LinkData(deviceName: deviceName, deviceType: Int(deviceType)!, randomId: randomId, kind: .sync)
            linkData.version = Int(version)!
            linkData.deviceId = Int32(deviceId)!
            inboxVC.onAcceptLinkDevice(username: accountUser, domain: accountDomain, linkData: linkData) {
                completionHandler()
            }
        case "SYNC_DENY":
            guard let randomId = userInfo["randomId"] as? String else {
                break
            }
            inboxVC.onCancelLinkDevice(username: accountUser, domain: accountDomain, linkData: LinkData(deviceName: "", deviceType: 1, randomId: randomId, kind: .sync)) {
                completionHandler()
            }
        case "EMAIL_MARK":
            guard let keyString = userInfo["metadataKey"] as? String,
                let key = Int(keyString) else {
                return
            }
            inboxVC.markAsRead(username: accountUser, domain: accountDomain, emailKey: key) {
                UIApplication.shared.applicationIconBadgeNumber = SharedDB.getUnreadCounters()
                completionHandler()
            }
            break
        case "EMAIL_REPLY":
            guard let keyString = userInfo["metadataKey"] as? String,
                let key = Int(keyString) else {
                    return
            }
            inboxVC.reply(username: accountUser, domain: accountDomain, emailKey: key) {
                completionHandler()
            }
            break
        case "EMAIL_TRASH":
            guard let keyString = userInfo["metadataKey"] as? String,
                let key = Int(keyString) else {
                    return
            }
            inboxVC.moveToTrash(username: accountUser, domain: accountDomain, emailKey: key) {
                completionHandler()
            }
            break
        default:
            if let threadId = userInfo["threadId"] as? String {
                inboxVC.openThread(username: accountUser, domain: accountDomain, threadId: threadId)
            }
        }
    }
}

extension AppDelegate: MessagingDelegate {
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard UIApplication.shared.applicationState != .active else {
            completionHandler(.noData)
            return
        }
        
        if let action = userInfo["action"] as? String ,
            action == "anti_push",
            let subAction = userInfo["subAction"] as? String{
            switch(subAction){
            case "delete_new_email":
                guard let metadataKeys = userInfo["metadataKeys"] as? String else {
                    return
                }
                let keys = metadataKeys.split(separator: ",").map({String($0)})
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: keys)
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: keys)
                completionHandler(.noData)
                return
            case "delete_sync_link":
                guard let randomId = userInfo["randomId"] as? String else {
                    return
                }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [randomId])
                UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [randomId])
                completionHandler(.noData)
                return
            default:
                return
            }
        }
        
        guard let accountUser = userInfo["account"] as? String,
            let accountDomain = userInfo["domain"] as? String else {
            completionHandler(.noData)
            return
        }
        RequestManager.shared.accountCompletions[accountUser] = { success in
            if success {
                UIApplication.shared.applicationIconBadgeNumber = SharedDB.getUnreadCounters()
            }
            completionHandler(.newData)
        }
        let accountId = accountDomain == Env.plainDomain ? accountUser : "\(accountUser)@\(accountDomain)"
        RequestManager.shared.getAccountEvents(accountId: accountId)
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        guard let inboxVC = getInboxVC() else {
            return
        }
        inboxVC.registerToken(fcmToken: fcmToken)
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        
    }
}

