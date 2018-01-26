//
//  ActivityViewController.swift
//  Criptext Secure Email
//
//  Created by Daniel Tigse on 4/6/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift
import SwiftyJSON

class ActivityViewController: UITableViewController{
    
    @IBOutlet weak var statusBarButton:UIBarButtonItem!
    
    var activities: [Activity]!
    var attachments: [String:[AttachmentCriptext]]!
    var user:User!
    var emailsUnsending = [String]()
    var gettingActivities: Bool = false
    var reachEnd: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activities = DBManager.getArrayActivities()
        attachments = DBManager.getAllAttachments()
        print("tiene %d actividades",activities.count)
        print("tiene %d attachments",attachments.count)
        
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: UIControlEvents.valueChanged)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onWebSocketMessage(_:)), name: NSNotification.Name.Activity.onNewMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWebSocketMessage(_:)), name: NSNotification.Name.Activity.onNewAttachment, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWebSocketMessage(_:)), name: NSNotification.Name.Activity.onMsgNotificationChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWebSocketMessage(_:)), name: NSNotification.Name.Activity.onFileNotificationChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWebSocketMessage(_:)), name: NSNotification.Name.Activity.onEmailMute, object: nil)
        
        let defaults = UserDefaults.standard
        let lastSync = defaults.integer(forKey: "lastSync")
        let rightNow = Int(NSDate().timeIntervalSince1970)
        if(lastSync > 0 && (rightNow - lastSync) > 60){
            let date = Date(timeIntervalSince1970: Double(defaults.integer(forKey: "lastSync")))
            statusBarButton.title = String(format:"Updated %@",DateUtils.beatyDate(date))
        }
        
        let font:UIFont = Font.regular.size(13)!
        let attributes:[String : Any] = [NSFontAttributeName: font];
        statusBarButton.setTitleTextAttributes(attributes, for: .normal)
        
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        DBManager.update(self.user, badge: 0)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.Activity.onNewMessage, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.Activity.onNewAttachment, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.Activity.onMsgNotificationChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.Activity.onFileNotificationChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.Activity.onEmailMute, object: nil)
        self.markAllAsRead()
    }

    func markAllAsRead(){
        for activity in self.activities {
            DBManager.update(activity, hasOpens: false)
        }
    }

    @IBAction func didPressBack(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.markAllAsRead()
        self.activities.removeAll()
        self.tableView.reloadData()
        self.getMoreActivities(manual: true)
    }
    
    func onWebSocketMessage(_ notification : Notification) {
        
        guard let userInfo = notification.userInfo else{
                print("No userInfo found in notification")
                return
        }
        
        switch notification.name {
        case Notification.Name.Activity.onMsgNotificationChange:
            let token = userInfo["token"] as! String
            var index = 0
            for activity in self.activities{
                if(activity.token == token){
                    let newActivity = DBManager.getActivityBy(token)
                    if(newActivity != nil){
                        newActivity!.openArray = JSON(parseJSON: newActivity!.openArraySerialized).arrayValue.map({$0.stringValue})
                        var opensList = [Open]()
                        for open in newActivity!.openArray{
                            let location = open.components(separatedBy: ":")[0]
                            let time = open.components(separatedBy: ":")[1]
                            opensList.append(Open(fromTimestamp: Double(time)!, fromLocation: location, fromType: 1))
                        }
                        newActivity!.openArrayObjects = opensList
                        self.activities[index] = newActivity!
                    }
                    
                    self.activities.remove(at: index)
                    self.activities.insert(newActivity!, at: 0)
                    self.tableView.reloadData()
                    break
                }
                index += 1
            }
        case Notification.Name.Activity.onFileNotificationChange:
            let fileToken = userInfo["fileToken"] as! String
            let mailToken = userInfo["mailToken"] as! String
            let attachments = self.attachments[mailToken]
            if(attachments != nil){
                for attachment in attachments!{
                    if(attachment.fileToken == fileToken){
                        let newAttachment = DBManager.getAttachmentBy(fileToken)
                        if(newAttachment != nil){
                            attachment.openArray = JSON(parseJSON: newAttachment!.openArraySerialized).arrayValue.map({$0.stringValue})
                            attachment.downloadArray = JSON(parseJSON: newAttachment!.downloadArraySerialized).arrayValue.map({$0.stringValue})
                            break
                        }
                    }
                }
                self.reloadRowWith(mailToken)
            }
        case Notification.Name.Activity.onNewMessage:
            let newActivity = userInfo["activity"] as! Activity
            if(newActivity.token != ""){
                self.activities.insert(newActivity, at: 0)
            }
            self.tableView.reloadData()
            
        case Notification.Name.Activity.onNewAttachment:
            let token = userInfo["token"] as! String
            self.attachments[token] = userInfo["attachments"] as? [AttachmentCriptext]
            self.reloadRowWith(token)
            
        case Notification.Name.Activity.onEmailMute:
            
            let tokens = userInfo["tokens"] as! String
            
            let tokenArray = tokens.components(separatedBy: ",")
            
            for token in tokenArray {
                guard let activity = self.activities.first(where: { (activity) -> Bool in
                    return activity.token == token
                }), let index = self.activities.index(of: activity) else { continue }
                
                let newActivity = DBManager.getActivityBy(token)
                if(newActivity != nil){
                    newActivity!.openArray = JSON(parseJSON: newActivity!.openArraySerialized).arrayValue.map({$0.stringValue})
                    var opensList = [Open]()
                    for open in newActivity!.openArray{
                        let location = open.components(separatedBy: ":")[0]
                        let time = open.components(separatedBy: ":")[1]
                        opensList.append(Open(fromTimestamp: Double(time)!, fromLocation: location, fromType: 1))
                    }
                    newActivity!.openArrayObjects = opensList
                    self.activities[index] = newActivity!
                }
                
                self.activities.remove(at: index)
                self.activities.insert(newActivity!, at: index)
                self.tableView.reloadData()
            }
            
            break
        default:
            print("default")
        }
        
    }
    
    func reloadRowWith(_ token:String){
        
        var index = 0
        for activity in self.activities{
            if(activity.token == token){
                let indexPath = IndexPath(item: index, section: 0)
                self.tableView.reloadRows(at: [indexPath], with: UITableViewRowAnimation.fade)
                break
            }
            index += 1
        }
    }
}

