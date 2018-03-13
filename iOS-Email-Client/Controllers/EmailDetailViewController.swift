//
//  EmailDetailViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/27/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class EmailDetailViewController: UITableViewController{
    var emailData = EmailDetailData()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailData.mockEmails()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 98
        
        for index in 0..<emailData.emails.count{
            let nib = UINib(nibName: "EmailDetailTableCell", bundle: nil)
            tableView.register(nib, forCellReuseIdentifier: "emailDetail\(index)")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "emailDetail\(indexPath.row)") as! EmailTableViewCell
        let email = emailData.emails[indexPath.row]
        cell.setContent(email.preview, email.content, isExpanded: email.isExpanded)
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emailData.emails.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: "emailTableHeaderView")
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: "emailTableFooterView")
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 78.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 56.0
    }
}

extension EmailDetailViewController: EmailTableViewCellDelegate{
    func tableViewCellDidLoadContent(_ cell: EmailTableViewCell) {
        guard self.tableView.indexPath(for: cell) != nil else {
            return
        }
        tableView.reloadData()
    }
    
    func tableViewCellDidTap(_ cell: EmailTableViewCell) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        let email = emailData.emails[indexPath.row]
        email.isExpanded = !email.isExpanded
        tableView.reloadData()
    }
    
    func tableViewCellDidTapIcon(_ cell: EmailTableViewCell, _ sender: UIView, _ iconType: EmailTableViewCell.IconType) {
        switch(iconType){
        case .attachment:
            handleAttachmentTap(cell, sender)
        case .read:
            handleReadTap(cell, sender)
        case .contacts:
            handleContactsTap(cell, sender)
        case .unsend:
            handleUnsendTap(cell, sender)
        default:
            return
        }
    }
    
    func handleAttachmentTap(_ cell: EmailTableViewCell, _ sender: UIView){
        let historyPopover = HistoryUIPopover()
        historyPopover.historyCellName = "AttachmentHistoryTableCell"
        historyPopover.historyTitleText = "Attachments History"
        historyPopover.historyImage = #imageLiteral(resourceName: "attachment")
        historyPopover.cellHeight = 81.0
        historyPopover.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 233)
        historyPopover.popoverPresentationController?.sourceView = sender
        historyPopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)
        historyPopover.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        historyPopover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(historyPopover, animated: true, completion: nil)
    }
    
    func handleReadTap(_ cell: EmailTableViewCell, _ sender: UIView){
        let historyPopover = HistoryUIPopover()
        historyPopover.historyCellName = "ReadHistoryTableCell"
        historyPopover.historyTitleText = "Read History"
        historyPopover.historyImage = #imageLiteral(resourceName: "read")
        historyPopover.cellHeight = 39.0
        historyPopover.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 233)
        historyPopover.popoverPresentationController?.sourceView = sender
        historyPopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)
        historyPopover.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        historyPopover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(historyPopover, animated: true, completion: nil)
    }
    
    func handleContactsTap(_ cell: EmailTableViewCell, _ sender: UIView){
        let contactsPopover = ContactsDetailUIPopover()
        contactsPopover.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 233)
        contactsPopover.popoverPresentationController?.sourceView = sender
        contactsPopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width/4, height: sender.frame.size.height)
        contactsPopover.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        contactsPopover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(contactsPopover, animated: true, completion: nil)
    }
    
    func handleUnsendTap(_ cell: EmailTableViewCell, _ sender: UIView){
        let contactsPopover = UnsentUIPopover()
        contactsPopover.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 68)
        contactsPopover.popoverPresentationController?.sourceView = sender
        contactsPopover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width/1.0001, height: sender.frame.size.height)
        contactsPopover.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        contactsPopover.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(contactsPopover, animated: true, completion: nil)
    }
}
