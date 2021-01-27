//
//  ComposerUIView.swift
//  ShareExtension
//
//  Created by Pedro on 11/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit
import CLTokenInputView
import Material
import TheRichTextEditor

protocol ComposerDelegate: class {
    func close()
    func send()
    func badRecipient()
    func typingRecipient(text: String)
    func setAccount(accountId: String, aliasId: Int?)
}

class ComposerUIView: UIView {
    
    let CONTACT_FIELDS_HEIGHT = 90
    let ENTER_LINE_HEIGHT : CGFloat = 28.0
    let COMPOSER_MIN_HEIGHT = 150
    let TOOLBAR_MARGIN_HEIGHT = 25
    let DEFAULT_ATTACHMENTS_HEIGHT = 303
    let MAX_ROWS_BEFORE_CALC_HEIGHT = 3
    let ATTACHMENT_ROW_HEIGHT = 65
    let MARGIN_TOP = 20
    
    @IBOutlet weak var fromField: UILabel!
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var accountOptionsView: MoreOptionsUIView!
    
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var arrowButton: UIButton!
    @IBOutlet var view: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var editorView: TheRichTextEditor!
    @IBOutlet weak var toField: CLTokenInputView!
    @IBOutlet weak var ccField: CLTokenInputView!
    @IBOutlet weak var bccField: CLTokenInputView!
    @IBOutlet weak var subjectTextField: UITextField!
    @IBOutlet weak var bccHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ccHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachmentTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachmentsTableView: UITableView!
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var navigationItem: UINavigationItem!
    @IBOutlet weak var navigationBar: UINavigationBar!
    weak var delegate: ComposerDelegate?
    
    var initialText: String?
    var previousCcHeight: CGFloat = 45
    var previousBccHeight: CGFloat = 45
    var collapsed = false
    weak var myAccount: Account!
    var myAlias: Alias? = nil
    var checkedDomains: [String: Bool] = Utils.defaultDomains
    var accountOptionsInterface: AccountOptionsInterface?
    var composerEditorHeight: CGFloat = 0.0
    
