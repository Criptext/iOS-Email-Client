//
//  ContactsDetailUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/12/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ContactsDetailUIPopover: BaseUIPopover{
    @IBOutlet weak var fromEmailsLabel: UILabel!
    @IBOutlet weak var replyToEmailsLabel: UILabel!
    @IBOutlet weak var replyToView: UIView!
    @IBOutlet weak var toEmailsTableView: UITableView!
    @IBOutlet weak var ccEmailsTableView: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var toHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ccViewHeightConstraint: NSLayoutConstraint!
    var email: Email!
    
    init(){
        super.init("ContactsDetailUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setFromContact()
        dateLabel.text = email.getFullDate()
        replyToView.isHidden = true
        toLabelHeightConstraint.constant = CGFloat(email.getContacts(type: .to).count * 40)
        toHeightConstraint.constant = CGFloat(email.getContacts(type: .to).count * 40)
        ccViewHeightConstraint.constant = CGFloat(email.getContacts(type: .cc).count * 40)
    }
    
    func setFromContact(){
        let contact = email.fromContact
        fromEmailsLabel.attributedText = buildContactAttributedString(contact.displayName, contact.email)
    }
    
    func buildContactAttributedString(_ name: String, _ email: String) -> NSMutableAttributedString{
        
        let attrs = [NSAttributedStringKey.font : Font.regular.size(15.0), NSAttributedStringKey.foregroundColor : UIColor(red: 125/255, green: 125/255, blue: 125/255, alpha: 1)]
        let stringPart1 = NSMutableAttributedString(string:name + " ", attributes:attrs)
        
        let highlightAttrs = [NSAttributedStringKey.font : Font.regular.size(15.0), NSAttributedStringKey.foregroundColor : UIColor(red: 0/255, green: 145/255, blue: 255/255, alpha: 1)]
        let stringPart2 = NSMutableAttributedString(string:email, attributes: highlightAttrs)
        
        stringPart1.append(stringPart2)
        return stringPart1
    }
}

extension ContactsDetailUIPopover: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView == toEmailsTableView ? numberOfToRows() : numberOfCcRows()
    }
    
    func numberOfToRows() -> Int{
        return email.getContacts(type: .to).count
    }
    
    func numberOfCcRows() -> Int{
        return email.getContacts(type: .cc).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView == toEmailsTableView ? cellForToRowAt(indexPath) : cellForCcRowAt(indexPath)
    }
    
    func cellForToRowAt(_ indexPath: IndexPath) -> UITableViewCell{
        let cell = UITableViewCell(style: .default, reuseIdentifier: "toCell")
        let contact = email.getContacts(type: .to)[indexPath.row]
        cell.textLabel?.numberOfLines = 2
        cell.imageView?.isHidden = true
        cell.textLabel?.isUserInteractionEnabled = true
        cell.textLabel?.attributedText = buildContactAttributedString(contact.displayName, contact.email)
        return cell
        
    }
    
    func cellForCcRowAt(_ indexPath: IndexPath) -> UITableViewCell{
        let cell = UITableViewCell(style: .default, reuseIdentifier: "toCell")
        let contact = email.getContacts(type: .cc)[indexPath.row]
        cell.textLabel?.attributedText = buildContactAttributedString(contact.displayName, contact.email)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40.0
    }
    
}
