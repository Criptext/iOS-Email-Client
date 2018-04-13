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
    
    @IBOutlet weak var tableView: UITableView!
    let refreshControl = UIRefreshControl()
    @IBOutlet weak var topToolbar: NavigationToolbarView!
    @IBOutlet weak var buttonCompose: UIButton!
    
    var selectedLabel = SystemLabel.inbox.id
    
    var emailArray = [Email]()
    var filteredEmailArray = [Email]()
    var threadHash = [String:[Email]]()
    //var attachmentHash = DBManager.getAllAttachments()
    //var activities = DBManager.getAllActivities()
    var searchNextPageToken: String?
    
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
    
    var threadToOpen:String?
    
    let statusBarButton = UIBarButtonItem(title: nil, style: .plain, target: nil, action: nil)
    
    var ws:WebSocket!
    var myAccount: Account!
    
    var originalNavigationRect:CGRect!
    var isCustomEditing = false
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
//        CriptextSpinner.show(in: self.view, title: nil, image: UIImage(named: "icon_sent_chat.png"))
        
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
        self.loadMails(from: selectedLabel, since: Date())
        
        self.navigationItem.leftBarButtonItems = [self.menuButton, self.fixedSpaceBarButton, self.titleBarButton, self.countBarButton]
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.emailTrashed), name: NSNotification.Name(rawValue: "EmailTrashed"), object: nil)
        
        self.initFloatingButton()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(getPendingEvents(_:)), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let indexPath = self.tableView.indexPathForSelectedRow, !self.isCustomEditing else {
            return
        }
        
        self.tableView.deselectRow(at: indexPath, animated: true)
        
        guard let indexArray = self.tableView.indexPathsForVisibleRows,
            let index = indexArray.first,
            index.row == 0,
            !self.searchController.isActive else {
            return
        }
        
    }
    
    // When the view appears, ensure that the Gmail API service is authorized
    // and perform API calls
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
        
