//
//  DetailViewController.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/9/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST
import QuickLook
import SwiftSoup
import Material

class DetailViewController: UIViewController {
    @IBOutlet weak var toLabel: UILabel!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var ccLabel: UILabel!
    
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var timerButton: UIButton!
    @IBOutlet weak var attachButton: UIButton!
    @IBOutlet weak var lockButton: UIButton!
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var subjectSpacingConstraint: NSLayoutConstraint!//initial 12, compressed -20
    @IBOutlet weak var timerTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var unsendButton: UIButton!
    
    var currentEmail:Email!
    var currentEmailIndex:Int!
    var threadEmailArray:[Email]!
    var selectedLabel:Label!
    
    var currentUser: User!
    var currentService: GTLRService!
    var activity:Activity?
    var attachmentArray = [Attachment]() //AttachmentGmail or AttachmentCriptext
    var attachmentGmailArray = [AttachmentGmail]()
    let rowHeight:CGFloat = 65.0
    var shouldReloadWebView = true
    
    var fixedSpaceBarButton:UIBarButtonItem!
    var unsendBarButton:UIBarButtonItem!
    var trashBarButton:UIBarButtonItem!
    var replyBarButton:UIBarButtonItem!
    var archiveBarButton:UIBarButtonItem!
    var moveBarButton:UIBarButtonItem!
    var webViewCollapsedHeight:CGFloat!
    
    lazy var previewController = QLPreviewController()
    lazy var previewItem = PreviewItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.webViewCollapsedHeight = self.webView.bounds.height
        
        self.unsendButton.tintColor = UIColor(red:0.85, green:0.29, blue:0.22, alpha:1.0)
        self.unsendButton.setImage(Icon.btn_unsend.image, for: .normal)
        self.unsendButton.isEnabled = true
        self.unsendButton.isHidden = false
        self.lockButton.isHidden = false
        
        //initialize nav bar buttons
        self.fixedSpaceBarButton = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
        self.fixedSpaceBarButton.width = 20.0
        
