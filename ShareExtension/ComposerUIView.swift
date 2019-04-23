//
//  ComposerUIView.swift
//  ShareExtension
//
//  Created by Pedro on 11/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit
import RichEditorView
import CLTokenInputView
import Material

protocol ComposerDelegate: class {
    func close()
    func send()
    func badRecipient()
    func typingRecipient(text: String)
    func setAccount(username: String)
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
    @IBOutlet weak var fromMenuView: BottomMenuView!
    
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var arrowButton: UIButton!
    @IBOutlet var view: UIView!
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var editorView: RichEditorView!
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
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.detailLabel.tintColor = .white
        self.editorView.placeholder = String.localize("MESSAGE")
        self.editorView.delegate = self
        self.editorView.isScrollEnabled = false
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
        
        fromMenuView.delegate = self
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
    
    func setFrom(account: Account, emails: [String]) {
        fromButton.isHidden = emails.count == 0
        let attributedFrom = NSMutableAttributedString(string: "From: ", attributes: [.font: Font.bold.size(15)!])
        let attributedEmail = NSAttributedString(string: account.email, attributes: [.font: Font.regular.size(15)!])
        attributedFrom.append(attributedEmail)
        fromMenuView.isUserInteractionEnabled = false
        fromMenuView.initialLoad(options: emails)
        fromField.attributedText = attributedFrom
        fromButton.setImage(UIImage(named: "icon-down"), for: .normal)
    }
    
    @IBAction func didPressFrom(_ sender: Any) {
        fromMenuView.isUserInteractionEnabled = true
        fromMenuView.toggleMenu(true)
        fromButton.setImage(UIImage(named: "icon-up"), for: .normal)
        
        self.toField.endEditing()
        self.ccField.endEditing()
        self.bccField.endEditing()
        self.subjectTextField.resignFirstResponder()
        self.editorView.webView.endEditing(true)
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
        return self.editorView.text.replaceNewLineCharater(separator: " ")
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

extension ComposerUIView: RichEditorDelegate {
    func richEditorDidLoad(_ editor: RichEditorView) {
        editorView.setEditorFontColor(theme.mainText)
        editorView.setEditorBackgroundColor(theme.background)
        toField.beginEditing()
    }
    
    func addToContent(text: String) {
        editorView.html = editorView.html + text
    }
    
    func richEditor(_ editor: RichEditorView, heightDidChange height: Int) {
        let cgheight = CGFloat(height)
        let diff = cgheight - self.editorHeightConstraint.constant
        let offset = self.scrollView.contentOffset
        
        if CGFloat(height + CONTACT_FIELDS_HEIGHT + TOOLBAR_MARGIN_HEIGHT) > self.view.frame.origin.y + self.view.frame.width {
            var newOffset = CGPoint(x: offset.x, y: offset.y + ENTER_LINE_HEIGHT)
            if diff == -ENTER_LINE_HEIGHT  {
                newOffset = CGPoint(x: offset.x, y: offset.y - ENTER_LINE_HEIGHT)
            }
            
            if !editor.webView.isLoading {
                self.scrollView.setContentOffset(newOffset, animated: true)
            }
        }
        
        guard height > COMPOSER_MIN_HEIGHT else {
            return
        }
        
        self.editorHeightConstraint.constant = cgheight
    }
}

extension ComposerUIView: CLTokenInputViewDelegate {
    func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        guard let input = text else {
            return
        }
        
        if input.contains(",") || input.contains(" ") {
            let name = input.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")
            
            guard name.contains("@") else {
                addToken(display: "\(name)\(Env.domain)", value: "\(name)\(Env.domain)", view: view)
                return
            }
            
            if Utils.validateEmail(name) {
                
            } else {
                self.delegate?.badRecipient()
            }
        }
        
        self.delegate?.typingRecipient(text: input)
    }
    
    func addToken(display: String, value: String, view: CLTokenInputView) {
        let textColor = value.contains(Constants.domain) ? UIColor(red: 0, green:0.23, blue: 0.41, alpha: 1.0) : UIColor(red: 0.13, green:0.13, blue: 0.13, alpha: 1.0)
        let bgColor = value.contains(Constants.domain) ? UIColor(red: 0.90, green:0.96, blue: 1.0, alpha: 1.0) : UIColor(red: 0.94, green:0.94, blue: 0.94, alpha: 1.0)
        let valueObject = NSString(string: value)
        let token = CLToken(displayText: display, context: valueObject)
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
    
    func tokenInputViewDidEndEditing(_ view: CLTokenInputView) {
        
        //self.contactTableView.isHidden = true
        
        guard let text = view.text, text.count > 0 else {
            return
        }
        
        guard text.contains("@") else {
            addToken(display: "\(text)\(Constants.domain)", value: "\(text)\(Constants.domain)", view: view)
            return
        }
        if Utils.validateEmail(text) {
            addToken(display: text, value: text, view: view)
        } else {
            self.delegate?.badRecipient()
        }
    }
}

extension ComposerUIView: BottomMenuDelegate {
    func didPressOption(_ option: String) {
        delegate?.setAccount(username: option)
    }
    
    func didPressBackground() {
        fromMenuView.isUserInteractionEnabled = false
        self.fromMenuView.toggleMenu(false)
        fromButton.setImage(UIImage(named: "icon-down"), for: .normal)
    }
}
