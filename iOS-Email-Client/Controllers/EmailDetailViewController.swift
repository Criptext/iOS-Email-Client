//
//  EmailDetailViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/27/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class EmailDetailViewController: UIViewController {
    var emailData = EmailDetailData()
    @IBOutlet weak var backgroundOverlayView: UIView!
    @IBOutlet weak var emailsTableView: UITableView!
    @IBOutlet weak var optionsContainerView: UIView!
    @IBOutlet weak var optionsContainerOffsetConstraint: NSLayoutConstraint!
    var tapGestureRecognizer:UITapGestureRecognizer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailData.mockEmails()
        setupMoreOptionsViews()
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeMoreOptions))
        for index in 0..<emailData.emails.count{
            let nib = UINib(nibName: "EmailDetailTableCell", bundle: nil)
            emailsTableView.register(nib, forCellReuseIdentifier: "emailDetail\(index)")
        }
    }
    
    func setupMoreOptionsViews(){
        emailsTableView.rowHeight = UITableViewAutomaticDimension
        emailsTableView.estimatedRowHeight = 108
        optionsContainerView.isHidden = false
        backgroundOverlayView.isHidden = true
        backgroundOverlayView.alpha = 0.0
        optionsContainerOffsetConstraint.constant = -300.0
    }
    
    @objc func closeMoreOptions(){
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            self.optionsContainerOffsetConstraint.constant = -300.0
            self.backgroundOverlayView.alpha = 0.0
            self.view.layoutIfNeeded()
        }, completion: {
            finished in
                self.optionsContainerView.isHidden = true
                self.backgroundOverlayView.isHidden = true
            self.backgroundOverlayView.removeGestureRecognizer(self.tapGestureRecognizer)
        })
    }
}

extension EmailDetailViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "emailDetail\(indexPath.row)") as! EmailTableViewCell
        let email = emailData.emails[indexPath.row]
        cell.setContent(email.preview, email.content, isExpanded: email.isExpanded)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emailData.emails.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: "emailTableHeaderView")
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
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
        guard let indexPath = self.emailsTableView.indexPath(for: cell) else {
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
        case .options:
            handleOptionsTap(cell, sender)
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
    
    func handleOptionsTap(_ cell: EmailTableViewCell, _ sender: UIView){
        self.optionsContainerView.isHidden = false
        self.backgroundOverlayView.isHidden = false
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
            self.optionsContainerOffsetConstraint.constant = 0.0
            self.backgroundOverlayView.alpha = 1.0
            self.view.layoutIfNeeded()
        }, completion: {
            finished in
            print("HOLI HOLI")
            self.backgroundOverlayView.addGestureRecognizer(self.tapGestureRecognizer)
        })
    }
}
