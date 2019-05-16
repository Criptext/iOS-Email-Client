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
    @IBOutlet weak var fromEmailTextView: UITextView!
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
    @IBOutlet weak var fromHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ccViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var bccViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var scrollView: UIScrollView!
    var email: Email!
    var initialFromHeight: CGFloat = 0
    var initialToHeight: CGFloat = 0
    var initialCcHeight: CGFloat = 0
    var initialBccHeight: CGFloat = 0
    var contactHeights = [String: CGFloat]()
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
        dateLabel.text = email.completeDate
        replyToView.isHidden = true
        toEmailsTableView.register(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: "contactCell")
        ccEmailsTableView.register(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: "contactCell")
        bccEmailsTableView.register(UINib(nibName: "ContactTableViewCell", bundle: nil), forCellReuseIdentifier: "contactCell")
        ccEmailsTableView.isScrollEnabled = false
        toEmailsTableView.isScrollEnabled = false;
        bccEmailsTableView.isScrollEnabled = false;
        applyTheme()
        toHeightConstraint.constant = initialToHeight
        ccViewHeightConstraint.constant = initialCcHeight
        bccViewHeightConstraint.constant = initialBccHeight
        setFromContact()
    }
    
    func setFromContact(){
        fromEmailTextView.textContainerInset = .zero
        fromEmailTextView.textContainer.lineFragmentPadding = 0
        
        let myContact = !email.fromAddress.isEmpty ? ContactUtils.getStringEmailName(contact: email.fromAddress) : (email.fromContact.email, email.fromContact.displayName)
        let name = ContactUtils.checkIfFromHasName(email.fromAddress) ? myContact.1 : email.fromContact.displayName
        let emailString = ContactUtils.checkIfFromHasName(email.fromAddress) ? myContact.0 : email.fromContact.email
        fromEmailTextView.attributedText = buildContactAttributedString(name, emailString)
        
        fromHeightConstraint.constant = initialFromHeight
    }
    
    func buildContactAttributedString(_ contact: String) -> NSMutableAttributedString{
        let theme = ThemeManager.shared.theme
        
        let attrs = [NSAttributedString.Key.font : Font.regular.size(13.0)!, NSAttributedString.Key.foregroundColor : theme.mainText]
        let stringPart1 = NSMutableAttributedString(string:contact, attributes:attrs)
        return stringPart1
    }
    
    func buildContactAttributedString(_ name: String, _ email: String) -> NSMutableAttributedString{
        let theme = ThemeManager.shared.theme
        
        let attrs = [NSAttributedString.Key.font : Font.regular.size(13.0)!, NSAttributedString.Key.foregroundColor : theme.mainText]
        let stringPart1 = NSMutableAttributedString(string:name + " ", attributes:attrs)
        
        let highlightAttrs = [NSAttributedString.Key.font : Font.regular.size(13.0)!, NSAttributedString.Key.foregroundColor : theme.criptextBlue]
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
        cell.backgroundColor = theme.background
        cell.contactLabel.textColor = theme.mainText
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let type = typeFromTableView(tableView)
        let contact = email.getContacts(type: type)[indexPath.row]
        return contactHeights[contact.email] ?? 25.0
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
        fromEmailTextView.textColor = theme.mainText
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