extension ActivityViewController {
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityTableViewCell", for: indexPath) as! ActivityTableViewCell
        cell.buttonUnsend.tintColor = UIColor(red:0.85, green:0.29, blue:0.22, alpha:1.0)
        
        let activity = self.activities[indexPath.row]
        
        let dateSent = Date(timeIntervalSince1970: Double(activity.timestamp))
        cell.noActivityDescriptionLabel.text = DateUtils.conversationTime(dateSent)
        
        cell.locationLabel.isHidden = false
        cell.openedLabel.isHidden = false
        cell.dateLabel.isHidden = false
        cell.locationImageView.isHidden = false
        cell.noActivityTitleLabel.isHidden = true
        cell.noActivityDescriptionLabel.isHidden = true
        cell.muteImageView.tintColor = Icon.enabled.color
        cell.timerView.isHidden = true
        cell.attachmentView.isHidden = true
        
        if activity.isMuted {
            cell.muteImageView.image = #imageLiteral(resourceName: "muted")
        } else {
            cell.muteImageView.image = #imageLiteral(resourceName: "unmuted")
        }
        
        if(activity.exists){
            cell.noActivityTitleLabel.text = "Sent"
            cell.noActivityTitleLabel.textColor = UIColor.gray
            
            if(activity.isNew){
                //DELIVERED
                cell.lockImageView.tintColor = UIColor.gray
                cell.timerImageView.tintColor = UIColor.gray
            }
            else{
                //OPEN
                cell.lockImageView.tintColor = UIColor.init(colorLiteralRed: 0, green: 145/255, blue: 255/255, alpha: 1)
                cell.timerImageView.tintColor = UIColor.init(colorLiteralRed: 0, green: 145/255, blue: 255/255, alpha: 1)
            }
            
            cell.toLabel.textColor = UIColor.black
            cell.subjectLabel.textColor = UIColor.init(colorLiteralRed: 114/244, green: 114/255, blue: 114/255, alpha: 1)
            cell.buttonUnsend.setImage(Icon.btn_unsend.image, for: .normal)
            cell.buttonUnsend.isEnabled = true
            cell.buttonUnsend.isHidden = false
            
//            cell.noActivityTitleLabel.textColor = UIColor.init(colorLiteralRed: 0, green: 145/255, blue: 255/255, alpha: 1)
            cell.noActivityTitleWidthConstraint.constant = 35
        }
        
