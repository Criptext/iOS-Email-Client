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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Initialize sign-in
        Fabric.with([Crashlytics.self])
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: 1,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                // We haven’t migrated anything yet, so oldSchemaVersion == 0
                if (oldSchemaVersion < 1) {
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        
        // Tell Realm to use this new configuration object for the default Realm
        Realm.Configuration.defaultConfiguration = config
        if(DBManager.getLabel(SystemLabel.inbox.id) == nil){
            createSystemLabels()
        }
        
        self.window?.tintColor = UIColor.black
        
        var initialVC:UIViewController!
        
        let defaults = UserDefaults.standard
        if let activeAccount = defaults.string(forKey: "activeAccount") {
            //Go to inbox
            initialVC = initMailboxRootVC(launchOptions, activeAccount)
        }else{
            //Go to login
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            initialVC = storyboard.instantiateInitialViewController()
        }
        
        self.replaceRootViewController(initialVC)
        IQKeyboardManager.shared.enable = true
        return true
    }
    
    func registerPushNotifications() {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
            
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
        
        UIApplication.shared.registerForRemoteNotifications()
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
    
    func createSystemLabels(){
        for systemLabel in SystemLabel.array {
            let newLabel = Label(systemLabel.description)
            newLabel.id = systemLabel.id
            newLabel.color = systemLabel.hexColor
            newLabel.type = "system"
            DBManager.store(newLabel)
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        self.triggerRefresh()
    }
    
    func triggerRefresh(){
        
        
        guard let snackVC = self.window?.rootViewController?.snackbarController,
            let rootVC = snackVC.childViewControllers.first as? NavigationDrawerController,
            let navVC = rootVC.childViewControllers.first as? UINavigationController,
            let inboxVC = navVC.childViewControllers.first as? InboxViewController else {
                return
        }
        
        inboxVC.getPendingEvents(nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("===== did become active")
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
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Delivers a notification to an app running in the foreground.
        
        guard let snackVC = self.window?.rootViewController?.snackbarController,
            let rootVC = snackVC.childViewControllers.first as? NavigationDrawerController,
            let navVC = rootVC.childViewControllers.first as? UINavigationController,
            let inboxVC = navVC.childViewControllers.first as? InboxViewController else {
                completionHandler([])
                return
        }
        
        inboxVC.getPendingEvents(nil)
    }
}