//        self.cancelBarButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(didPressEdit))
        let derp = UIButton(type: .custom)
        derp.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        derp.setImage(#imageLiteral(resourceName: "menu-back"), for: .normal)
        derp.layer.backgroundColor = UIColor.red.cgColor
        derp.layer.cornerRadius = 15.5
        derp.addTarget(self, action: #selector(didPressEdit), for: .touchUpInside)
        
        self.cancelBarButton = UIBarButtonItem(customView: derp)
        
        self.trashBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "delete-icon"), style: .plain, target: self, action: #selector(didPressTrash))
        self.trashBarButton.tintColor = UIColor.white
        
        self.trashBarButton.isEnabled = false
        self.archiveBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "archive-icon"), style: .plain, target: self, action: #selector(didPressArchive))
        self.archiveBarButton.tintColor = UIColor.white
        self.archiveBarButton.isEnabled = false
        
        self.markBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "mark_read"), style: .plain, target: self, action: #selector(didPressMark))
        
        self.deleteBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "delete-icon"), style: .plain, target: self, action: #selector(didPressDelete))
        self.deleteBarButton.tintColor = UIColor.white
        self.counterBarButton = UIBarButtonItem(title: nil, style: .plain, target: self, action: nil)
        self.counterBarButton.tintColor = Icon.system.color
        self.titleBarButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "NunitoSans-Bold", size: 16.0)!, NSAttributedStringKey.foregroundColor: UIColor.white], for: .disabled)
        self.titleBarButton.isEnabled = false
        
        self.countBarButton.tintColor = UIColor(red:0.73, green:0.73, blue:0.74, alpha:1.0)
        self.countBarButton.setTitleTextAttributes([NSAttributedStringKey.font: UIFont(name: "NunitoSans-Bold", size: 16.0)!, NSAttributedStringKey.foregroundColor: UIColor(red:0.73, green:0.73, blue:0.74, alpha:1.0)], for: .disabled)
        self.countBarButton.isEnabled = false
        
        let attributescounter = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 20)]
        self.counterBarButton.setTitleTextAttributes(attributescounter, for: .normal)
        
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
        activityButton.addTarget(self, action: #selector(didPressActivity), for: UIControlEvents.touchUpInside)
        self.activityBarButton = UIBarButtonItem(customView: activityButton)
        
        self.activityBarButton.tintColor = UIColor.white
        
        let font:UIFont = Font.regular.size(13)!
        let attributes:[NSAttributedStringKey : Any] = [NSAttributedStringKey.font: font];
        self.statusBarButton.setTitleTextAttributes(attributes, for: .normal)
        self.statusBarButton.tintColor = UIColor.darkGray
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
    
    @objc func getPendingEvents(_ refreshControl: UIRefreshControl?) {
        APIManager.getEvents(token: myAccount.jwt) { (error, data) in
            let asyncGroupCalls = DispatchGroup()
            refreshControl?.endRefreshing()
            guard error == nil else {
                print(error.debugDescription)
                return
            }
            let keysArray = data as! Array<Dictionary<String, Any>>
            keysArray.forEach({ (keys) in
                asyncGroupCalls.enter()
                let cmd = keys["cmd"] as! Int32
                guard let params = Utils.convertToDictionary(text: (keys["params"] as! String)) else {
                    return
                }
                switch(cmd){
                case 1:
                    self.handleNewEmailCommand(params: params){
                        asyncGroupCalls.leave()
                    }
                    break
                default:
                    break
                }
            })
            asyncGroupCalls.notify(queue: .main) {
                self.didPressLabel(labelId: self.selectedLabel, sender: nil)
            }
        }
    }
    
    func handleNewEmailCommand(params: [String: Any], finishCallback: @escaping () -> Void){
        let threadId = params["threadId"] as! String
        let subject = params["subject"] as! String
        let from = params["from"] as! String
        let to = params["to"] as! String
        let cc = params["cc"] as! String
        let bcc = params["bcc"] as! String
        let bodyKey = params["bodyKey"] as! String
        let preview = params["preview"] as! String
        let date = params["date"] as! String
        let metadataKey = params["metadataKey"] as! Int32
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let localDate = dateFormatter.date(from: date)
        
        guard DBManager.getMailByKey(key: metadataKey.description) == nil else {
            print("yala \(metadataKey)")
            finishCallback()
            return
        }
        
        let email = Email()
        email.threadId = threadId
        email.subject = subject
        email.key = metadataKey.description
        email.s3Key = bodyKey
        email.preview = preview
        email.date = localDate
        
        APIManager.getEmailBody(s3Key: email.s3Key, token: myAccount.jwt) { (error, data) in
            guard error == nil else {
                finishCallback()
                return
            }
            let signalMessage = data as! String
            email.content = self.decryptMessage(signalMessage)
            email.preview = String(email.content.prefix(100))
            email.labels.append(DBManager.getLabel(SystemLabel.inbox.id)!)
            DBManager.store(email)
            
            self.parseContacts(from, email: email, type: .from)
            self.parseContacts(to, email: email, type: .to)
            self.parseContacts(cc, email: email, type: .cc)
            self.parseContacts(bcc, email: email, type: .bcc)
            finishCallback()
        }
        
    }
    
    func decryptMessage(_ encryptedMessageB64: String) -> String{
        let axolotlStore = CriptextAxolotlStore(myAccount.regId, myAccount.identityB64)
        let sessionCipher = SessionCipher(axolotlStore: axolotlStore, recipientId: myAccount.username, deviceId: 1)
        let incomingMessage = PreKeyWhisperMessage.init(data: Data.init(base64Encoded: encryptedMessageB64))
        let plainText = sessionCipher?.decrypt(incomingMessage)
        let plainTextString = NSString(data:plainText!, encoding:String.Encoding.ascii.rawValue)
        print("decrypted: \(String(describing: plainTextString))")
        return plainTextString! as String
    }
    
    func parseContact(_ contactString: String) -> Contact {
        let splittedContact = contactString.split(separator: "<")
        guard splittedContact.count > 1 else {
            return Contact(value: ["displayName": contactString, "email": contactString])
        }
        let contactName = splittedContact[0].prefix((splittedContact[0].count - 1))
        let email = splittedContact[1].prefix((splittedContact[1].count - 1))
        return Contact(value: ["displayName": contactName, "email": email])
    }
    
    func parseContacts(_ contactsString: String, email: Email, type: ContactType){
        let contacts = contactsString.split(separator: ",")
        contacts.forEach { (contactString) in
            let contact = parseContact(contactsString)
            let emailContact = EmailContact()
            emailContact.contact = contact
            emailContact.email = email
            emailContact.type = type.rawValue
            DBManager.store([contact])
            DBManager.store([emailContact])
        }
    }
}