        if !self.user.isPro() {
            cell.lockImageView.tintColor = activity.exists ? UIColor.gray : UIColor.red
            cell.timerImageView.tintColor = activity.exists ? UIColor.gray : UIColor.red
            cell.buttonUnsend.tintColor = UIColor.gray
        }
        
        if(activity.secondsSet > 0){
            //INFORMATION ABOUT EXPIRATION
//            cell.timerView.opacity = 1
            cell.timerView.isHidden = false
            //IF I GOT EXPIRATION AND NOT ATTACHMENTS
            cell.attachmentView.isHidden = self.attachments[activity.token] == nil
        }
        else{
//            cell.timerView.opacity = 0
            cell.timerView.isHidden = true
        }
        
        //OPENS INFORMATION
        let openArray = JSON(parseJSON: activity.openArraySerialized).arrayValue.map({$0.stringValue})
        if openArray.count > 0 && self.user.isPro() {
            
            let open:String = openArray[0]
            let location = open.components(separatedBy: ":")[0]
            let time = open.components(separatedBy: ":")[1]
            
            let date = Date(timeIntervalSince1970: Double(time)!)
            
            cell.dateLabel.text = DateUtils.conversationTime(date)
            cell.locationLabel.text = location
            
            cell.openedLabel.isHidden = false
            cell.dateLabel.isHidden = false
            cell.locationLabel.isHidden = false
            cell.locationImageView.isHidden = false
            cell.noActivityTitleLabel.isHidden = true
            cell.noActivityDescriptionLabel.isHidden = true
        }
        else{
            cell.openedLabel.isHidden = true
            cell.dateLabel.isHidden = true
            cell.locationLabel.isHidden = true
            cell.locationImageView.isHidden = true
            cell.noActivityTitleLabel.isHidden = false
            cell.noActivityDescriptionLabel.isHidden = false
        }
        
        //OTHER INFORMATION
        cell.toLabel.text = activity.toDisplayString.isEmpty ? activity.to : activity.toDisplayString
        
        if activity.subject.isEmpty {
            cell.subjectLabel.text = "(No Subject)"
        } else {
            cell.subjectLabel.text = activity.subject
        }
        
        
        cell.delegate = self
        
        //ATTACHMENTS
        if(self.attachments[activity.token] != nil){
//            cell.attachmentView.opacity = 1
            cell.attachmentView.isHidden = false
            let tempAttacments = self.attachments[activity.token]!
            var total = 0
            for attachment in tempAttacments{
                total = total + attachment.openArray.count + attachment.downloadArray.count
            }
            
            if(total > 0 && activity.exists && self.user.isPro()){
                cell.attachmentImageView.tintColor = UIColor.init(colorLiteralRed: 0, green: 145/255, blue: 255/255, alpha: 1)
            }
            else if(activity.exists){
                cell.attachmentImageView.tintColor = UIColor.gray
            }
            //cell.attachmentImageView.tintColor = UIColor.gray
            //IF I GOT ATTACHMENTS AND NOT EXPIRATION
            cell.timerView.isHidden = activity.secondsSet == 0
        }
        else{
            cell.attachmentView.isHidden = true
//            cell.attachmentView.opacity = 0
        }
        
        //UNSENDING
        if(emailsUnsending.contains(activity.token)){
            cell.unsendView.isHidden = false
            cell.indicator.startAnimating()
        }
        else{
            cell.unsendView.isHidden = true
            cell.indicator.stopAnimating()
        }
        