    var inputFailed: [CLTokenInputView: Bool] = [:]
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "ComposerUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
    }
    
    func initialLoad() {
        editorView.enableAccessoryView = false
        
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.detailLabel.tintColor = .white
        self.editorView.delegate = self
        self.editorHeightConstraint.constant = 150
        
        self.toField.fieldName = String.localize("TO")
        self.toField.delegate = self
        self.ccField.fieldName = String.localize("CC")
        self.ccField.delegate = self
        self.bccField.fieldName = String.localize("BCC")
        self.bccField.delegate = self
        
        contactsTableView.isHidden = true
        ccHeightConstraint.constant = 0
        bccHeightConstraint.constant = 0
        
        if let content = initialText {
            editorView.html = content
        }
        
        toField.becomeFirstResponder()
        
        applyTheme()
    }
    
    func applyTheme(){
        self.view.backgroundColor = theme.background
        toField.fieldColor = theme.mainText
        toField.setTextColor(theme.mainText)
        toField.backgroundColor = theme.background
        ccField.fieldColor = theme.mainText
        ccField.setTextColor(theme.mainText)
        ccField.backgroundColor = theme.background
        bccField.backgroundColor = theme.background
        bccField.setTextColor(theme.mainText)
        bccField.fieldColor = theme.mainText
        arrowButton.backgroundColor = theme.background
        toField.backgroundColor = theme.background
        separatorView.backgroundColor = theme.separator
        subjectTextField.textColor = theme.mainText
        subjectTextField.textColor = theme.mainText
        subjectTextField.backgroundColor = theme.background
        subjectTextField.textColor = theme.mainText
        subjectTextField.attributedPlaceholder = NSAttributedString(string: String.localize("SUBJECT"), attributes: [.foregroundColor: theme.mainText, .font: Font.regular.size(subjectTextField.minimumFontSize)!])
        scrollView.backgroundColor = theme.background
        attachmentsTableView.backgroundColor = theme.background
        contactsTableView.backgroundColor = theme.background
        editorView.webView.backgroundColor = theme.background
        editorView.webView.isOpaque = false
        
        fromField.textColor = theme.mainText
        fromField.backgroundColor = theme.background
        
        fromButton.imageView?.tintColor = theme.markedText
        arrowButton.imageView?.tintColor = theme.markedText
        
        navigationBar.isTranslucent = false
    }
    
    func setFrom(account: Account, alias: Alias? = nil) {
        myAccount = account
        myAlias = alias
        
        let accountAliases = buildAccountAliases(currentAccount: account, currentAlias: alias)
        accountOptionsInterface = AccountOptionsInterface(accounts: accountAliases)
        accountOptionsInterface!.delegate = self
        accountOptionsView.setDelegate(newDelegate: accountOptionsInterface!)
        
        let hideMoreButton = accountAliases.count == 0
        setFromUI(hideMoreButton: hideMoreButton, accountEmail: account.email, aliasEmail: alias?.email)
    }
    
    func setFromUI(hideMoreButton: Bool, accountEmail: String, aliasEmail: String?) {
        fromButton.isHidden = hideMoreButton
        fromButton.setImage(UIImage(named: "icon-down"), for: .normal)
        
        if let aliasMail = aliasEmail {
            let theme = ThemeManager.shared.theme
            let attributedFrom = NSMutableAttributedString(string: "\(String.localize("FROM")): ", attributes: [.font: Font.bold.size(15)!])
            let attributedEmail = NSAttributedString(string: aliasMail, attributes: [.font: Font.regular.size(15)!])
            attributedFrom.append(attributedEmail)
            let attributedOrigin = NSAttributedString(string: " (\(accountEmail))", attributes: [.font: Font.regular.size(15)!, .foregroundColor: theme.secondText])
            attributedFrom.append(attributedOrigin)
            fromField.attributedText = attributedFrom
        } else {
            let attributedFrom = NSMutableAttributedString(string: "\(String.localize("FROM")): ", attributes: [.font: Font.bold.size(15)!])
            let attributedEmail = NSAttributedString(string: accountEmail, attributes: [.font: Font.regular.size(15)!])
            attributedFrom.append(attributedEmail)
            fromField.attributedText = attributedFrom
        }
    }
    
    func buildAccountAliases(currentAccount: Account, currentAlias: Alias?) -> [AccountAlias] {
        let accounts = SharedDB.getLoggedAccounts()
        var accountAliases: [AccountAlias] = []
        
        for account in accounts {
            if (currentAlias != nil || account.compoundKey != currentAccount.compoundKey) {
                accountAliases.append(AccountAlias(account: account))
            }
            let aliases = SharedDB.getActiveAliases(account: account)
            for alias in aliases {
                if (currentAlias == nil || currentAlias!.rowId != alias.rowId) {
                    accountAliases.append(AccountAlias(account: account, alias: alias))
                }
            }
        }
        return accountAliases
    }
    
    @IBAction func didPressFrom(_ sender: Any) {
        guard accountOptionsView.isHidden else {
            onClose()
            return
        }
        
        fromButton.setImage(UIImage(named: "icon-up"), for: .normal)
        accountOptionsView.showMoreOptions()
        
        self.toField.endEditing()
        self.ccField.endEditing()
        self.bccField.endEditing()
        self.subjectTextField.resignFirstResponder()
        self.editorView.endEditing(true)
    }
    
    @IBAction func onClosePress(_ sender: Any) {
        delegate?.close()
    }
    
    @IBAction func onSendPress(_ sender: Any) {
        delegate?.send()
    }
    
    @IBAction func onCollapsePress(_ sender: Any) {
        collapsed = !collapsed
        self.ccHeightConstraint.constant = collapsed ? previousCcHeight : 0
        self.bccHeightConstraint.constant = collapsed ? previousBccHeight : 0
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
        self.arrowButton.setImage(collapsed ? Icon.new_arrow.up.image : Icon.new_arrow.down.image, for: .normal)
    }
    
    func getPlainEditorContent () -> String {
        return self.editorView.preview.replaceNewLineCharater(separator: " ")
    }
    
    func resizeAttachmentTable(numberOfAttachments: Int){
        var height = DEFAULT_ATTACHMENTS_HEIGHT
        if numberOfAttachments > MAX_ROWS_BEFORE_CALC_HEIGHT {
            height = MARGIN_TOP + (numberOfAttachments * ATTACHMENT_ROW_HEIGHT)
        }
        
        if numberOfAttachments <= 0 {
            height = 0
        }
        
        self.attachmentTableHeightConstraint.constant = CGFloat(height)
    }
    
    func addContact(name: String, email: String) {
        var focusInput:CLTokenInputView!
        
        if self.toField.isEditing {
            focusInput = self.toField
        }
        
        if self.ccField.isEditing {
            focusInput = self.ccField
        }
        
        if self.bccField.isEditing {
            focusInput = self.bccField
        }
        
        addToken(display: name, value: email, view: focusInput)
    }
}

extension ComposerUIView: TheRichTextEditorDelegate {
    func textDidChange(content: String) {
        
    }
    
    func scrollOffset(verticalOffset: CGFloat) {
        
    }
    
    func heightDidChange() {
        let height = editorView.height
        let cgheight = CGFloat(height)
        let diff = cgheight - composerEditorHeight
        let offset = self.scrollView.contentOffset
        
        if CGFloat(Int(height) + CONTACT_FIELDS_HEIGHT + TOOLBAR_MARGIN_HEIGHT) > self.view.frame.origin.y + self.view.frame.width {
            var newOffset = CGPoint(x: offset.x, y: offset.y + ENTER_LINE_HEIGHT)
            if diff < 0  {
                newOffset = CGPoint(x: offset.x, y: offset.y - ENTER_LINE_HEIGHT)
            }
            if !editorView.webView.isLoading {
                self.scrollView.setContentOffset(newOffset, animated: true)
            }
        }
        
        guard Int(height) > COMPOSER_MIN_HEIGHT else {
            return
        }
        
        composerEditorHeight = cgheight
        self.editorHeightConstraint.constant = cgheight
    }
    