        self.archiveBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "archive-icon"), style: .plain, target: self, action: #selector(didPressArchive))
        
        self.trashBarButton = UIBarButtonItem(image: #imageLiteral(resourceName: "delete-icon"), style: .plain, target: self, action: #selector(didPressTrash))
        
        self.replyBarButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.reply, target: self, action: #selector(didPressReply(_:)))
        
        self.navigationItem.rightBarButtonItems = [self.replyBarButton, self.trashBarButton, self.archiveBarButton]
        
        self.lockButton.tintColor = Icon.enabled.color
        self.attachButton.tintColor = Icon.enabled.color
        self.timerButton.tintColor = Icon.enabled.color
        self.timerButton.isHidden = true
        
        if self.selectedLabel == .inbox || self.selectedLabel == .junk || self.selectedLabel == .trash {
            let markButton = UIBarButtonItem(image: UIImage(named: "mark_unread"), style: .plain, target: self, action: #selector(didPressMark(_:)))
            self.navigationItem.rightBarButtonItems?.insert(markButton, at: 1)
        }else if let activity = self.activity, self.currentEmail.realCriptextToken != "" {
            
            self.toolbarItems?[0].isEnabled = activity.exists
            if !activity.openArray.isEmpty {
                self.lockButton.tintColor = Icon.activated.color
            }
        }
        
        if self.currentEmail.realCriptextToken.isEmpty {
            self.unsendButton.isHidden = true
            self.lockButton.isHidden = true
        }
        
        self.previewController.dataSource = self
        
        self.toLabel.text = self.currentEmail.toDisplayString
        self.fromLabel.text = self.currentEmail.fromDisplayString
        self.ccLabel.text = self.currentEmail.ccDisplayString
        self.subjectLabel.text = self.currentEmail.subject.isEmpty ? "(No Subject)" : self.currentEmail.subject
        self.dateLabel.text = DateUtils.prettyDate(self.currentEmail.date)
        
        if self.currentEmail.cc.isEmpty {
            self.subjectSpacingConstraint.constant = -18
        }
        
        self.tableViewHeightConstraint.constant = CGFloat(self.attachmentArray.count + self.attachmentGmailArray.count) * self.rowHeight
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView()
        
        let jsURL = Bundle.main.url(forResource: "MCOMessageViewScript", withExtension: "js")
        let scriptContent = try! String(contentsOfFile: jsURL!.path)
        
//        let hideScript = "var replybody = document.getElementsByTagName(\"blockquote\")[0].parentElement;" +
//            "if(!document.getElementById(\"criptext_hide_show\")){" +
//            "var img = document.createElement(\"img\");" +
//            "img.id = \"criptext_hide_show\";" +
//            "img.src = \"${imageUri}\";" +
//            "img.width = 30;" +
//            "var breaker = document.createElement(\"br\");" +
//            "img.innerHTML = \"show more\";" +
//            "replybody.style.display = \"none\";" +
//            "replybody.parentElement.insertBefore(breaker, replybody);" +
//            "replybody.parentElement.insertBefore(img, replybody);" +
//            "img.addEventListener(\"click\", function(){ if(replybody.style.display == \"block\"){ " +
//            "replybody.style.display = \"none\";} else {" +
//            "replybody.style.display = \"block\";} });" +
//            "}else{" +
//            "var img = document.getElementById(\"criptext_hide_show\");" +
//            "img.addEventListener(\"click\", function(){ if(replybody.style.display == \"block\"){ " +
//            "replybody.style.display = \"none\";} else {" +
//            "replybody.style.display = \"block\";} });" + "}"
        
        let imagePath = Bundle.main.path(forResource: "showmore.png", ofType: nil) ?? ""
        print(imagePath)
        
        let hideScript = "var replybody = document.getElementsByTagName(\"blockquote\")[0];" +
            "var newNode = document.createElement(\"img\");" +
            "newNode.src = \"file://\(imagePath)\";" +
            "newNode.width = 30;" +
            "newNode.style.paddingTop = \"10px\";" +
            "newNode.style.paddingBottom = \"10px\";" +
            "replybody.style.display = \"none\";" +
            "replybody.parentElement.insertBefore(newNode, replybody);" +
            "newNode.addEventListener(\"click\", function(){ if(replybody.style.display == \"block\"){ " +
            "replybody.style.display = \"none\";} else {" +
        "replybody.style.display = \"block\";} window.location.href = \"inapp://heightUpdate\";});"
        
        let script = "<html><head><script>\(scriptContent)</script><style type='text/css'>body{ font-family: 'Helvetica Neue', Helvetica, Arial; margin:0; padding:30px;} hr {border: 0; height: 1px; background-color: #bdc3c7;}.show { display: block;}.hide:target + .show { display: inline;} .hide:target { display: block;} .content { display:block;} .hide:target ~ .content { display:inline;} </style></head><body></body><iframe src='x-mailcore-msgviewloaded:' style='width: 0px; height: 0px; border: none;'></iframe><script>\(hideScript)</script></html>"
        
        
        
        var loadingTitle = "Loading..."
        
        if !self.currentEmail.realCriptextToken.isEmpty {
            loadingTitle = "Decrypting..."
        }
        
        self.showSnackbar(loadingTitle, attributedText: nil, buttons: "", permanent: true)
        
        let userRef = DBManager.getReference(self.currentUser)
        let emailRef = DBManager.getReference(self.currentEmail)
        
        if self.currentUser.email != self.currentEmail.from {
            self.attachButton.isHidden = true
            self.timerButton.isHidden = true
            self.lockButton.isHidden = true
            self.unsendButton.isHidden = true
            self.lockButton.isHidden = true
            self.timerTrailingConstraint.constant = 15
        }
        
        for attachment in self.attachmentArray as! [AttachmentCriptext] {
            if self.currentUser.email == self.currentEmail.from, !attachment.openArray.isEmpty || !attachment.downloadArray.isEmpty {
                self.attachButton.tintColor = Icon.activated.color
            }
        }
        
        if let activity = self.activity,
            activity.secondsSet != 0,
            currentUser.email == self.currentEmail.from {
            
            self.timerButton.isHidden = false
            
            if activity.type != 3, !activity.openArray.isEmpty {
                //EXPIRATION ONOPEN
                self.timerButton.tintColor = Icon.activated.color
            }else if activity.type == 3 {
                //EXPIRATION ONSENT
                self.timerButton.tintColor = Icon.activated.color
            }
        }
        
        if let activity = self.activity,
            !activity.exists {
            self.timerButton.tintColor = UIColor.red
            self.attachButton.tintColor = UIColor.red
            self.lockButton.tintColor = UIColor.red
            
            //already unsent
            self.unsendButton.setImage(Icon.btn_unsent.image, for: .normal)
            self.unsendButton.isEnabled = false
            self.unsendButton.isHidden = true
        }
    
    
        if !self.attachmentArray.isEmpty {
            self.attachButton.isHidden = false
        }
        
        if !self.currentUser.isPro() {
            self.timerButton.tintColor = Icon.enabled.color
            self.attachButton.tintColor = Icon.enabled.color
            self.lockButton.tintColor = Icon.enabled.color
            self.unsendButton.tintColor = UIColor.gray
        }
        
        self.attachmentGmailArray = Array(self.currentEmail.attachments)
        
        //do everything on background thread
        DispatchQueue.global(qos: .userInitiated).async{
            
            guard let currentEmail = DBManager.getObject(emailRef),
                let currentUser = DBManager.getObject(userRef) as? User else {
                return
            }
            
            let currentEmail2 = currentEmail as! Email
            currentEmail2.criptextTokens = []
            
            if !currentEmail2.criptextTokensSerialized.isEmpty {
                currentEmail2.criptextTokens = currentEmail2.criptextTokensSerialized.components(separatedBy: ",")
            }
            
            currentEmail2.labels = currentEmail2.labelArraySerialized.components(separatedBy: ",")
            
            var doc:Document!
            do {
                doc = try SwiftSoup.parse(currentEmail2.body)
                
                //remove attachment tags
                let attachElements = try doc.getElementsByAttributeValueContaining("href", "https://mail.criptext.com/v2.0/attachment/download/")
                
                for element in attachElements {
                    if let div = element.parent(),
                        let td = div.parent(),
                        let tr = td.parent(){
                        try tr.html("")
                        
                        if let tbody = tr.parent(),
                            let table = tbody.parent() {
                            try table.attr("style", "display: none;")
                        }
                    }
                }
                
                //remove attachment tags
                let moreAttachElements = try doc.getElementsByAttributeValueContaining("href", "https://mail.criptext.com/viewer/")
                
                for element in moreAttachElements {
                    if let div = element.parent(),
                        let td = div.parent(),
                        let tr = td.parent(){
                        try tr.html("")
                        
                        if let tbody = tr.parent(),
                            let table = tbody.parent() {
                            try table.attr("style", "display: none;")
                        }
                    }
                }
                
                if let head = try doc.getElementsByTag("head").first() {
                    try head.append("<meta name='viewport' content='width=device-width,user-scalable=yes'>")
                }
                
            } catch {
                self.webView.loadHTMLString(currentEmail2.body+script, baseURL: nil)
            }
            
            guard !currentEmail2.criptextTokens.isEmpty else {
                DispatchQueue.main.async {
                    self.timerTrailingConstraint.constant = 15
                    self.webView.loadHTMLString(try! doc.html() + script, baseURL: nil)
                }
                return
            }
            
            var markOpen = [String]()
            
            if currentEmail2.from != currentUser.email {
                markOpen.append(currentEmail2.realCriptextToken)
            }
            
            APIManager.getMailDetails(currentUser,
                                      tokens: currentEmail2.criptextTokens,
                                      mark: markOpen) { (error, attachments, activity, textHash) in
                                        guard let textHash = textHash else {
                                            self.webView.loadHTMLString(self.currentEmail.body+script, baseURL: nil)
                                            return
                                        }
                                        
                                        for (key, value) in textHash {
                                            if doc == nil {
                                                break
                                            }
                                            
                                            do {
                                                //remove images tags
                                                var imgElements = try doc.getElementsByAttributeValueContaining("src", "https://mail.criptext.com/rs/\(key)")
                                                
                                                if imgElements.isEmpty() {
                                                    imgElements = try doc.getElementsByAttributeValueContaining("src", "https://mail.criptext.com/cache/\(key)")
                                                }
                                                for element in imgElements {
                                                    if let div = element.parent(),
                                                        let td = div.parent(),
                                                        let tr = td.parent(),
                                                        let tbody = tr.parent(),
                                                        let table = tbody.parent(){
                                                        try table.html(value)
                                                    }
                                                }
                                                
                                                self.webView.loadHTMLString(try doc.html() + script, baseURL: nil)
                                            } catch {
                                                self.webView.loadHTMLString(self.currentEmail.body+script, baseURL: nil)
                                            }
                                        }
                                        
                                        guard let attachmentArray = attachments else {
                                            return
                                        }
                                        
                                        for attachment in attachmentArray {
                                            
                                            
                                            if attachment.emailToken == self.currentEmail.realCriptextToken &&
                                                !self.attachmentArray.contains(where: {$0.fileToken == attachment.fileToken}) {
                                                self.attachmentArray.append(attachment)
                                                
                                                if self.currentUser.email == self.currentEmail.from,
                                                    !attachment.openArray.isEmpty || !attachment.downloadArray.isEmpty,
                                                    let activity = self.activity,
                                                    activity.exists {
                                                    self.attachButton.tintColor = Icon.activated.color
                                                }
                                            }
                                        }
                                        
                                        if !self.attachmentArray.isEmpty && self.currentUser.email == self.currentEmail.from {
                                            self.attachButton.isHidden = false
                                        }
                                        
                                        self.tableViewHeightConstraint.constant = CGFloat(self.attachmentArray.count + self.attachmentGmailArray.count) * self.rowHeight
                                        self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.hideSnackbar()
    }
    
    @IBAction func didPressTrash(_ sender: UIBarButtonItem) {
        guard let service = self.currentService else {
            return
        }
        
        CriptextSpinner.show(in: self.view, title: nil, image: UIImage(named: "icon_sent_chat.png"))
        APIManager.trash(emails: [self.currentEmail.threadId], with: service) { (error, result) in
            if error != nil {
                self.showAlert("Network Error", message: "Please try again later", style: .alert)
                return
            }
            
            CriptextSpinner.hide(from: self.view)
            if self.selectedLabel == .inbox || self.selectedLabel == .junk {
                DBManager.update(self.currentEmail, labels: self.currentEmail.labels.filter{$0 != self.selectedLabel.id})
            }
            self.currentEmail.labels.append(Label.trash.id)
            DBManager.update(self.currentEmail, labels: self.currentEmail.labels)
            NotificationCenter.default.post(name: Notification.Name(rawValue:"EmailTrashed"), object: nil, userInfo:["email":self.currentEmail])
            self.navigationController?.popViewController(animated: true)
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func didPressReply(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Reply", style: .default) { action in
            self.replyMail()
        })
        
        if self.currentEmail.to.components(separatedBy: ",").count > 1 || !self.currentEmail.cc.isEmpty{
            alert.addAction(UIAlertAction(title: "Reply All", style: .default) { action in
                self.replyAllMail()
            })
        }
        
        alert.addAction(UIAlertAction(title: "Forward", style: .default) { action in
            self.forwardMail()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alert, animated: true, completion:nil)
    }
    
    @IBAction func didPressComposer(_ sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let composeVC = navComposeVC.childViewControllers.first as! ComposeViewController
        composeVC.currentService = self.currentService
        composeVC.currentUser = self.currentUser
        composeVC.replyingEmail = self.currentEmail
        
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        
        self.present(snackVC, animated: true, completion: nil)
    }
    
    @objc func didPressMark(_ sender: UIBarButtonItem){
        var title = "Read"
        if self.currentEmail.isRead() {
            title = "Unread"
        }
        
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        sheet.addAction(UIAlertAction(title: "Mark as \(title)" , style: .default) { (action) in
            
            var addLabels:[String]?
            var removeLabels:[String]?
            
            if self.currentEmail.isRead() {
                addLabels = [Label.unread.id]
            } else {
                removeLabels = [Label.unread.id]
            }
            
            self.showSnackbar("Marking mail as \(title)...", attributedText: nil, buttons: "", permanent: true)
            APIManager.messageModifyLabels(add: addLabels,
                                          remove: removeLabels,
                                          from: [self.currentEmail.id],
                                          with: self.currentService,
                                          user: "me",
                                          completionHandler: { (error, flag) in
                                            
                                            if error != nil {
                                                self.showAlert("Network Error", message: "Please try again later", style: .alert)
                                                self.hideSnackbar()
                                                return
                                            }
                                            
                                            self.showSnackbar("Mail marked as \(title)", attributedText: nil, buttons: "", permanent: false)
                                            
                                            if self.currentEmail.isRead() {
                                                DBManager.update(self.currentEmail, labels: Array(Set(self.currentEmail.labels + [Label.unread.id])))
                                            } else {
                                                DBManager.update(self.currentEmail, labels: self.currentEmail.labels.filter{$0 != Label.unread.id})
                                            }
                                            
//                                            let imagename = self.currentEmail.isRead() ? "mark_unread" : "mark_read"
//                                            let markButton = UIBarButtonItem(image: UIImage(named: imagename), style: .plain, target: self, action: #selector(self.didPressMark(_:)))
//                                            
//                                            self.navigationItem.rightBarButtonItems?.removeLast()
//                                            
//                                            self.navigationItem.rightBarButtonItems?.insert(markButton, at: 1)
                                            
                                            self.navigationController?.popViewController(animated: true)
                                            
                                            (UIApplication.shared.delegate as! AppDelegate).triggerRefresh()
            })
        })
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        sheet.popoverPresentationController?.sourceView = self.view
        sheet.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        
        self.present(sheet, animated: true, completion: nil)
    }
    
    @IBAction func didPressUnsend(_ sender: UIButton) {
        guard self.currentUser.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to unsend this email")
            return
        }
        CriptextSpinner.show(in: self.view, title: nil, image: UIImage(named: "icon_sent_chat.png"))
        APIManager.unsendMail(self.currentEmail.realCriptextToken, user: self.currentUser) { (error, string) in
            CriptextSpinner.hide(from: self.view)
            if(error == nil){
                self.showSnackbar("Mail unsent", attributedText: nil, buttons: "", permanent: false)
                DBManager.update(self.activity!, exist: false)
                let unsendString = Constants.unsendEmail
                self.webView.loadHTMLString(unsendString, baseURL: nil)
                self.unsendButton.isHidden = true
                self.lockButton.tintColor = UIColor.red
                self.attachButton.tintColor = UIColor.red
                self.timerButton.tintColor = UIColor.red
            }else{
                self.showAlert("Network Error", message: "Please try again later", style: .alert)
            }
        }
    }
    
    @IBAction func didPressAttachButton(_ sender: UIButton) {
        guard self.currentUser.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to view activity")
            return
        }
        
        let custom = AttachmentUIPopover()
        
        var height: CGFloat = 169.0
        if(self.attachmentArray.count > 2){
            height = 214.0
        }
        if(self.attachmentArray.count == 1){
            custom.setOneSectionAlwaysOpen(true)
        }
        else{
            custom.setOneSectionAlwaysOpen(false)
        }
        
//        custom.myMailToken = activity.token
        custom.setSectionArray(self.attachmentArray as! [AttachmentCriptext])
        custom.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: height)
        custom.popoverPresentationController?.sourceView = sender
        custom.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.bounds.width, height: sender.bounds.height)
        custom.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        custom.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(custom, animated: true, completion: nil)
    }
    
    @IBAction func didPressLockButton(_ sender: UIButton) {
        guard self.currentUser.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to view activity")
            return
        }
        
        guard let activity = self.activity else {
            return
        }
        
        let custom = OpenUIPopover()
        
        let openArray = self.activity?.openArray ?? []
        if(openArray.count == 0){
            self.presentGenericPopover("Your email has not been opened", image: Icon.not_open.image!, sourceView: sender)
            return
        }
        
        //LAST LOCATION INFORMATION
        let open:String = openArray[0]
        let location = open.components(separatedBy: ":")[0]
        let time = open.components(separatedBy: ":")[1]
        let date = Date(timeIntervalSince1970: Double(time)!)
        custom.lastDate = DateUtils.beatyDate(date)
        custom.lastLocation = location
        
        let dateSent = Date(timeIntervalSince1970: Double(activity.timestamp))
        custom.sentDate = DateUtils.conversationTime(dateSent)
        
        //OPENS ARRAY
        var opensList = [Open]()
        for open in openArray{
            let location = open.components(separatedBy: ":")[0]
            let time = open.components(separatedBy: ":")[1]
            opensList.append(Open(fromTimestamp: Double(time)!, fromLocation: location, fromType: 1))
        }
        custom.opensList = opensList
        custom.totalViews = String(opensList.count)
        custom.myMailToken = activity.token
        
        custom.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 188)
        custom.popoverPresentationController?.sourceView = sender
        
        custom.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.bounds.width, height: sender.bounds.height)
        custom.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        custom.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(custom, animated: true, completion: nil)
    }
    
    @IBAction func didPressTimerButton(_ sender: UIButton) {
        guard self.currentUser.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to view activity")
            return
        }
        
        guard let activity = self.activity else {
            return
        }
        
        if((activity.exists && !activity.isNew) || (activity.exists && activity.type == 3)){
            //OPENED
            var dateEnd: NSDate!
            if(activity.type == 3){
                //EXPIRATION ONSENT
                dateEnd = NSDate(timeIntervalSince1970: TimeInterval(activity.timestamp + activity.secondsSet))
            }
            else{
                //EXPIRATION ONOPEN
                let openArray = activity.openArray
                let open = openArray[0]
                let time = Double(open.components(separatedBy: ":")[1])
                dateEnd = NSDate(timeIntervalSince1970: TimeInterval(Int(time!) + activity.secondsSet))
            }
            let custom = TimerUIPopover()
            custom.dateEnd = dateEnd
            custom.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 122)
            custom.popoverPresentationController?.sourceView = sender
            custom.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.bounds.width, height: 80)
            custom.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            custom.popoverPresentationController?.backgroundColor = UIColor.white
            self.present(custom, animated: true, completion: nil)
        }
        else if(activity.exists && activity.isNew){
            //NOT OPENED
            self.presentGenericPopover("Timer will start once the email is opened by the recepient", image: Icon.not_timer.image!, sourceView: sender)
        }
        else{
            //EXPIRED, SHOW NOTHING
        }
    }
    
    @objc func didPressArchive() {
        
        self.showSnackbar("Archiving...", attributedText: nil, buttons: "", permanent: true)
        
        APIManager.messageModifyLabels(add: nil, remove: [self.selectedLabel.id], from: [self.currentEmail.id], with: self.currentService, user:"me") { (error, result) in
            
            if error != nil {
                self.showAlert("Network Error", message: "Please try again later", style: .alert)
                self.hideSnackbar()
                return
            }
            
            self.showSnackbar("Archived", attributedText: nil, buttons: "", permanent: false)
            
            DBManager.update(self.currentEmail, labels: self.currentEmail.labels.filter{$0 != self.selectedLabel.id})
            DBManager.update(self.currentEmail, labels: self.currentEmail.labels.filter{$0 != Label.unread.id })
            
            (UIApplication.shared.delegate as! AppDelegate).triggerRefresh()
        }
    }
    
    @objc func didPressMove() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        let moveVC = storyboard.instantiateViewController(withIdentifier: "MoveMailViewController") as! MoveMailViewController
        moveVC.selectedLabel = self.selectedLabel
        
        self.present(moveVC, animated: true, completion: nil)
    }
    
    func replyMail() -> Void {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let composeVC = navComposeVC.childViewControllers.first as! ComposeViewController
        composeVC.currentService = self.currentService
        composeVC.currentUser = self.currentUser
        composeVC.replyingEmail = self.currentEmail
        composeVC.loadViewIfNeeded()
        
        if self.currentEmail.from == self.currentUser.email {
            for email in self.currentEmail.to.components(separatedBy: ",") {
                composeVC.addToken(email, value: email, to: composeVC.toField)
            }
        } else {
            composeVC.addToken(self.currentEmail.from, value: self.currentEmail.from, to: composeVC.toField)
        }
        
        if !self.currentEmail.subject.lowercased().contains("re:") {
            composeVC.subjectField.text = "Re: "+self.currentEmail.subject
        } else {
            composeVC.subjectField.text = self.currentEmail.subject
        }
        
        let replyBody = ("<br><br><pre class=\"criptext-remove-this\"></pre>" + "On \(DateUtils.prettyDate(self.currentEmail.date!) ?? "some day"), \(self.currentEmail.from) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + self.currentEmail.body + "</blockquote>").replacingOccurrences(of: "https://mail.criptext.com/rs/", with: "https://mail.criptext.com/cache/")
        
        
        
        composeVC.editorView.html = "<br><br><br>" + self.currentUser.emailSignature + replyBody
        composeVC.replyBody = replyBody
        
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        
        self.present(snackVC, animated: true) {
            composeVC.editorView.focus(at: CGPoint(x: 0.0, y: 0.0))
        }
    }
    
    func replyAllMail() -> Void {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let composeVC = navComposeVC.childViewControllers.first as! ComposeViewController
        composeVC.currentService = self.currentService
        composeVC.currentUser = self.currentUser
        composeVC.replyingEmail = self.currentEmail
        composeVC.loadViewIfNeeded()
        
        for email in self.currentEmail.cc.components(separatedBy: ",") {
            if (!email.isEmpty && email.range(of: self.currentUser.email) == nil) {
                composeVC.addToken(email, value: email, to: composeVC.ccField)
            }
        }
        if self.currentEmail.from == self.currentUser.email {
            for email in self.currentEmail.to.components(separatedBy: ",") {
                composeVC.addToken(email, value: email, to: composeVC.toField)
            }
        } else {
            composeVC.addToken(self.currentEmail.from, value: self.currentEmail.from, to: composeVC.toField)
        }
        for email in self.currentEmail.to.components(separatedBy: ",") {
            if (email.range(of: self.currentUser.email) == nil) {
                if self.selectedLabel == .sent {
                    composeVC.addToken(email, value: email, to: composeVC.toField)
                }else{
                    composeVC.addToken(email, value: email, to: composeVC.ccField)
                }
            }
        }
        
        if !self.currentEmail.subject.lowercased().contains("re:") {
            composeVC.subjectField.text = "Re: "+self.currentEmail.subject
        } else {
            composeVC.subjectField.text = self.currentEmail.subject
        }
        
        let replyBody = ("<br><br><pre class=\"criptext-remove-this\"></pre>" + "On \(DateUtils.prettyDate(self.currentEmail.date!) ?? "some day"), \(self.currentEmail.from) wrote:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + self.currentEmail.body + "</blockquote>").replacingOccurrences(of: "https://mail.criptext.com/rs/", with: "https://mail.criptext.com/cache/")

        composeVC.editorView.html = "<br><br><br>" + self.currentUser.emailSignature + replyBody
        composeVC.replyBody = replyBody
        
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        
        self.present(snackVC, animated: true)  {
            composeVC.editorView.focus(at: CGPoint(x: 0.0, y: 0.0))
        }
    }
    
    func forwardMail() -> Void {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
        let composeVC = navComposeVC.childViewControllers.first as! ComposeViewController
        composeVC.currentService = self.currentService
        composeVC.currentUser = self.currentUser
        composeVC.replyingEmail = self.currentEmail
        let gmailAttachments = Array(self.currentEmail.attachments)
        composeVC.attachmentArray = self.attachmentArray + gmailAttachments
        composeVC.loadViewIfNeeded()
        
        if !self.currentEmail.subject.lowercased().contains("fwd:") {
            composeVC.subjectField.text = "Fwd: "+self.currentEmail.subject
        } else {
            composeVC.subjectField.text = self.currentEmail.subject
        }
        
        let replyBody = ("<br><br><pre class=\"criptext-remove-this\"></pre>Begin forwarded message:<br><blockquote class=\"gmail_quote\" style=\"margin:0 0 0 .8ex;border-left:1px #ccc solid;padding-left:1ex\">" + self.currentEmail.body + "</blockquote>").replacingOccurrences(of: "https://mail.criptext.com/rs/", with: "https://mail.criptext.com/cache/")

        composeVC.editorView.html = "<br><br><br>" + self.currentUser.emailSignature + replyBody
        composeVC.replyBody = replyBody
        
        let snackVC = SnackbarController(rootViewController: navComposeVC)
        
        self.present(snackVC, animated: true)  {
            composeVC.download(gmailAttachments, mail: self.currentEmail)
            composeVC.editorView.focus(at: CGPoint(x: 0.0, y: 0.0))
        }
    }
}

extension DetailViewController: UIWebViewDelegate {
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if let url = request.url, url.scheme == "inapp", url.host == "heightUpdate" {
            print("trigger cosita")
            if self.webViewHeightConstraint.constant != self.webViewCollapsedHeight {
                self.webViewHeightConstraint.constant = self.webViewCollapsedHeight
            } else {
                let size = CGFloat((webView.stringByEvaluatingJavaScript(from: "document.body.offsetHeight;")! as NSString).doubleValue)
                self.webViewHeightConstraint.constant = size
            }
            
        }
        if navigationType == UIWebViewNavigationType.linkClicked {
            UIApplication.shared.open(request.url!, options: [:], completionHandler: nil)
            return false
        }
        return true
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
//        if self.shouldReloadWebView {
//            let result2 = self.webView.stringByEvaluatingJavaScript(from: "urlify()")!
//            self.webView.loadHTMLString(result2, baseURL: nil)
//            self.shouldReloadWebView = false
//            return
//        }
//        self.webView.stringByEvaluatingJavaScript(from: "document.body.")
        let cidImagesString = self.webView.stringByEvaluatingJavaScript(from: "findCIDImageURL()")!
        let data = cidImagesString.data(using: .utf8)
        
        do {
            if let arrayImgs = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String] {
                
                let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
                
                for imgUrl in arrayImgs {
                    
                    guard let attachment = self.attachmentGmailArray.first(where: { (attachment) -> Bool in
                        return imgUrl.contains(attachment.contentId)
                    }) else {
                        continue
                    }
                    
                    let filePath = documentsPath + "/" + self.currentEmail.id + attachment.fileName
                    let fileURL = URL(fileURLWithPath: filePath)
                    
                    self.download(attachment, to:fileURL, completionHandler: { data in
                        guard let _ = data else {
                            return
                        }
                        
                        let args = "{\"URLKey\":\"\(imgUrl)\", \"LocalPathKey\":\"\(fileURL.absoluteString)\"}"
                        self.webView.stringByEvaluatingJavaScript(from: "replaceImageSrc(\(args))")
                        
                        if let index = self.attachmentGmailArray.index(of: attachment) {
                            self.attachmentGmailArray.remove(at: index)
                            self.tableView.reloadData()
                        }
                    })
                }
            }
            
            
        } catch {
            print("derpo")
        }
        
        
        
        let size = CGFloat((self.webView.stringByEvaluatingJavaScript(from: "document.body.offsetHeight;")! as NSString).doubleValue)
        self.webViewCollapsedHeight = size
        self.webViewHeightConstraint.constant = size
        
        self.tableView.reloadData()
        
        CriptextSpinner.hide(from: self.view)
        self.hideSnackbar()
    }
}

