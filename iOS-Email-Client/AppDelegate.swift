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
import Firebase
import FirebaseMessaging
import UserNotifications
import RealmSwift
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // Initialize sign-in
        Fabric.with([Crashlytics.self])
        FIRApp.configure()
        
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
        
        self.window?.tintColor = UIColor.black
        
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(String(describing: configureError))")
        
        GIDSignIn.sharedInstance().scopes.append("https://mail.google.com/")
        GIDSignIn.sharedInstance().serverClientID = "249459851975-65698k7s4pb2pa1klkddb5fj0b330fro.apps.googleusercontent.com"
        
        var initialVC:UIViewController!
        
        let defaults = UserDefaults.standard
        if defaults.string(forKey: "activeAccount") != nil {
            //Go to inbox
            initialVC = initMailboxRootVC(launchOptions)
        }else{
            //Go to login
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            initialVC = storyboard.instantiateInitialViewController()
        }
        
        self.replaceRootViewController(initialVC)
        IQKeyboardManager.sharedManager().enable = true
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
            
            // For iOS 10 data message (sent via FCM)
            FIRMessaging.messaging().remoteMessageDelegate = self
            
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
    
    func initMailboxRootVC(_ launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> UIViewController{
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let rootVC = storyboard.instantiateViewController(withIdentifier: "InboxNavigationController") as! UINavigationController
        let sidemenuVC = storyboard.instantiateViewController(withIdentifier: "ListLabelViewController") as! ListLabelViewController
        let inboxVC = rootVC.childViewControllers.first as! InboxViewController
        sidemenuVC.detailViewController = inboxVC
        GIDSignIn.sharedInstance().delegate = inboxVC
        
        if let launchOptions = launchOptions,
            let notification = launchOptions[UIApplicationLaunchOptionsKey.remoteNotification] as? NSDictionary,
            let threadId = notification.object(forKey: "threadId") as? String  {
            inboxVC.threadToOpen = threadId
        }
        
        let feedsRightView = storyboard.instantiateViewController(withIdentifier: "FeedsViewController") as! FeedViewController
        
        let drawerVC = CriptextDrawerController(rootViewController: rootVC, leftViewController: sidemenuVC, rightViewController: feedsRightView)
        drawerVC.delegate = inboxVC
        return SnackbarController(rootViewController: drawerVC)
    }
    
    func application(application: UIApplication,
                     openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return GIDSignIn.sharedInstance().handle(url as URL!,
                                                 sourceApplication: sourceApplication,
                                                 annotation: annotation)
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
        
        inboxVC.handleRefresh(inboxVC.refreshControl, automatic: true, signIn: false, completion: nil)
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("===== did become active")
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return self.application(app, processOpenURLAction: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String?, annotation: options[UIApplicationOpenURLOptionsKey.annotation] as Any, iosVersion: 9)
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return self.application(application, processOpenURLAction: url, sourceApplication: sourceApplication, annotation: annotation, iosVersion: 8)
    }
    
    func application(_ application: UIApplication, processOpenURLAction url: URL, sourceApplication: String?, annotation: Any, iosVersion: Int) -> Bool {
        return GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        
        guard let snackVC = self.window?.rootViewController?.snackbarController,
            let rootVC = snackVC.childViewControllers.first as? NavigationDrawerController,
            let navVC = rootVC.childViewControllers.first as? UINavigationController,
            let inboxVC = navVC.childViewControllers.first as? InboxViewController,
            let deviceTokenString = FIRInstanceID.instanceID().token() else {
                return
        }
        
        inboxVC.register(deviceTokenString)
    }
    
    
    
}

extension AppDelegate: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return false
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        guard let threadId = response.notification.request.content.userInfo["threadId"] as? String,
            let snackVC = self.window?.rootViewController?.snackbarController,
            let rootVC = snackVC.childViewControllers.first as? NavigationDrawerController,
            let navVC = rootVC.childViewControllers.first as? UINavigationController,
            let inboxVC = navVC.childViewControllers.first as? InboxViewController else {
                completionHandler()
                return
        }
        
        inboxVC.open(threadId: threadId)
        
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Delivers a notification to an app running in the foreground.
        
        guard let snackVC = self.window?.rootViewController?.snackbarController,
            let rootVC = snackVC.childViewControllers.first as? NavigationDrawerController,
            let navVC = rootVC.childViewControllers.first as? UINavigationController,
            let inboxVC = navVC.childViewControllers.first as? InboxViewController else {
                completionHandler([])
                return
        }
        
        inboxVC.handleRefresh(inboxVC.refreshControl, automatic: true) {
            completionHandler([])//completionHandler([.badge, .alert, .sound])
        }
    }
}

extension AppDelegate: FIRMessagingDelegate {
    func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
        print("message: \(remoteMessage)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        FIRMessaging.messaging().appDidReceiveMessage(userInfo)
        
        guard let snackVC = self.window?.rootViewController?.snackbarController,
            let rootVC = snackVC.childViewControllers.first as? NavigationDrawerController,
            let navVC = rootVC.childViewControllers.first as? UINavigationController,
            let inboxVC = navVC.childViewControllers.first as? InboxViewController else {
                completionHandler(.noData)
                return
        }
        
        inboxVC.handleRefresh(inboxVC.refreshControl, automatic: true) {
            completionHandler(.newData)
        }
    }
}