//MARK: - Modify mails actions
extension InboxViewController{
    @objc func didPressEdit() {
        self.isCustomEditing = !self.isCustomEditing
//        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
        
        if self.isCustomEditing {
            self.topToolbar.counterButton.title = "1"
            self.title = ""
            self.navigationItem.leftBarButtonItems = [self.cancelBarButton, self.counterBarButton]
            self.topToolbar.isHidden = false
        }else{
            self.topToolbar.isHidden = true
            self.navigationController?.navigationBar.isHidden = false
            self.navigationItem.leftBarButtonItems = [self.menuButton, self.fixedSpaceBarButton, self.titleBarButton, self.countBarButton]
            self.titleBarButton.title = self.selectedLabel.description.uppercased()
            self.navigationController?.navigationBar.frame = self.originalNavigationRect
//            self.title = self.selectedLabel.description
        }
        
        //disable toolbar buttons
        if !self.isCustomEditing {
            self.toggleToolbar(false)
        }
        
        self.setButtonItems(isEditing: self.isCustomEditing)
    }
    
    @IBAction func didPressComposer(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    
    
    @objc func didPressActivity(_ sender: UIBarButtonItem) {
        
        
    }
    
    @objc func didPressArchive(_ sender: UIBarButtonItem) {
        guard let emailsIndexPath = self.tableView.indexPathsForSelectedRows,
            (self.selectedLabel == SystemLabel.inbox.id || self.selectedLabel == SystemLabel.junk.id) else {
                if self.isCustomEditing {
                    self.didPressEdit()
                }
            return
        }
        
//        self.emailArray.remove(at: indexPath.row)
        self.tableView.deleteRows(at: emailsIndexPath, with: .fade)
    }
    
    @objc func didPressTrash(_ sender: UIBarButtonItem) {
        guard let emailsIndexPath = self.tableView.indexPathsForSelectedRows else {
            if self.isCustomEditing {
                self.didPressEdit()
            }
            return
        }
        
//        let email = self.emailArray.remove(at: emailsIndexPath.first!.row)
        self.tableView.deleteRows(at: emailsIndexPath, with: .fade)
    }
    
    @objc func emailTrashed(notification:Notification) -> Void {
        guard let userInfo = notification.userInfo,
            let emailTrashed  = userInfo["email"] as? Email else {
                print("No userInfo found in notification")
                return
        }
        
        if let index = self.emailArray.index(of: emailTrashed) {
            self.emailArray.remove(at: index)
        }
        
        if var threadArray = self.threadHash[emailTrashed.threadId],
            let index = threadArray.index(of: emailTrashed) {
            threadArray.remove(at: index)
            self.threadHash[emailTrashed.threadId] = threadArray
        }
        
        self.tableView.reloadData()
    }
    
    @objc func didPressMove(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let moveVC = storyboard.instantiateViewController(withIdentifier: "MoveMailViewController") as! MoveMailViewController
        
        self.present(moveVC, animated: true, completion: nil)
    }
    
    @objc func didPressMark(_ sender: UIBarButtonItem) {
        
        guard let emailsIndexPath = self.tableView.indexPathsForSelectedRows else {
            return
        }
        
        var markRead = true
        
        let emails = emailsIndexPath.map { return self.emailArray[$0.row] }
        
        var count = 0
        
        if count == emails.count {
            markRead = false
        }
        
        
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        var title = "Unread"
        if markRead {
            title = "Read"
        }
        
        sheet.addAction(UIAlertAction(title: "Mark as \(title)" , style: .default) { (action) in
            self.didPressEdit()
            
            let emailThreadIds = emailsIndexPath.map { return self.emailArray[$0.row].threadId }
            
            var addLabels:[String]?
            var removeLabels:[String]?
        })
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        sheet.popoverPresentationController?.sourceView = self.view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        
        self.present(sheet, animated: true, completion: nil)
    }
    
    func didPressDeleteAll(_ sender: UIBarButtonItem) {
        
        if self.isCustomEditing {
            self.didPressEdit()
        }
        
        for email in self.emailArray {
            if let hashEmails = self.threadHash[email.threadId] {
                DBManager.delete(hashEmails)
            }
        }
        self.emailArray.removeAll()
        self.threadHash.removeAll()
        self.tableView.reloadData()
    }
    
    @objc func didPressDelete(_ sender: UIBarButtonItem) {
        guard let emailsIndexPath = self.tableView.indexPathsForSelectedRows else {
            if self.isCustomEditing {
                self.didPressEdit()
            }
            return
        }
        
        for indexPath in emailsIndexPath {
            let threadId = self.emailArray[indexPath.row].threadId
            
            if let hashEmails = self.threadHash[threadId] {
                DBManager.delete(hashEmails)
                self.threadHash.removeValue(forKey: threadId)
            }
            self.emailArray.remove(at: indexPath.row)
        }
        self.tableView.deleteRows(at: emailsIndexPath, with: .fade)
    }
    
    func didPressLabel(labelId: Int, sender: Any?){
        self.selectedLabel = labelId
        loadMails(from: labelId, since: Date())
        self.navigationDrawerController?.closeLeftView()
    }
}

//MARK: - Side menu events
extension InboxViewController {
    
