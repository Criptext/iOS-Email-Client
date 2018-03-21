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
    var selectedLabel:MyLabel!
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
//        cell.attachmentView.isHidden = email.attachments.isEmpty
//        cell.attachmentImageView.tintColor = Icon.disabled.color
        
        //Set attachment image
//        cell.secureAttachmentView.isHidden = true

        if let criptextAttachments = self.attachmentHash[email.realCriptextToken] {
//            cell.secureAttachmentView.isHidden = false
            for attachment in criptextAttachments {
                if !attachment.openArray.isEmpty || !attachment.downloadArray.isEmpty {
                    cell.secureAttachmentImageView.tintColor = Icon.system.color
                    break
                }
            }
        }
        
        cell.subjectLabel.text = email.subject == "" ? "(No Subject)" : email.subject
        
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
                cell.senderLabel.textColor = UIColor.black
                cell.subjectLabel.textColor = UIColor(red: 114/244, green: 114/255, blue: 114/255, alpha: 1)
            }
            else{
                //UNSENT
                cell.secureAttachmentImageView.tintColor = UIColor.red
            }
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
        
        let modifyObject = GTLRGmail_ModifyMessageRequest(json: ["removeLabelIds": [MyLabel.unread.id]])
        let query = GTLRGmailQuery_UsersMessagesModify.query(withObject: modifyObject, userId: "me", identifier: email.id)
        
        self.currentService.executeQuery(query) { (ticket, derpo, error) in
            if error == nil {
                email.labels = email.labels.filter{$0 != MyLabel.unread.id}
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
