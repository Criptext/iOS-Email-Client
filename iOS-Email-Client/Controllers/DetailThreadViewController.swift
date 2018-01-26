//
//  DetailThreadViewController.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 9/3/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftSoup
import GoogleAPIClientForREST

class DetailThreadViewController: UIViewController {
    
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    var currentThread:[Email]!
    var activities = [String:Activity]()
    var attachmentHash = [String: [AttachmentCriptext]]()
    
    var currentUser: User!
    var currentService: GTLRService!
    var baseScript: String!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView()
        self.tableView.separatorColor = UIColor.clear
        self.tableView.estimatedRowHeight = 79
        self.tableView.rowHeight = UITableViewAutomaticDimension
        
        
        
        
        for (index, email) in currentThread.enumerated() {
            email.isDisplayed = !email.isRead()
            self.tableView.register(UINib(nibName: "DetailThreadTableViewCell", bundle: nil), forCellReuseIdentifier: "Detail\(index)")
            
            guard email.isDisplayed else { continue }
            
        }
        
        if let firstEmail = self.currentThread.first {
            self.subjectLabel.text = firstEmail.subject
        }
        
        let jsURL = Bundle.main.url(forResource: "MCOMessageViewScript", withExtension: "js")
        let scriptContent = try! String(contentsOfFile: jsURL!.path)
        
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
        
        self.baseScript = script
//        self.tableView.reloadData()
    }
}

extension DetailThreadViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Detail\(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "Detail\(indexPath.row)", for: indexPath) as! DetailThreadTableViewCell
        
        let email = self.currentThread[indexPath.row]
        
        if email.isDisplayed {
            cell.expandedContainer.isHidden = false
            cell.collapsedContainer.isHidden = true
            cell.webViewHeightConstraint.constant = 200
            cell.expandedDateLabel.isHidden = false
            cell.dateBottomSpaceConstraint.constant = 8
            cell.timerLeftSpaceConstraint.constant = 5
            
        } else {
            cell.expandedContainer.isHidden = true
            cell.collapsedContainer.isHidden = false
            cell.webViewHeightConstraint.constant = 0
            cell.dateBottomSpaceConstraint.constant = -15
            cell.timerLeftSpaceConstraint.constant = -95
        }
        
        cell.collapsedDateLabel.text = DateUtils.conversationTime(email.date)
        cell.expandedDateLabel.text = cell.collapsedDateLabel.text
        
        cell.collapsedSenderLabel.text = email.fromDisplayString
        cell.expandedSenderLabel.text = email.fromDisplayString
        
        cell.expandedRecipientLabel.text = "to \(email.toDisplayString)"
        cell.collapsedSnippet.text = email.snippet
        
        if cell.webView.isLoading {
            print("webview is loading")
            return cell
        }
        
        if email.isLoaded {
            print("webview is loaded")
            return cell
//            cell.webView.load
        }
        
        //////////////////////////////////////////////////////////////////////
        
        if let activity = self.activities[email.realCriptextToken], !activity.exists {
            cell.collapsedLockButton.tintColor = UIColor.red
            cell.expandedLockButton.tintColor = UIColor.red
            cell.collapsedAttachmentButton.tintColor = UIColor.red
            cell.expandedAttachmentButton.tintColor = UIColor.red
            
            cell.expandedUnsendButton.setImage(Icon.btn_unsent.image, for: .normal)
            cell.expandedUnsendButton.isEnabled = false
            cell.expandedUnsendButton.isHidden = true
        }
        
        if let attachmentArray = self.attachmentHash[email.realCriptextToken], !attachmentArray.isEmpty {
            cell.collapsedAttachmentButton.isHidden = false
            cell.expandedAttachmentButton.isHidden = false
        }
        
        if !self.currentUser.isPro() {
            cell.collapsedTimerButton.tintColor = Icon.enabled.color
            cell.expandedTimerButton.tintColor = Icon.enabled.color
            
            cell.collapsedAttachmentButton.tintColor = Icon.enabled.color
            cell.expandedAttachmentButton.tintColor = Icon.enabled.color
            
            cell.collapsedLockButton.tintColor = Icon.enabled.color
            cell.expandedLockButton.tintColor = Icon.enabled.color
            
            cell.expandedUnsendButton.tintColor = UIColor.gray
        }
        
        
        