    @IBAction func didPressOpenMenu(_ sender: UIBarButtonItem) {
        self.navigationDrawerController?.toggleLeftView()
    }
    
    @IBAction func didPressSearch(_ sender: UIBarButtonItem) {
        self.searchController.searchBar.becomeFirstResponder()
    }
    
    func showSignature(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let signatureVC = storyboard.instantiateViewController(withIdentifier: "SignatureViewController") as! SignatureViewController
        
        self.navigationController?.childViewControllers.last!.present(signatureVC, animated: true, completion: nil)
    }
    
    func showHeader(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let headerVC = storyboard.instantiateViewController(withIdentifier: "HeaderViewController") as! HeaderViewController
        
        self.navigationController?.childViewControllers.last!.present(headerVC, animated: true, completion: nil)
    }
    
    func showShareDialog(){
        
        let linkUrl = "https://criptext.com/getapp"
        let textInvite = "I'm using Criptext for Gmail, it allows me to have control over my emails. Install it now: "
        let htmlInvite = "<html><body><p>\(textInvite)</p><p><a href='\(linkUrl)'>\(linkUrl)</a></p></body></html>"
        
        let textItem = ShareActivityItemProvider(placeholderItem: "wat")
        
        textItem.invitationText = textInvite
        textItem.invitationTextMail = htmlInvite
        textItem.subject = "Criptext for Gmail Invitation"
        textItem.otherappsText = textInvite
        
        let urlItem = URLActivityItemProvider(placeholderItem: linkUrl)
        
        urlItem.urlInvite = URL(string: linkUrl)
        
        let shareVC = UIActivityViewController(activityItems: [textItem, urlItem], applicationActivities: nil)
        
        shareVC.excludedActivityTypes = [.airDrop, .assignToContact, .print, .saveToCameraRoll, .addToReadingList]
        
        shareVC.completionWithItemsHandler = { (type, completed, returnedItems, error) in
            if !completed {
                return
            }
            
            if type == .copyToPasteboard {
                self.showAlert(nil, message: "Copied to clipboard", style: .alert)
            }
        }
        
        shareVC.popoverPresentationController?.sourceView = self.view
        shareVC.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        
        self.navigationController?.childViewControllers.last!.present(shareVC, animated: true, completion: nil)
        
    }
    