//MARK: - TableView Data Source
extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AttachmentTableViewCell", for: indexPath) as! AttachmentTableViewCell
        
        let attachment:Attachment!
        
        if indexPath.row <= (self.attachmentGmailArray.count - 1) {
            attachment = self.attachmentGmailArray[indexPath.row]
            cell.lockImageView.isHidden = true
        }else{
            attachment = self.attachmentArray[indexPath.row - self.attachmentGmailArray.count]
            cell.lockImageView.isHidden = false
            cell.lockImageView.tintColor = Icon.activated.color
            
            if let activity = self.activity, !activity.exists {
                cell.lockImageView.tintColor = UIColor.red
            }
        }
        
        cell.delegate = self
        cell.nameLabel.text = attachment.fileName
        cell.sizeLabel.text = attachment.filesize
        
        //image icon
        var imageIcon:UIImage!
        switch attachment.mimeType {
        case "application/pdf":
            imageIcon = Icon.attachment.pdf.image
            break
        case _ where attachment.mimeType.contains("application/msword") ||
            attachment.mimeType.contains("application/vnd.openxmlformats-officedocument.wordprocessingml") ||
            attachment.mimeType.contains("application/vnd.ms-word"):
            imageIcon = Icon.attachment.word.image
            break
        case "image/png", "image/jpeg":
            imageIcon = Icon.attachment.image.image
            break
        case _ where attachment.mimeType.contains("application/vnd.ms-powerpoint") ||
            attachment.mimeType.contains("application/vnd.openxmlformats-officedocument.presentationml"):
            imageIcon = Icon.attachment.ppt.image
            break
        case _ where attachment.mimeType.contains("application/vnd.ms-excel") ||
            attachment.mimeType.contains("application/vnd.openxmlformats-officedocument.spreadsheetml"):
            imageIcon = Icon.attachment.excel.image
            break
        default:
            imageIcon = Icon.attachment.generic.image
        }
        
        cell.typeImageView.image = imageIcon
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.attachmentArray.count + self.attachmentGmailArray.count
    }
}
//MARK: - TableView Delegate
extension DetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.rowHeight
    }
}