        //HAS OPENS
        if(activity.hasOpens){
            cell.containerView.backgroundColor = UIColor(red:0.96, green:0.98, blue:1.00, alpha:1.0)
            cell.toLabel.font = Font.bold.size(cell.toLabel.font.pointSize)
            cell.subjectLabel.font = Font.bold.size(cell.subjectLabel.font.pointSize)
        }
        else{
            cell.containerView.backgroundColor = UIColor.white
            cell.toLabel.font = Font.regular.size(cell.toLabel.font.pointSize)
            cell.subjectLabel.font = Font.regular.size(cell.subjectLabel.font.pointSize)
        }
        
        
        if(!activity.exists){
            //UNSENT
            cell.lockImageView.tintColor = UIColor.red
            cell.timerImageView.tintColor = UIColor.red
            cell.attachmentImageView.tintColor = UIColor.red
            cell.buttonUnsend.setImage(Icon.btn_unsent.image, for: .normal)
            cell.buttonUnsend.isEnabled = false
            cell.buttonUnsend.isHidden = true
            
            cell.noActivityTitleLabel.text = "Unsent"
            cell.noActivityTitleLabel.textColor = UIColor.red
            cell.noActivityTitleWidthConstraint.constant = 53
            
            cell.locationLabel.isHidden = true
            cell.openedLabel.isHidden = true
            cell.dateLabel.isHidden = true
            cell.locationImageView.isHidden = true
            cell.noActivityTitleLabel.isHidden = false
            cell.noActivityDescriptionLabel.isHidden = false
            
            var recallTime = activity.recallTime
            if recallTime == 0 {
                recallTime = activity.timestamp + activity.secondsSet
            }
            let dateUnsent = Date(timeIntervalSince1970: Double(recallTime))
            cell.noActivityDescriptionLabel.text = DateUtils.conversationTime(dateUnsent)
        }
        