    func showSupport(){
        
        let body = "Type your message here...<br><br><br><br><br><br><br>Do not write below this line.<br>*****************************<br> Version: 1.2<br> Device: \(systemIdentifier()) <br> OS: iOS \(UIDevice.current.systemVersion)"
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let composeVC = navComposeVC.childViewControllers.first as! ComposeViewController
        composeVC.loadViewIfNeeded()
        composeVC.addToken("support@criptext.com", value: "support@criptext.com", to: composeVC.toField)
        composeVC.subjectField.text = "Criptext iPhone Support"
        composeVC.editorView.html = body
        composeVC.thumbUpdated = true
        
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        
        self.navigationController?.childViewControllers.last!.present(snackVC, animated: true, completion: nil)
    }
    
    func changeDefaultValue(_ isOn:Bool){
        //DBManager.update(self.currentUser, switchValue: isOn)
    }
}

//MARK: - Unwind Segues
extension InboxViewController{
    //move mail, unwind segue
    @IBAction func selectedMailbox(_ segue:UIStoryboardSegue){
        let vc = segue.source as! MoveMailViewController
        
        guard let selectedMailbox = vc.selectedMailbox,
            let emailsIndexPath = self.tableView.indexPathsForSelectedRows else {
            return
        }
        
        if self.navigationController!.viewControllers.count > 1 {
            self.navigationController?.popViewController(animated: true)
        }
        
        if self.isCustomEditing {
            self.didPressEdit()
        }
        
        var removeLabels: [String]?
        
        for indexPath in emailsIndexPath {
            let threadId = self.emailArray[indexPath.row].threadId
        }
        self.emailArray.removeAll()
        self.threadHash.removeAll()
        self.loadMails(from: selectedLabel, since: Date())
        self.tableView.reloadData()
    }
}

//MARK: - Websocket
extension InboxViewController{
    func startWebSocket(){
        
        let defaults = UserDefaults.standard
        let since = defaults.integer(forKey: "lastSync")
        self.ws = WebSocket("wss://com.criptext.com:3000?user_id=1&session_id=\(NSUUID().uuidString)&since=\(since)", subProtocols:["criptext-protocol"])
        
        self.ws.event.open = {
            print("opened")
        }
        self.ws.event.close = { code, reason, clean in
            print("close")
            self.startWebSocket()
        }
        self.ws.event.error = { error in
            print("error \(error)")
        }
        self.ws.event.message = { message in
            guard let text = message as? String,
                let mails = JSON.parse(text).array else {
                    return
            }
            
            print("recv: \(text)")
            
            var shouldReload = false
            var lastSync = 0
            var totalMailOpens = 0
            for mail in mails {
                let cmd = mail["cmd"].intValue
                
                switch cmd {
                case Commands.userStatus.rawValue:
                    let newStatus = mail["args"]["msg"].intValue
                    //DBManager.update(self.currentUser, status:newStatus)
                    
                    if let plan = mail["args"]["plan"].string {
                        
                       // DBManager.update(self.currentUser, plan:plan.isEmpty ? "Free trial" : plan)
                    }
                    
                case Commands.emailOpened.rawValue:
                    
                    //SEND NOTIFICATIONS TO ACTIVITY
                    //NotificationCenter.default.post(name: Notification.Name.Activity.onMsgNotificationChange, object: nil, userInfo: ["token": token!])
                    
                    shouldReload = true
                    
                case Commands.emailUnsend.rawValue:
                    //[{"cmd":4,"args":{"uid_from":1,"uid_to":"100","timestamp":1492039527,"msg":<token>},"timestamp":1492039527}]
                    
                    shouldReload = true
                    
                case Commands.fileOpened.rawValue:
                    //[{"cmd":2,"args":{"uid_from":1,"uid_to":"100","location":"Guayaquil, EC","timestamp":1492039785,"file_token":"f2ao1vzakh85mij1ds17wncb40qenkp661dcxr","email_token":"967nl7v92fqrggb9j1ds1r7rzkdf6vfj2sf3l3di","file_name":"7-Activity-Inbox.png"},"timestamp":1492039785}]
                    
                    shouldReload = true
                    
                case Commands.fileDownloaded.rawValue:
                    //[{"cmd":3,"args":{"uid_from":1,"uid_to":"100","location":"Guayaquil, EC","timestamp":1492039847,"file_token":"f2ao1vzakh85mij1ds17wncb40qenkp661dcxr","email_token":"967nl7v92fqrggb9j1ds1r7rzkdf6vfj2sf3l3di","file_name":"7-Activity-Inbox.png"},"timestamp":1492039847}]
                    
                    shouldReload = true
                    
                case Commands.emailCreated.rawValue:
                    //[{"cmd":54,"args":{"uid_from":1,"uid_to":"100","timestamp":1492103587,"msg":"9814u5geuaulq5mij1gny37yfsnb0uoafrsh5mi:mayer@criptext.com"},"timestamp":1492103587}]
                    break
                    
                case Commands.fileCreated.rawValue:
                    //[{"cmd":55,"args":{"uid_from":1,"uid_to":"100","timestamp":1492103609,"msg":"9814u5geuaulq5mij1gny37yfsnb0uoafrsh5mi"},"timestamp":1492103609}]
                    break
                case Commands.emailMute.rawValue:
                    //{"cmd":5,"args":{"uid_from":156,"uid_to":"5634","timestamp":1499355531, "msg":{"tokens":"fyehrgfgnfyndwgtrt54g,5gyuetyehwgy5egtyg","mute":"0"}},"timestamp":1499355531}
                    
                    break
                    
                default:
                    print("unsupported command")
                }
                lastSync = mail["timestamp"].intValue
            }
            
            //SAVE THE LAST SYNC
            defaults.set(lastSync, forKey: "lastSync")
            
            //UPDATE BADGE
            if(totalMailOpens > 0){
                //DBManager.update(self.currentUser, badge: self.currentUser.badge + totalMailOpens)
                //self.updateBadge(self.currentUser.badge)
            }
            
            guard shouldReload, let indexPaths = self.tableView.indexPathsForVisibleRows else {
                return
            }
            
            self.tableView.reloadRows(at: indexPaths, with: .automatic)
        }
        
    }
    
