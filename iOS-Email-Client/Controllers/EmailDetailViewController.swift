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
        default:
            return
        }
    }
    
    func handleAttachmentTap(_ cell: EmailTableViewCell, _ sender: UIView){
        let custom = AttachmentHistoryUIPopover()
        custom.preferredContentSize = CGSize(width: self.view.frame.size.width - 20, height: 233)
        custom.popoverPresentationController?.sourceView = sender
        custom.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: sender.frame.size.width, height: sender.frame.size.height)
        custom.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        custom.popoverPresentationController?.backgroundColor = UIColor.white
        self.present(custom, animated: true, completion: nil)
    }
}