    func editorDidLoad() {
        editorView.placeholder = String.localize("MESSAGE")
        editorView.setEditorFontColor(theme.mainText)
        editorView.setEditorBackgroundColor(theme.background)
        editorView.backgroundColor = theme.background
        toField.beginEditing()
    }
    
    func addToContent(text: String) {
        editorView.html = editorView.html + text
    }
}

extension ComposerUIView: CLTokenInputViewDelegate {
    func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        guard let input = text else {
            return
        }
        
        handleRecipientsInput(input: input, tokenView: view, onExit: false)
        
        self.delegate?.typingRecipient(text: input)
    }
    
    private func checkDomain(domain: String, token: CLToken, view: CLTokenInputView) -> Bool {
        let theme = ThemeManager.shared.theme
        var checked: Bool = (domain == Env.plainDomain)
        APIManager.getDomainCheck(domains: [domain], token: self.myAccount.jwt) { (responseData) in
            guard case let .SuccessArray(domainArray) = responseData else {
                return
            }
            checked = domainArray[0]["isCriptextDomain"] as? Bool ?? checked
            self.checkedDomains[domainArray[0]["name"] as! String] = checked
            
            let textColor = checked ? theme.emailBubbleCriptext : theme.emailBubble
            let bgColor = checked ? theme.bgBubbleCriptext : theme.bgBubble
            
            view.remove(token)
            view.add(token, highlight: textColor, background: bgColor)
        }
        return checked
    }
    
    func addToken(display: String, value: String, view: CLTokenInputView) {
        let theme = ThemeManager.shared.theme
        var isFromCriptext = value.contains(Env.domain)
        let valueObject = NSString(string: value)
        let token = CLToken(displayText: display, context: valueObject)
        
        if(Utils.validateEmail(value)){
            let domain = ContactUtils.getUsernameAndDomain(email: value).1
            isFromCriptext = checkedDomains[domain] ?? checkDomain(domain: domain, token: token, view: view)
        }
        let textColor = isFromCriptext ? theme.emailBubbleCriptext : theme.emailBubble
        let bgColor = isFromCriptext ? theme.bgBubbleCriptext : theme.bgBubble
        
        view.add(token, highlight: textColor, background: bgColor)
    }
    
    func tokenInputView(_ view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        switch view {
        case toField:
            toHeightConstraint.constant = height > 45.0 ? height : 45.0
        case ccField:
            previousCcHeight = height > 45.0 ? height : 45.0
            ccHeightConstraint.constant = height
        case bccField:
            previousBccHeight = height
            bccHeightConstraint.constant = height
        default:
            break
        }
    }
    
    func handleRecipientsInput(input: String, tokenView: CLTokenInputView, onExit: Bool) {
        guard input.count > 0 else {
            inputFailed[tokenView] = false
            return
        }
        
        let hasFailed = inputFailed[tokenView] ?? false
        let inputCondition = hasFailed ? (input.last == " " || input.last == ",") : input.contains(",") || input.contains(" ")
        
        guard onExit || inputCondition else {
            return
        }
        
        let inputText = input.replacingOccurrences(of: ",", with: "")
        let recipients = inputText.split(separator: " ").map( {$0.description} )
        
        var invalidNames = ""
        for recipient in recipients {
            if !recipient.contains("@") {
                addToken(display: "\(recipient)\(Env.domain)", value: "\(recipient)\(Env.domain)".lowercased(), view: tokenView)
            } else if Utils.validateEmail(recipient) {
                addToken(display: recipient, value: recipient.lowercased(), view: tokenView)
            } else {
                if (invalidNames.isEmpty) {
                    invalidNames = recipient
                } else {
                    invalidNames += " \(recipient)"
                }
            }
        }
        
        inputFailed[tokenView] = !invalidNames.isEmpty
        
        guard !onExit else {
            if !invalidNames.isEmpty {
                delegate?.badRecipient()
            }
            return
        }
        
        if let lastCharacter = inputText.last,
            !invalidNames.isEmpty && lastCharacter == " " {
            if let lastCharacter = inputText.last,
                !invalidNames.isEmpty && lastCharacter == " " {
                delegate?.badRecipient()
            }
        }
        
        if !invalidNames.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                tokenView.text = invalidNames
            }
        }
    }
    
    func tokenInputViewDidEndEditing(_ view: CLTokenInputView) {
        self.contactsTableView.isHidden = true
        
        guard let text = view.text else {
            return
        }
        
        handleRecipientsInput(input: text, tokenView: view, onExit: true)
    }
}

extension ComposerUIView: AccountOptionsInterfaceDelegate {
    func onClose() {
        fromButton.setImage(UIImage(named: "icon-down"), for: .normal)
        accountOptionsView.closeMoreOptions()
    }
    
    func accountSelected(account: Account, alias: Alias?) {
        fromButton.setImage(UIImage(named: "icon-down"), for: .normal)
        accountOptionsView.closeMoreOptions()
        guard !account.isInvalidated else {
            return
        }
        self.delegate?.setAccount(accountId: account.compoundKey, aliasId: alias?.rowId)
    }
}
