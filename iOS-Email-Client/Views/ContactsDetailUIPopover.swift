//
//  ContactsDetailUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/12/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ContactsDetailUIPopover: BaseUIPopover{
    
    @IBOutlet weak var bccView: UIView!
    @IBOutlet weak var dateView: UIView!
    @IBOutlet weak var fromView: UIView!
    @IBOutlet weak var ccView: UIView!
    @IBOutlet weak var toView: UIView!
    @IBOutlet weak var fromTitleLabel: UILabel!
    @IBOutlet weak var fromEmailsLabel: UILabel!
    @IBOutlet weak var replyToEmailsLabel: UILabel!
    @IBOutlet weak var replyTitleLabel: UILabel!
    @IBOutlet weak var replyToView: UIView!
    @IBOutlet weak var toTitleLabel: UILabel!
    @IBOutlet weak var toEmailsTableView: UITableView!
    @IBOutlet weak var ccTitleLabel: UILabel!
    @IBOutlet weak var ccEmailsTableView: UITableView!
    @IBOutlet weak var bccTitleLabel: UILabel!
    @IBOutlet weak var bccEmailsTableView: UITableView!
    @IBOutlet weak var dateTitleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var toHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ccViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bccViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    var email: Email!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    init(){
        super.init("ContactsDetailUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setFromContact()
        dateLabel.text = email.completeDate
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
        applyTheme()
    }
    
    func setFromContact(){
        let contact = email.fromContact
        fromEmailsLabel.attributedText = buildContactAttributedString(contact.displayName, contact.email)
    }
    
    func buildContactAttributedString(_ name: String, _ email: String) -> NSMutableAttributedString{
        
        let attrs = [NSAttributedStringKey.font : Font.regular.size(13.0)!, NSAttributedStringKey.foregroundColor : UIColor(red: 125/255, green: 125/255, blue: 125/255, alpha: 1)]
        let stringPart1 = NSMutableAttributedString(string:name + " ", attributes:attrs)
        
        let highlightAttrs = [NSAttributedStringKey.font : Font.regular.size(13.0)!, NSAttributedStringKey.foregroundColor : UIColor(red: 0/255, green: 145/255, blue: 255/255, alpha: 1)]
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
        cell.contactTextView.attributedText = buildContactAttributedString(contact.displayName, contact.email)
        cell.contactLabel?.numberOfLines = 1
        cell.contactLabel?.attributedText = buildContactAttributedString(contact.displayName, contact.email)
        cell.backgroundColor = theme.background
        cell.contactLabel.textColor = theme.mainText
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
    
    func applyTheme() {
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        fromView.backgroundColor = theme.background
        replyToView.backgroundColor = theme.background
        toView.backgroundColor = theme.background
        ccView.backgroundColor = theme.background
        bccView.backgroundColor = theme.background
        dateView.backgroundColor = theme.background
        
        fromTitleLabel.textColor = theme.mainText
        fromEmailsLabel.textColor = theme.mainText
        replyTitleLabel.textColor = theme.mainText
        replyToEmailsLabel.textColor = theme.mainText
        toTitleLabel.textColor = theme.mainText
        toEmailsTableView.backgroundColor = theme.background
        ccTitleLabel.textColor = theme.mainText
        ccEmailsTableView.backgroundColor = theme.background
        bccTitleLabel.textColor = theme.mainText
        bccEmailsTableView.backgroundColor = theme.background
        dateTitleLabel.textColor = theme.mainText
        dateLabel.textColor = theme.mainText
        stackView.backgroundColor = theme.background
        scrollView.backgroundColor = theme.background
    }
}