        //USER IS BASIC
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.activities.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110.0
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        //let activity = self.activities[indexPath.row]
        //if(!activity.exists){
            //return false
        //}
        return false
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let unsendAction = UITableViewRowAction(style: UITableViewRowActionStyle.normal, title: "              ") { (action, index) in
            
            let activity = self.activities[index.row]
            let cell = tableView.cellForRow(at: index) as! ActivityTableViewCell
            cell.unsendView.isHidden = false
            cell.indicator.startAnimating()
            self.emailsUnsending.append(activity.token)
            tableView.setEditing(false, animated: true)
            
            APIManager.unsendMail(activity.token, user: self.user, completion: { (error, string) in
                
                if(error != nil){
                    cell.unsendView.isHidden = true
                    self.emailsUnsending.remove(at: self.emailsUnsending.index(of: activity.token)!)
                    tableView.reloadRows(at: [index], with: UITableViewRowAnimation.fade)
                }
                else{
                    cell.unsendLabel.text = "Email Succesfully Unsent \u{2713}"
                    cell.indicator.stopAnimating()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        cell.unsendView.isHidden = true
                        DBManager.update(activity, exist: false)
                        self.emailsUnsending.remove(at: self.emailsUnsending.index(of: activity.token)!)
                        tableView.reloadRows(at: [index], with: UITableViewRowAnimation.fade)
                    }
                }
                
            })
            
        }
        unsendAction.backgroundColor = UIColor(patternImage: UIImage(named: "unsend-label")!)
        return [unsendAction];
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard let lastEmail = self.activities.last else {
            return
        }
        
        if(self.gettingActivities || self.reachEnd){
            return
        }
        
        let email = self.activities[indexPath.row]
        
        if email == lastEmail {
            self.gettingActivities = true
            tableView.reloadData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.getMoreActivities(manual: false)
            }
        }
    }
    
    override func tableView( _ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?{
        
        let footerView = UIView(frame: CGRect(x:0, y:0, width:tableView.frame.size.width, height:50))
        let indicator = UIActivityIndicatorView(frame: CGRect.init(x: (tableView.frame.size.width/2)-25, y: 0, width: 50, height: 50))
        indicator.color = .black
        indicator.activityIndicatorViewStyle = .gray
        indicator.startAnimating()
        
        let labelReachEnd = UILabel(frame: CGRect.init(x: (tableView.frame.size.width/2)-50, y: 0, width: 100, height: 50))
        labelReachEnd.textColor = UIColor.darkGray
        labelReachEnd.text = "No more emails"
        
        if(self.reachEnd){
            footerView.addSubview(labelReachEnd)
        }
        else{
            footerView.addSubview(indicator)
        }
        
        footerView.backgroundColor = UIColor.white
        return footerView
    }
    
    override func tableView( _ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat{
        if(self.gettingActivities){
            return 50.0
        }
        else{
            return 0.0
        }
    }
    
    func getMoreActivities(manual:Bool){
        
        APIManager.getActivityPanel(self.user, since: self.activities.count, count: "100") { (error, tupleResponse) in
            
            if let error = error {
                print(error)
                return
            }
            
            if manual {
                self.showSnackbar("Updated just now", attributedText: nil, buttons: "", permanent: false)
            }
            
            if(tupleResponse?.0.count == 0 && tupleResponse?.1.count == 0){
                self.reachEnd = true
            }
            
            if let activityArray = tupleResponse?.0 {
                DBManager.store(activityArray)
                
                if self.activities.count == 0 {
                    self.activities = DBManager.getArrayActivities()
                }else{
                    for activity in activityArray{
                        activity.openArray = JSON(parseJSON: activity.openArraySerialized).arrayValue.map({$0.stringValue})
                        var opensList = [Open]()
                        for open in activity.openArray{
                            let location = open.components(separatedBy: ":")[0]
                            let time = open.components(separatedBy: ":")[1]
                            opensList.append(Open(fromTimestamp: Double(time)!, fromLocation: location, fromType: 1))
                        }
                        activity.openArrayObjects = opensList
                        self.activities.append(activity)
                    }
                }
                self.sortActivities()
            }
            
            if let attachmentArray = tupleResponse?.1 {
                DBManager.store(attachmentArray)
                self.attachments = DBManager.getAllAttachments()
            }
            
            self.gettingActivities = false
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
            
            let defaults = UserDefaults.standard
            defaults.set(Int(NSDate().timeIntervalSince1970), forKey: "lastSync")
            self.statusBarButton.title = "Updated Just Now"
        }
    }
    
    func sortActivities(){
        
        self.activities = self.activities.sorted(by: { (activity1, activity2) -> Bool in
            
            if(activity1.openArrayObjects.count > 0 && activity2.openArrayObjects.count > 0){
                return Int((activity1.openArrayObjects.first?.timestamp)!) > Int((activity2.openArrayObjects.first?.timestamp)!)
            }
            else if(activity1.openArrayObjects.count > 0 && activity2.openArrayObjects.count == 0){
                return Int((activity1.openArrayObjects.first?.timestamp)!) > activity2.timestamp
            }
            else if(activity1.openArrayObjects.count == 0 && activity2.openArrayObjects.count > 0){
                return activity1.timestamp > Int((activity2.openArrayObjects.first?.timestamp)!)
            }
            
            return activity1.timestamp > activity2.timestamp
        })
    }
}

extension ActivityViewController: ActivityTableViewCellDelegate{
    
    func restoreCellToRead(_ cell:ActivityTableViewCell){
        cell.containerView.backgroundColor = UIColor.white
        cell.toLabel.font = Font.regular.size(cell.toLabel.font.pointSize)
        cell.subjectLabel.font = Font.regular.size(cell.subjectLabel.font.pointSize)
    }
    
    func tableViewCellDidTapTimer(_ cell:ActivityTableViewCell){
        
        guard self.user.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to view activity")
            return
        }
        
        let indexPath = self.tableView.indexPath(for: cell)
        let activity = activities[indexPath!.row]
        DBManager.update(activity, hasOpens: false)
        self.restoreCellToRead(cell)
        
        if((activity.exists && !activity.isNew) || (activity.exists && activity.type == 3)){
            //OPENED
            var dateEnd: NSDate!
            if(activity.type == 3){
                //EXPIRATION ONSENT
                dateEnd = NSDate(timeIntervalSince1970: TimeInterval(activity.timestamp + activity.secondsSet))
            }
            else{
                //EXPIRATION ONOPEN
                let openArray = JSON(parseJSON: activity.openArraySerialized).arrayValue.map({$0.stringValue})
                let open = openArray[0]
                let time = Double(open.components(separatedBy: ":")[1])
                dateEnd = NSDate(timeIntervalSince1970: TimeInterval(Int(time!) + activity.secondsSet))
            }
            let custom = TimerUIPopover()
            custom.dateEnd = dateEnd
            custom.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 122)
            custom.popoverPresentationController?.sourceView = cell.timerView
            custom.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: cell.timerView.frame.size.width, height: cell.lockView.frame.size.height)
            custom.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            custom.popoverPresentationController?.backgroundColor = UIColor.white
            self.present(custom, animated: true, completion: nil)
        }
        else if(activity.exists && activity.isNew){
            //NOT OPENED
            self.presentGenericPopover("Timer will start once the email is opened by the recepient", image: Icon.not_timer.image!, sourceView: cell.timerView)
        }
        else{
            //EXPIRED, SHOW NOTHING
        }
    }
    
    func tableViewCellDidTapAttachment(_ cell:ActivityTableViewCell){
        
        guard self.user.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to view activity")
            return
        }
        
        let custom = AttachmentUIPopover()
        
        let indexPath = self.tableView.indexPath(for: cell)
        let activity = activities[indexPath!.row]
        let attachments = self.attachments[activity.token]
        DBManager.update(activity, hasOpens: false)
        self.restoreCellToRead(cell)
        
        if(attachments == nil){
            return
        }
        
        var height: CGFloat = 168.0
        if(attachments!.count > 2){
            height = 234.0
        }
        if(attachments!.count == 1){
            custom.setOneSectionAlwaysOpen(true)
        }
        else{
            custom.setOneSectionAlwaysOpen(false)
        }
        custom.myMailToken = activity.token
        custom.setSectionArray(attachments!)
        custom.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: height)
        custom.popoverPresentationController?.sourceView = cell.attachmentView
        custom.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: cell.attachmentView.frame.size.width, height: cell.lockView.frame.size.height)
        custom.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        custom.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(custom, animated: true, completion: nil)
    }
    
    func tableViewCellDidTapLock(_ cell:ActivityTableViewCell){
        
        guard self.user.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to view activity")
            return
        }
        
        let custom = OpenUIPopover()
        
        let indexPath = self.tableView.indexPath(for: cell)
        let activity = activities[indexPath!.row]
        DBManager.update(activity, hasOpens: false)
        self.restoreCellToRead(cell)
        
        let openArray = JSON(parseJSON: activity.openArraySerialized).arrayValue.map({$0.stringValue})
        if(openArray.count == 0){
            self.presentGenericPopover("Your email has not been opened", image: Icon.not_open.image!, sourceView: cell.lockView)
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
        custom.popoverPresentationController?.sourceView = cell.lockView
        custom.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: cell.lockView.frame.size.width, height: cell.lockView.frame.size.height)
        custom.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        custom.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(custom, animated: true, completion: nil)
    }
    
    func tableViewCellDidTapUnsend(_ cell:ActivityTableViewCell){
        
        guard self.user.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to unsend your emails")
            return
        }
        
        let indexPath = self.tableView.indexPath(for: cell)
        let activity = activities[indexPath!.row]
        cell.unsendView.isHidden = false
        cell.indicator.startAnimating()
        self.emailsUnsending.append(activity.token)
        
        APIManager.unsendMail(activity.token, user: self.user, completion: { (error, string) in
            
            if(error != nil){
                cell.unsendView.isHidden = true
                self.emailsUnsending.remove(at: self.emailsUnsending.index(of: activity.token)!)
                self.tableView.reloadRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
            }
            else{
                cell.unsendLabel.text = "Email Succesfully Unsent \u{2713}"
                cell.indicator.stopAnimating()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    cell.unsendView.isHidden = true
                    let recallTime = Int(Date().timeIntervalSince1970)
                    DBManager.update(activity, recallTime: recallTime)
                    DBManager.update(activity, exist: false)
                    self.emailsUnsending.remove(at: self.emailsUnsending.index(of: activity.token)!)
                    self.tableView.reloadRows(at: [indexPath!], with: UITableViewRowAnimation.fade)
                }
            }
            
        })
    }
    
    func tableViewCellDidTapMute(_ cell: ActivityTableViewCell) {
        
        guard self.user.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to unsend your emails")
            return
        }
        
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        let activity = activities[indexPath.row]
        
        var finalImage:UIImage!
        
        if activity.isMuted {
            finalImage = #imageLiteral(resourceName: "unmuted")
        } else {
            finalImage = #imageLiteral(resourceName: "muted")
        }
        
        cell.muteImageView.image = finalImage
        
        APIManager.muteActivity(self.user, tokens: [activity.token], shouldMute: !activity.isMuted) { (error, flag) in
            if let _ = error {
                self.showSnackbar("Network connection error, please try again later", attributedText: nil, buttons: "", permanent: false)
                self.tableView.reloadRows(at: [indexPath], with: .none)
                return
            }
            
            DBManager.update(activity, isMuted: !activity.isMuted)
        }
        
    }
    
}
