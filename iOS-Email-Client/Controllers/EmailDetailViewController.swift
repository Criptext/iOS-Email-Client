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
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "emailTableCellView", for: indexPath) as! EmailTableViewCell
        let email = emailData.emails[indexPath.row]
        cell.setContent(email.preview, email.content, isExpanded: email.isExpanded)
        cell.myHeight = email.myHeight
        cell.delegate = self
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emailData.emails.count
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as! EmailTableViewCell? else {
            return
        }
        let email = emailData.emails[indexPath.row]
        email.isExpanded = !email.isExpanded
        email.myHeight = 0
        cell.toggleCell(email.isExpanded)
        if(!email.isExpanded){
            tableView.beginUpdates()
            tableView.endUpdates()
        }
    }
}

extension EmailDetailViewController: EmailTableViewCellDelegate{
    func tableViewCellDidLoadContent(_ cell: EmailTableViewCell, _ height: Int) {
        guard let indexPath = self.tableView.indexPath(for: cell) else {
            return
        }
        let email = emailData.emails[indexPath.row]
        email.myHeight = height
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        cell.setNeedsUpdateConstraints()
        cell.updateConstraintsIfNeeded()
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
}