    func stopWebsocket(){
        self.ws.event.close = {_,_,_ in }
        self.ws.close()
    }
    
    func updateBadge(_ count: Int){
        
        let activityButton = self.activityBarButton?.customView as! MIBadgeButton?
        if(count == 0){
            activityButton?.badgeString = ""
        }
        else{
            activityButton?.badgeString = String(count)
        }
        
    }
}

//MARK: - UIBarButton layout
extension InboxViewController{
    func setButtonItems(isEditing: Bool){
        
        if(!isEditing){
            self.navigationItem.rightBarButtonItems = [self.activityBarButton, self.searchBarButton, self.spaceBarButton]
            return
        }
        
        var items:[UIBarButtonItem] = []
        
        self.navigationItem.rightBarButtonItems = items
    }
    
    func toggleToolbar(_ isEnabled:Bool){
        
    }
}

//MARK: - Load mails
extension InboxViewController{
    func open(threadId:String) {
        
        guard let threadArray = self.threadHash[threadId],
            let firstMail = threadArray.first,
            let index = self.emailArray.index(of: firstMail) else {
                self.threadToOpen = threadId
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        print("selecting cell")
        
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.tableView(self.tableView , didSelectRowAt: indexPath)
        
        self.threadToOpen = nil
    }
    
    func loadMails(from label: Int, since date:Date){
        let tuple = DBManager.getMails(from: label, since: date)
        self.emailArray = tuple.1
        self.tableView.reloadData()
        
        //@TODO: remove return statement and paginate mails from db
        return
    }
}

//MARK: - Google SignIn Delegate
extension InboxViewController{
    
