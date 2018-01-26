//
//  ThreadViewController.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/24/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import GoogleAPIClientForREST
import SwiftyJSON
import Material

class ThreadViewController: UITableViewController {
    var emailArray = [Email]()
    
    var currentUser:User!
    var currentService: GTLRService!
    var selectedLabel:Label!
    var attachmentHash = [String:[AttachmentCriptext]]()
    var activities = [String:Activity]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //replicate toolbar items
        let vc = self.navigationController?.viewControllers[0]
        self.toolbarItems = vc?.toolbarItems
        self.tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        guard let indexPath = self.tableView.indexPathForSelectedRow else {
            return
        }
        
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
}

extension ThreadViewController: InboxTableViewCellDelegate {
    func tableViewCellDidLongPress(_ cell: InboxTableViewCell) {
    }
    
    func tableViewCellDidTapLock(_ cell: InboxTableViewCell) {
        
        guard self.currentUser.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to view activity")
            return
        }
        
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        
        let email = self.emailArray[indexPath.row]
        
        guard let activity = self.activities[email.realCriptextToken] else {
            return
        }
        
        let custom = OpenUIPopover()
        
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
    
    func tableViewCellDidTapTimer(_ cell: InboxTableViewCell) {
        
        guard self.currentUser.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to view activity")
            return
        }
        
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        
        let email = self.emailArray[indexPath.row]
        
        guard let activity = self.activities[email.realCriptextToken] else {
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
    
    func tableViewCellDidTapAttachment(_ cell: InboxTableViewCell) {
        
        guard self.currentUser.isPro() else {
            self.showProAlert(nil, message: "Upgrade to Pro to view activity")
            return
        }
        
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        
        let email = self.emailArray[indexPath.row]
        
        guard let activity = self.activities[email.realCriptextToken],
            let attachments = self.attachmentHash[activity.token] else {
                return
        }
        
        let custom = AttachmentUIPopover()
        
        var height: CGFloat = 168.0
        if(attachments.count > 2){
            height = 234.0
        }
        if(attachments.count == 1){
            custom.setOneSectionAlwaysOpen(true)
        }
        else{
            custom.setOneSectionAlwaysOpen(false)
        }
        
        custom.myMailToken = activity.token
        custom.setSectionArray(attachments)
        custom.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: height)
        custom.popoverPresentationController?.sourceView = cell.secureAttachmentView
        custom.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: cell.secureAttachmentView.frame.size.width, height: cell.lockView.frame.size.height)
        custom.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        custom.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(custom, animated: true, completion: nil)
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
}

