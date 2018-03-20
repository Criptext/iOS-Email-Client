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
    @IBOutlet weak var toEmailsLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var toHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toLabelHeightConstraint: NSLayoutConstraint!
    
    init(){
        super.init("ContactsDetailUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let attributedText = buildContactsAttributedString()
        toEmailsLabel.attributedText = attributedText
        replyToEmailsLabel.attributedText = buildContactAttributedString("Gianni", "gianni@criptext.com")
        fromEmailsLabel.attributedText = buildContactAttributedString("Pedro Aim", "pedro_aim@hotmail.com")
        let toViewHeight = Utils.getLabelHeight(attributedText, width: toEmailsLabel.frame.width, fontSize: 15.0)
        toHeightConstraint.constant = toViewHeight + 8.0
        toLabelHeightConstraint.constant = toViewHeight
    }
    
    func buildContactsAttributedString() -> NSMutableAttributedString{
        let contact1 = buildContactAttributedString("Pedro Aim", "pedro_aim12345536563456345635@criptext.com\n\n")
        let contact2 = buildContactAttributedString("Hola Hola", "hola@criptext.com\n\n")
        let contact3 = buildContactAttributedString("Bye Bye", "bye@criptext.com")
        contact1.append(contact2)
        contact1.append(contact2)
        contact1.append(contact3)
        return contact1
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