    //silent sign in callback
   
    func signout(){
        self.stopWebsocket()
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
        
        guard let tappedView = self.view.hitTest(touchPt, with: nil) else {
            return true
        }
        
        
//        if gestureRecognizer == self.dismissTapGestureRecognizer && tappedView.isDescendant(of: self.contactTableView) && !self.contactTableView.isHidden {
//            return false
//        }
        
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
            email = self.filteredEmailArray[indexPath.row]
        }else {
            email = self.emailArray[indexPath.row]
        }
        
        let isSentFolder = self.selectedLabel == SystemLabel.sent.id
        
        //Set colors to initial state
        cell.secureAttachmentImageView.tintColor = UIColor(red:0.84, green:0.84, blue:0.84, alpha:1.0)
        
        //Set row status
        if !email.unread || isSentFolder {
            cell.backgroundColor = UIColor(red:0.96, green:0.96, blue:0.96, alpha:1.0)
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
        
//        var senderText = (isSentFolder || self.selectedLabel == .draft) ? email.to : email.fromDisplayString
        
//        if self.currentUser.email == email.from && self.selectedLabel != .sent {
//            senderText = "me"
//        }
        
//        cell.senderLabel.text = senderText
//
//        if senderText.isEmpty {
//            cell.senderLabel.text = "No Recipients"
//        }
        
        if self.isCustomEditing {
            cell.avatarImageView.image = nil
            cell.avatarImageView.layer.borderWidth = 1.0
            cell.avatarImageView.layer.borderColor = UIColor.lightGray.cgColor
            cell.avatarImageView.layer.backgroundColor = UIColor.lightGray.cgColor
        } else {
            
            let initials = cell.senderLabel.text!.replacingOccurrences(of: "\"", with: "")
            cell.avatarImageView.setImageForName(string: initials, circular: true, textAttributes: nil)
            cell.avatarImageView.layer.borderWidth = 0.0
        }
        
        guard let emailArrayHash = self.threadHash[email.threadId], emailArrayHash.count > 1 else{
            cell.containerBadge.isHidden = true
            cell.badgeWidthConstraint.constant = 0
            return cell
        }
        
//        let names = emailArrayHash.map { (mail) -> String in
//            var senderText = mail.fromDisplayString
//
//            if self.currentUser.email == mail.from {
//                senderText = "me"
//            }
//
//            return senderText
//        }
//
//        cell.senderLabel.text = Array(Set(names)).joined(separator: ", ")
        
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
            return self.filteredEmailArray.count
        }
        return self.emailArray.count
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
        
        if self.isCustomEditing {
            return
        }
        
        self.didPressEdit()
        
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        
        if self.tableView.indexPathsForSelectedRows == nil {
//            print("count \(indexPaths.count)")
            self.tableView.reloadData()
        }
        
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.tableView(self.tableView , didSelectRowAt: indexPath)
    }
    