extension DetailViewController: AttachmentTableViewCellDelegate {
    func tableViewCellDidTapPassword(_ cell: AttachmentTableViewCell) {
    }
    
    func tableViewCellDidTapReadOnly(_ cell: AttachmentTableViewCell) {
    }
    
    func tableViewCellDidLongPress(_ cell: AttachmentTableViewCell) {
    }
    
    func tableViewCellDidTap(_ cell: AttachmentTableViewCell) {
        
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        
        var attachment:Attachment!
        if indexPath.row <= (self.attachmentGmailArray.count - 1) {
            //use currentemail attachments (Gmail)
            let gmail = self.attachmentGmailArray[indexPath.row]
            
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
            
            let filePath = documentsPath + "/" + self.currentEmail.id + gmail.fileName
            let fileURL = URL(fileURLWithPath: filePath)
            
            self.showSnackbar("Downloading attachment...", attributedText: nil, buttons: "", permanent: true)
            self.download(gmail, to:fileURL, completionHandler: { data in
                self.hideSnackbar()
                guard let _ = data else {
                    //show error
                    self.showAlert("Network Error", message: "Please retry opening the attachment later", style: .alert)
                    return
                }
                
                //show the file
                self.previewItem.previewItemURL = fileURL
                self.previewItem.previewItemTitle = gmail.fileName
                self.previewController.reloadData()
                self.present(self.previewController, animated: true, completion: nil)
            })
        }else{
            
            //use attachmentArray (Criptext)
            attachment = self.attachmentArray[indexPath.row - self.attachmentGmailArray.count]
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            let attachmentVC = storyboard.instantiateViewController(withIdentifier: "AttachmentViewController") as! AttachmentViewController
            attachmentVC.currentAttachment = attachment
            let snackVC = SnackbarController(rootViewController: attachmentVC)
            
            self.present(snackVC, animated: true, completion: nil)
        }
    }
    
    func download(_ attachment:AttachmentGmail, to fileURL:URL, completionHandler handler:@escaping ((Data?) -> ())){
        let filePath = fileURL.path
        
        if FileManager.default.fileExists(atPath: filePath) {
            //show the file
            handler(FileManager.default.contents(atPath: filePath))
            return
        }
        
        guard let service = self.currentService else {
            //TODO: alert user
            handler(nil)
            return
        }
        
        APIManager.download(attachment: attachment.attachmentId, for: self.currentEmail.id, with: service, user: "me", completionHandler: { (error, data) in
            guard let attachmentData = data else {
                //show error
                handler(nil)
                return
            }
            
            do {
                try attachmentData.write(to: fileURL)
            } catch {
                //show error
                handler(nil)
                return
            }
            
            handler(attachmentData)
        })
    }
}

extension DetailViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem
    }
}