extension ThreadViewController {
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "InboxTableViewCell", for: indexPath) as! InboxTableViewCell
        cell.delegate = self
        
        let email = self.emailArray[indexPath.row]
        
        let isSentFolder = self.selectedLabel == .sent
        
        //Set colors to initial state
        cell.senderLabel.textColor = UIColor.black
        cell.subjectLabel.textColor = UIColor(red:0.37, green:0.37, blue:0.37, alpha:1.0)
        cell.lockImageView.tintColor = Icon.system.color
        cell.timerImageView.tintColor = Icon.system.color
        cell.secureAttachmentImageView.tintColor = Icon.disabled.color
        
        cell.containerBadge.isHidden = true
        
        //Set row status
        if email.isRead() || isSentFolder {
            cell.backgroundColor = UIColor.white
            cell.senderLabel.font = Font.regular.size(17)
            cell.subjectLabel.font = Font.regular.size(17)
        }else{
            cell.backgroundColor = UIColor(red:0.96, green:0.98, blue:1.00, alpha:1.0)
            cell.senderLabel.font = Font.bold.size(17)
            cell.subjectLabel.font = Font.bold.size(17)
        }
        
        //Set initial icons hidden status
        cell.lockView.isHidden = email.realCriptextToken.isEmpty
        
        cell.lockView.isHidden = email.realCriptextToken.isEmpty || email.from != self.currentUser.email
        
        cell.attachmentView.isHidden = email.attachments.isEmpty
        cell.attachmentImageView.tintColor = Icon.disabled.color
        
        cell.timerView.isHidden = true
        if !isSentFolder { //change this
            cell.timerView.isHidden = true
        }
        
        //Set attachment image
        cell.secureAttachmentView.isHidden = true

        if let criptextAttachments = self.attachmentHash[email.realCriptextToken] {
            cell.secureAttachmentView.isHidden = false
            for attachment in criptextAttachments {
                if !attachment.openArray.isEmpty || !attachment.downloadArray.isEmpty {
                    cell.secureAttachmentImageView.tintColor = Icon.system.color
                    break
                }
            }
        }
        
        cell.subjectLabel.text = email.subject == "" ? "(No Subject)" : email.subject
        
        cell.respondMailView.isHidden = false
        if cell.subjectLabel.text!.lowercased().contains("re:") {
            cell.respondMailImageView.image = Icon.reply.image
        } else if cell.subjectLabel.text!.lowercased().contains("fwd:") {
            cell.respondMailImageView.image = Icon.forward.image
        } else {
            cell.respondMailView.isHidden = true
        }
        
        cell.previewLabel.text = email.snippet
        
        cell.dateLabel.text = DateUtils.conversationTime(email.date)
        
        let size = cell.dateLabel.sizeThatFits(CGSize(width: 130, height: 21))
        cell.dateWidthConstraint.constant = size.width
        
        var senderText = (isSentFolder || self.selectedLabel == .draft) ? email.toDisplayString : email.fromDisplayString
        
        if self.currentUser.email == email.from {
            senderText = "me"
        } else if isSentFolder {
            senderText = email.fromDisplayString
        }
        
        cell.senderLabel.text = senderText
        
        if senderText.isEmpty {
            cell.senderLabel.text = "No Recipients"
        }
        
        //Activity stuff
        if !email.realCriptextToken.isEmpty, let activity = self.activities[email.realCriptextToken] {
            if(activity.exists){
                
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
                
                cell.senderLabel.textColor = UIColor.black
                cell.subjectLabel.textColor = UIColor.init(colorLiteralRed: 114/244, green: 114/255, blue: 114/255, alpha: 1)
            }
            else{
                //UNSENT
                cell.lockImageView.tintColor = UIColor.red
                cell.timerImageView.tintColor = UIColor.red
                cell.secureAttachmentImageView.tintColor = UIColor.red
            }
            
            if !self.currentUser.isPro() {
                cell.lockImageView.tintColor = activity.exists ? UIColor.gray : UIColor.red
                cell.timerImageView.tintColor = activity.exists ? UIColor.gray : UIColor.red
            }
            
            if(activity.secondsSet > 0){
                //INFORMATION ABOUT EXPIRATION
                cell.timerView.isHidden = false
                cell.timerWidthConstraint.constant = 20
            }
            else{
                cell.timerView.isHidden = true
                cell.timerWidthConstraint.constant = 0
            }
        } else {
            cell.lockView.isHidden = true
        }
        
        if !self.currentUser.isPro() {
            cell.secureAttachmentImageView.tintColor = UIColor.gray
        }

        
        guard let _ = self.attachmentHash[email.realCriptextToken] else {
            return cell
        }
        
        cell.secureAttachmentImageView.image = Icon.attachment.secure.image
        
        return cell
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.emailArray.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let email = self.emailArray[indexPath.row]
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if email.isDraft() {
            let navComposeVC = storyboard.instantiateViewController(withIdentifier: "NavigationComposeViewController") as! UINavigationController
            let vcDraft = navComposeVC.childViewControllers.first as! ComposeViewController
            vcDraft.currentService = self.currentService
            vcDraft.currentUser = self.currentUser
            vcDraft.attachmentArray = Array(email.attachments)
            vcDraft.isDraft = true
            vcDraft.emailDraft = email
            vcDraft.loadViewIfNeeded()
            for email in email.to.components(separatedBy: ",") {
                if email.isEmpty {
                    continue
                }
                vcDraft.addToken(email, value: email, to: vcDraft.toField)
            }
            
            if email.subject != "No Subject" {
                vcDraft.subjectField.text = email.subject
            } else if email.subject != "(No Subject)" {
                vcDraft.subjectField.text = email.subject
            }
            
            vcDraft.editorView.html = email.body
            vcDraft.isEdited = false
            
            let snackVC = SnackbarController(rootViewController: navComposeVC)
            
            self.navigationController?.childViewControllers.last!.present(snackVC, animated: true) {
                //needed here because rich editor triggers content change on did load
                vcDraft.isEdited = false
                vcDraft.scrollView.setContentOffset(CGPoint(x: 0, y: -64), animated: true)
            }
            return
        }
        
        let vc = storyboard.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
        
        vc.currentUser = self.currentUser
        vc.currentEmail = email
        vc.currentEmailIndex = indexPath.row
        vc.threadEmailArray = self.emailArray
        vc.selectedLabel = self.selectedLabel
        vc.currentService = self.currentService
        
        vc.activity = self.activities[email.realCriptextToken]
        vc.attachmentArray =  []
        
        if email.isRead() {
            self.navigationController?.pushViewController(vc, animated: true)
            return
        }
        
        let modifyObject = GTLRGmail_ModifyMessageRequest(json: ["removeLabelIds": [Label.unread.id]])
        let query = GTLRGmailQuery_UsersMessagesModify.query(withObject: modifyObject, userId: "me", identifier: email.id)
        
        self.currentService.executeQuery(query) { (ticket, derpo, error) in
            if error == nil {
                email.labels = email.labels.filter{$0 != Label.unread.id}
                self.tableView.reloadRows(at: [self.tableView.indexPathForSelectedRow ?? IndexPath(row: 0, section: 0)], with: UITableViewRowAnimation.automatic)
                (UIApplication.shared.delegate as! AppDelegate).triggerRefresh()
            }
            
        }
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110.0
    }
}