    func tableViewCellDidTap(_ cell: InboxTableViewCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        
//        if self.tableView.isEditing {
//            
//            return
//        }
        
        if cell.isSelected {
            self.tableView.deselectRow(at: indexPath, animated: true)
            self.tableView(tableView, didDeselectRowAt: indexPath)
            return
        }
        
        self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        self.tableView(self.tableView , didSelectRowAt: indexPath)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if self.isCustomEditing {
            guard let indexPaths = tableView.indexPathsForSelectedRows else {
                return
            }
            
            if indexPaths.count == 1 {
                self.toggleToolbar(true)
            }
            
            let cell = tableView.cellForRow(at: indexPath) as! InboxTableViewCell
            
            cell.avatarImageView.layer.backgroundColor = UIColor(red:0.00, green:0.57, blue:1.00, alpha:1.0).cgColor
            cell.avatarImageView.image = #imageLiteral(resourceName: "check")
            cell.avatarImageView.tintColor = UIColor.white
            
            
            self.topToolbar.counterButton.title = "\(indexPaths.count)"
            return
        }
        
        let selectedEmail = self.emailArray[indexPath.row]
        let emails = DBManager.getMailsbyThreadId(selectedEmail.threadId, label: 1)
        let emailDetailData = EmailDetailData()
        emailDetailData.emails = emails
        emailDetailData.labels += emails.first!.labels
        emailDetailData.subject = emails.first!.subject
        
        emails.last?.isExpanded = true
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if self.selectedLabel != SystemLabel.draft.id {
            let vc = storyboard.instantiateViewController(withIdentifier: "EmailDetailViewController") as! EmailDetailViewController
            vc.emailData = emailDetailData
            self.navigationController?.pushViewController(vc, animated: true)
            return
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        guard self.isCustomEditing else {
            return
        }
        
        guard tableView.indexPathsForSelectedRows == nil else {
            self.topToolbar.counterButton.title = "\(tableView.indexPathsForSelectedRows!.count)"
            let cell = tableView.cellForRow(at: indexPath) as! InboxTableViewCell
            cell.avatarImageView.image = nil
            return
        }
        
        self.toggleToolbar(false)
        self.didPressEdit()
        self.tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let lastEmail = (self.searchController.isActive  && self.searchController.searchBar.text != "") ? self.filteredEmailArray.last : self.emailArray.last,
            let threadEmailArray = self.threadHash[lastEmail.threadId], let firstThreadEmail = threadEmailArray.first else {
                return
        }
        
        let email:Email
        if self.searchController.isActive && self.searchController.searchBar.text != "" {
            email = self.filteredEmailArray[indexPath.row]
        }else {
            email = self.emailArray[indexPath.row]
        }
        if email == lastEmail {
            if(searchController.searchBar.text == ""){
                self.loadMails(from: selectedLabel, since: firstThreadEmail.date!)
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
        
        let email:Email
        if self.searchController.isActive && self.searchController.searchBar.text != "" {
            email = self.filteredEmailArray[indexPath.row]
        }else {
            email = self.emailArray[indexPath.row]
        }
        
        guard self.selectedLabel != SystemLabel.trash.id else {
            return []
        }
        
        let trashAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "         ") { (action, index) in
            
            if self.searchController.isActive && self.searchController.searchBar.text != "" {
                let emailTmp = self.filteredEmailArray.remove(at: indexPath.row)
                guard let index = self.emailArray.index(of: emailTmp) else {
                    return
                }
                self.emailArray.remove(at: index)
            }else {
                self.emailArray.remove(at: indexPath.row)
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
        filteredEmailArray = emailArray.filter { email in
            return email.content.lowercased().contains(searchText.lowercased())
                || email.subject.lowercased().contains(searchText.lowercased())
        }
        
        self.tableView.reloadData()
        
        if(searchText != ""){
            self.searchNextPageToken = "0"
            self.loadSearchedMails()
        }
    }
    
    func loadSearchedMails(){
        //search emails
    }
    
    func addSearchedFetched(_ emails:[Email]){
        self.filteredEmailArray.removeAll()
        for email in emails {
            DBManager.store(email)
            
            if self.threadHash[email.threadId] == nil {
                self.threadHash[email.threadId] = []
            }
            
            var threadArray = self.threadHash[email.threadId]!
            
            if !threadArray.contains(email){
                self.threadHash[email.threadId]!.append(email)
            }
            
            threadArray.sort(by: { $0.date?.compare($1.date!) == ComparisonResult.orderedDescending })
            
            if !self.filteredEmailArray.contains(where: { $0.threadId == email.threadId }) {
                self.filteredEmailArray.append(email)
            }
            
            if let dummyEmail = self.filteredEmailArray.first(where: { $0.threadId == email.threadId }),
                let index = self.filteredEmailArray.index(of: dummyEmail), email.date! > dummyEmail.date! {
                self.filteredEmailArray[index] = email
            }
        }
        
        self.filteredEmailArray.sort(by: { $0.date?.compare($1.date!) == ComparisonResult.orderedDescending })
        
        self.tableView.reloadData()
    }
}
