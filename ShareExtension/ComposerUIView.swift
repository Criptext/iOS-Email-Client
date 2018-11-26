//
//  ComposerUIView.swift
//  ShareExtension
//
//  Created by Allisson on 11/21/18.
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
    var collapsed = true
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "ComposerUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
    }
    
    func initialLoad() {
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationItem.detailLabel.tintColor = .white
        self.editorView.placeholder = String.localize("Message")
        self.editorView.delegate = self
        self.editorView.isScrollEnabled = false
        self.editorHeightConstraint.constant = 150
        
        self.toField.fieldName = String.localize("To")
        self.toField.tintColor = Icon.system.color
        self.toField.delegate = self
        self.ccField.fieldName = String.localize("Cc")
        self.ccField.tintColor = Icon.system.color
        self.ccField.delegate = self
        self.bccField.fieldName = String.localize("Bcc")
        self.bccField.tintColor = Icon.system.color
        self.bccField.delegate = self
        
        contactsTableView.isHidden = true
        ccHeightConstraint.constant = 0
        bccHeightConstraint.constant = 0
        
        if let content = initialText {
            editorView.html = content
        }
        
        toField.becomeFirstResponder()
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
        
        let valueObject = NSString(string: email)
        let token = CLToken(displayText: name, context: valueObject)
        focusInput.add(token)
    }
}

extension ComposerUIView: RichEditorDelegate {
    func richEditorDidLoad(_ editor: RichEditorView) {
        
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
                let valueObject = NSString(string: "\(name)\(Env.domain)")
                let token = CLToken(displayText: "\(name)\(Env.domain)", context: valueObject)
                view.add(token)
                return
            }
            
            if Utils.validateEmail(name) {
                let valueObject = NSString(string: name)
                let token = CLToken(displayText: name, context: valueObject)
                view.add(token)
            } else {
                self.delegate?.badRecipient()
            }
        }
        
        self.delegate?.typingRecipient(text: input)
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
            let valueObject = NSString(string: "\(text)\(Constants.domain)")
            let token = CLToken(displayText: "\(text)\(Constants.domain)", context: valueObject)
            view.add(token)
            return
        }
        if Utils.validateEmail(text) {
            let valueObject = NSString(string: text)
            let token = CLToken(displayText: text, context: valueObject)
            view.add(token)
        } else {
            self.delegate?.badRecipient()
        }
    }
}
