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
    @IBOutlet weak var bccEmailsTableView: UITableView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var toHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ccViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bccViewHeightConstraint: NSLayoutConstraint!
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
        toHeightConstraint.constant = CGFloat(email.getContacts(type: .to).count * 28)
        ccViewHeightConstraint.constant = CGFloat(email.getContacts(type: .cc).count * 28)
        bccViewHeightConstraint.constant = CGFloat(email.getContacts(type: .bcc).count * 28)
        toEmailsTableView.register(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: "contactCell")
        ccEmailsTableView.register(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: "contactCell")
        bccEmailsTableView.register(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: "contactCell")
        ccEmailsTableView.isScrollEnabled = false
        toEmailsTableView.isScrollEnabled = false;
        bccEmailsTableView.isScrollEnabled = false;
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
        let type = typeFromTableView(tableView)
        return email.getContacts(type: type).count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "contactCell") as! PlainContactTableViewCell
        let type = typeFromTableView(tableView)
        let contact = email.getContacts(type: type)[indexPath.row]
        cell.contactLabel?.numberOfLines = 2
        cell.contactLabel?.attributedText = buildContactAttributedString(contact.displayName, contact.email)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 25.0
    }
    
    func typeFromTableView(_ tableView: UITableView) -> ContactType {
        switch(tableView){
        case ccEmailsTableView:
            return .cc
        case bccEmailsTableView:
            return .bcc
        default:
            return .to
        }
    }
    
}
