//
//  AppDelegate.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/3/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import UIKit
import Fabric
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
            return currentTimestamp - timestamp >= Utils.ONE_MINUTE
        case .fiveminutes:
            return currentTimestamp - timestamp >= Utils.FIVE_MINUTES
        case .fifteenminutes:
            return currentTimestamp - timestamp >= Utils.FIFTEEN_MINUTES
        case .onehour:
            return currentTimestamp - timestamp >= Utils.ONE_HOUR
        case .oneday:
            return currentTimestamp - timestamp >= Utils.ONE_DAY
        default:
            return true
        }
    }
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Initialize sign-in
        Fabric.with([Crashlytics.self])
        
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
            })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        
        self.window?.tintColor = UIColor.black
        
        var initialVC:UIViewController!
        
        let defaults = CriptextDefaults()
        defaults.migrate()
        
        if let activeAccount = defaults.activeAccount {
            //Go to inbox
            initialVC = initMailboxRootVC(launchOptions, activeAccount)
        }else{
            //Go to login
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let loginVC = storyboard.instantiateInitialViewController()!
            initialVC = loginVC
        }
        
        self.replaceRootViewController(initialVC)
        self.registerPushNotifications()
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
        UNUserNotificationCenter.current().setNotificationCategories([setupLinkDeviceNotification(), setupNewEmailNotification()])
    }
    
    func setupLinkDeviceNotification() -> UNNotificationCategory {
        let linkAccept = UNNotificationAction(identifier: "LINK_ACCEPT", title: "Approve", options: .foreground)
        let linkDeny = UNNotificationAction(identifier: "LINK_DENY", title: "Reject", options: .destructive)
        return UNNotificationCategory(identifier: "LINK_DEVICE", actions: [linkAccept, linkDeny], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
    }
    
    func setupNewEmailNotification() -> UNNotificationCategory {
        let emailMark = UNNotificationAction(identifier: "EMAIL_MARK", title: "Mark as Read", options: .authenticationRequired)
        let emailReply = UNNotificationAction(identifier: "EMAIL_REPLY", title: "Reply", options: .foreground)
        let emailTrash = UNNotificationAction(identifier: "EMAIL_TRASH", title: "Delete", options: .destructive)
        return UNNotificationCategory(identifier: "OPEN_THREAD", actions: [emailMark, emailReply, emailTrash], intentIdentifiers: [], hiddenPreviewsBodyPlaceholder: "", options: .customDismissAction)
    }
    
    func logout(manually: Bool = false, message: String = "This device has been removed remotely."){
        if let mailboxVC = getInboxVC() {
            mailboxVC.invalidateObservers()
        }
        UIApplication.shared.applicationIconBadgeNumber = 0
        APIManager.cancelAllRequests()
        WebSocketManager.sharedInstance.close()
        WebSocketManager.sharedInstance.delegate = nil
        self.clearDefaults()
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
        
        if (!manually) {
            DBManager.destroy()
        } else {
            DBManager.signout()
        }
    }
    
    func clearDefaults() {
        let defaults = CriptextDefaults()
        defaults.removeConfig()
    }
    
    func replaceRootViewController(_ viewController:UIViewController){
        self.window?.rootViewController = nil
        self.window?.rootViewController = viewController
        self.window?.makeKeyAndVisible()
    }
    
    func initMailboxRootVC(_ launchOptions: [UIApplicationLaunchOptionsKey: Any]?, _ activeAccount: String) -> UIViewController{
        let myAccount = DBManager.getAccountByUsername(activeAccount)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootVC = storyboard.instantiateViewController(withIdentifier: "InboxNavigationController") as! UINavigationController
        let sidemenuVC = storyboard.instantiateViewController(withIdentifier: "MenuViewController") as! MenuViewController
        sidemenuVC.menuData = MenuData()
        let inboxVC = rootVC.childViewControllers.first as! InboxViewController
        
        inboxVC.myAccount = myAccount
        let feedsRightView = storyboard.instantiateViewController(withIdentifier: "FeedsViewController") as! FeedViewController
    
        let drawerVC = CriptextDrawerController(rootViewController: rootVC, leftViewController: sidemenuVC, rightViewController: feedsRightView)
        drawerVC.delegate = inboxVC
        WebSocketManager.sharedInstance.connect(account: myAccount!)
        let paddingBottom = window?.safeAreaInsets.bottom ?? 0.0
        let snackbarController = CriptextSnackbarController(rootViewController: drawerVC)
        snackbarController.setBottomPadding(padding: paddingBottom)
        snackbarController.delegate = inboxVC
        return snackbarController
    }
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        UIApplication.shared.applicationIconBadgeNumber = DBManager.getUnreadMailsCounter(from: SystemLabel.inbox.id)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        WebSocketManager.sharedInstance.pause()
        goneTimestamp = Date().timeIntervalSince1970
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        self.triggerRefresh()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        WebSocketManager.sharedInstance.reconnect()
        let defaults = CriptextDefaults()
        let showBiometrics = shouldShowPinLock()
        passcodeLockPresenter.passcodeLockVC.passcodeConfiguration.isTouchIDAllowed = defaults.hasPIN && (defaults.hasFingerPrint || defaults.hasFaceID)
        passcodeLockPresenter.passcodeLockVC.passcodeConfiguration.shouldRequestTouchIDImmediately = showBiometrics
        if showBiometrics {
            passcodeLockPresenter.present()
        }
    }
    
    func triggerRefresh(){
        guard let inboxVC = getInboxVC() else {
            return
        }
        inboxVC.getPendingEvents(nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
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
            let rootVC = snackVC.childViewControllers.first as? NavigationDrawerController,
            let navVC = rootVC.childViewControllers.first as? UINavigationController,
            let inboxVC = navVC.childViewControllers.first as? InboxViewController else {
                return nil
        }
        return inboxVC
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    }
        
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let inboxVC = getInboxVC() else {
                return
        }
        DBManager.refresh()
        switch response.actionIdentifier {
        case "LINK_ACCEPT":
            guard let randomId = userInfo["randomId"] as? String else {
                break
            }
            inboxVC.onAcceptLinkDevice(linkData: LinkData(deviceName: "", deviceType: 1, randomId: randomId)) {
                completionHandler()
            }
        case "LINK_DENY":
            guard let randomId = userInfo["randomId"] as? String else {
                break
            }
            inboxVC.onCancelLinkDevice(linkData: LinkData(deviceName: "", deviceType: 1, randomId: randomId)) {
                completionHandler()
            }
        case "EMAIL_MARK":
            guard let keyString = userInfo["metadataKey"] as? String,
                let key = Int(keyString) else {
                return
            }
            inboxVC.markAsRead(emailKey: key) {
                UIApplication.shared.applicationIconBadgeNumber = DBManager.getUnreadMailsCounter(from: SystemLabel.inbox.id)
                completionHandler()
            }
            break
        case "EMAIL_REPLY":
            guard let keyString = userInfo["metadataKey"] as? String,
                let key = Int(keyString) else {
                    return
            }
            inboxVC.reply(emailKey: key) {
                completionHandler()
            }
            break
        case "EMAIL_TRASH":
            guard let keyString = userInfo["metadataKey"] as? String,
                let key = Int(keyString) else {
                    return
            }
            inboxVC.moveToTrash(emailKey: key) {
                completionHandler()
            }
            break
        default:
            if let threadId = userInfo["threadId"] as? String {
                inboxVC.goToEmailDetail(threadId: threadId)
            }
        }
        
    }
}

extension AppDelegate: MessagingDelegate {
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        let defaults = CriptextDefaults()
        let state = UIApplication.shared.applicationState
        guard let action = userInfo["action"] as? String else {
            completionHandler(.noData)
            return
        }
        switch(action){
        case "link_device":
            completionHandler(.noData)
        default:
            guard defaults.hasActiveAccount,
                state == .background,
                let snackVC = self.window?.rootViewController?.snackbarController,
                let rootVC = snackVC.childViewControllers.first as? NavigationDrawerController,
                let navVC = rootVC.childViewControllers.first as? UINavigationController,
                let inboxVC = navVC.childViewControllers.first as? InboxViewController else {
                    completionHandler(.noData)
                    return
            }
            inboxVC.getPendingEvents(nil) { success in
                UIApplication.shared.applicationIconBadgeNumber = DBManager.getUnreadMailsCounter(from: SystemLabel.inbox.id)
                completionHandler(.newData)
            }
        }
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        let defaults = CriptextDefaults()
        guard defaults.hasActiveAccount,
            let inboxVC = getInboxVC() else {
            return
        }
        inboxVC.registerToken(fcmToken: fcmToken)
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        
    }
}

