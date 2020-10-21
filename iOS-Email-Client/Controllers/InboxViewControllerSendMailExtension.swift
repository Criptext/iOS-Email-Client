//
//  InboxViewControllerSendMailExtension.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/13/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit

extension InboxViewController: ComposerSendMailDelegate {
    func newDraft(draft: Email) {
        guard mailboxData.selectedLabel == SystemLabel.draft.id else {
            return
        }
        self.refreshThreadRows()
        self.showSendingSnackBar(message: String.localize("DRAFT_SAVED"), permanent: false)
    }
    
    func sendFailEmail(){
        guard let email = DBManager.getEmailFailed(account: self.myAccount) else {
            return
        }
        DBManager.updateEmail(email, status: .sending)
        let bodyFromFile = FileUtils.getBodyFromFile(account: myAccount, metadataKey: "\(email.key)")
        sendMail(email: email,
                 emailBody: bodyFromFile.isEmpty ? email.content : bodyFromFile,
                 password: nil)
    }
    
    func sendMail(email: Email, emailBody: String, password: String?) {
        showSendingSnackBar(message: String.localize("SENDING_MAIL"), permanent: true)
        reloadIfSentMailbox(email: email)
        let emailId = email.compoundKey
        let sendMailAsyncTask = SendMailAsyncTask(email: email, emailBody: emailBody, password: password)
        sendMailAsyncTask.start { [weak self] responseData in
            guard let weakSelf = self else {
                return
            }
            if case .Unauthorized = responseData {
                weakSelf.showSnackbar(String.localize("AUTH_ERROR_MESSAGE"), attributedText: nil, permanent: false)
                return
            }
            if case .Removed = responseData {
                weakSelf.logout(account: weakSelf.myAccount, manually: false)
                return
            }
            if case .Forbidden = responseData {
                weakSelf.showSnackbar(String.localize("EMAIL_FAILED"), attributedText: nil, permanent: false)
                weakSelf.presentPasswordPopover(myAccount: weakSelf.myAccount)
                return
            }
            if case let .Error(error) = responseData {
                weakSelf.showRetrySendSnackbar(message: "\(error.description). \(String.localize("RESENT_FUTURE"))", emailId: emailId)
                return
            }
            guard case let .SuccessInt(key) = responseData else {
                weakSelf.showRetrySendSnackbar(message: String.localize("EMAIL_FAILED"), emailId: emailId)
                return
            }
            let sentEmail = DBManager.getMail(key: key, account: weakSelf.myAccount)
            guard sentEmail != nil else {
                weakSelf.showSendingSnackBar(message: String.localize("EMAIL_SENT"), permanent: false)
                return
            }
            weakSelf.refreshThreadRows()
            let message = sentEmail!.secure ? String.localize("EMAIL_SENT_SECURE") : String.localize("EMAIL_SENT")
            weakSelf.showSendingSnackBar(message: message, permanent: false)
            weakSelf.sendFailEmail()
        }
    }
    
    func showRetrySendSnackbar(message: String, emailId: String) {
        let retryButton = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        retryButton.backgroundColor = .clear
        retryButton.setTitle(String.localize("RETRY"), for: .normal)
        retryButton.toolbarPlaceholder = emailId
        retryButton.addTarget(self, action: #selector(onClickRetrySend), for: .touchUpInside)
        
        showSnackbar(message, attributedText: nil, buttons: [retryButton], permanent: false)
        
        let content = UNMutableNotificationContent()
        content.title = String.localize("UNABLE_SENT")
        content.subtitle = message
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = "RESEND_EMAIL"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "resend-\(emailId)", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    @objc func onClickRetrySend(sender: UIButton) {
        guard let emailId = sender.toolbarPlaceholder,
              let email = DBManager.getMail(compoundKey: emailId) else {
            return
        }
        resendEmail(email)
    }
    
    func resendEmail(_ email: Email) {
        DBManager.updateEmail(email, status: .sending)
        let bodyFromFile = FileUtils.getBodyFromFile(account: email.account, metadataKey: "\(email.key)")
        sendMail(email: email,
                 emailBody: bodyFromFile.isEmpty ? email.content : bodyFromFile,
                 password: nil)
    }
    
    func reloadIfSentMailbox(email: Email){
        if( SystemLabel(rawValue: self.mailboxData.selectedLabel) == .sent || mailboxData.threads.contains(where: {$0.threadId == email.threadId}) ){
            self.refreshThreadRows()
        }
    }
    
    func showSendingSnackBar(message: String, permanent: Bool) {
        let fullString = NSMutableAttributedString(string: "")
        let attrs = [NSAttributedString.Key.font : Font.regular.size(15)!, NSAttributedString.Key.foregroundColor : UIColor.white]
        fullString.append(NSAttributedString(string: message, attributes: attrs))
        self.showSnackbar("", attributedText: fullString, permanent: permanent)
    }
    
    func deleteDraft(draftId: Int) {
        guard let draftIndex = mailboxData.threads.firstIndex(where: {$0.lastEmailKey == draftId}) else {
                return
        }
        mailboxData.threads.remove(at: draftIndex)
        tableView.reloadData()
    }
}