//        self.attachmentGmailArray = Array(self.currentEmail.attachments)
        
        //do everything on background thread
        
//        let currentEmail2 = currentEmail as! Email
//        currentEmail2.criptextTokens = []
//        
//        if !currentEmail2.criptextTokensSerialized.isEmpty {
//            currentEmail2.criptextTokens = currentEmail2.criptextTokensSerialized.components(separatedBy: ",")
//        }
//        
//        currentEmail2.labels = currentEmail2.labelArraySerialized.components(separatedBy: ",")
//        email.isLoaded = true
        var doc:Document!
        do {
            doc = try SwiftSoup.parse(email.body)
            
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
            
            cell.webView.loadHTMLString(email.body+self.baseScript, baseURL: nil)
        }
        
        guard !email.criptextTokens.isEmpty else {
//            self.timerTrailingConstraint.constant = 15
            cell.webView.loadHTMLString(try! doc.html() + self.baseScript, baseURL: nil)
            return cell
        }
        
        var markOpen = [String]()
        
        if email.from != currentUser.email {
            markOpen.append(email.realCriptextToken)
        }
        
        APIManager.getMailDetails(currentUser,
                                  tokens: email.criptextTokens,
                                  mark: markOpen) { (error, attachments, activity, textHash) in
                                    guard let textHash = textHash else {
                                        cell.webView.loadHTMLString(email.body+self.baseScript, baseURL: nil)
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
                                            
                                            cell.webView.loadHTMLString(try doc.html() + self.baseScript, baseURL: nil)
                                        } catch {
                                            cell.webView.loadHTMLString(email.body + self.baseScript, baseURL: nil)
                                        }
                                    }
                                    
                                    guard let attachmentArray = attachments else {
                                        return
                                    }
                                    
                                    for attachment in attachmentArray {
                                        if let attachmentArray = self.attachmentHash[email.realCriptextToken], !attachmentArray.isEmpty {
                                            cell.collapsedAttachmentButton.isHidden = false
                                            cell.expandedAttachmentButton.isHidden = false
                                        }
                                        
                                        
                                        if attachment.emailToken == email.realCriptextToken,
                                            var attachmentArray = self.attachmentHash[email.realCriptextToken],
                                            !attachmentArray.contains(where: {$0.fileToken == attachment.fileToken}) {
                                            attachmentArray.append(attachment)
                                            
                                            
                                            if self.currentUser.email == email.from,
                                                !attachment.openArray.isEmpty || !attachment.downloadArray.isEmpty,
                                                let activity = self.activities[email.realCriptextToken],
                                                activity.exists {
                                                cell.expandedAttachmentButton.tintColor = Icon.activated.color
                                                cell.collapsedAttachmentButton.tintColor = Icon.activated.color
                                            }
                                        }
                                    }
                                    
                                    if let attachmentArray = self.attachmentHash[email.realCriptextToken],
                                        !attachmentArray.isEmpty,
                                        self.currentUser.email == email.from {
                                        cell.collapsedAttachmentButton.isHidden = false
                                        cell.expandedAttachmentButton.isHidden = false
                                    }
                                    
//                                    self.tableViewHeightConstraint.constant = CGFloat(self.attachmentArray.count + self.attachmentGmailArray.count) * self.rowHeight
                                    self.tableView.reloadData()
        }
        
        //////////////////////////////////////////////////////////////////////
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentThread.count
    }
}

extension DetailThreadViewController: UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let email = self.currentThread[indexPath.row]
        
        email.isDisplayed = !email.isDisplayed
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
//    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        let email = self.currentThread[indexPath.row]
//        
//        if email.isDisplayed {
//            return 310.0
//        }
//        
//        return 85
//    }
}
