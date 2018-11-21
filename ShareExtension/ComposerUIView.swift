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

protocol ComposerDelegate: class {
    func close()
}

class ComposerUIView: UIView {
    
    @IBOutlet var view: UIView!
    @IBOutlet weak var editorView: RichEditorView!
    @IBOutlet weak var toField: CLTokenInputView!
    @IBOutlet weak var ccField: CLTokenInputView!
    @IBOutlet weak var bccField: CLTokenInputView!
    @IBOutlet weak var bccHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ccHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var toHeightConstraint: NSLayoutConstraint!
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
        self.editorView.placeholder = String.localize("Message")
        self.editorView.delegate = self
        
        self.toField.fieldName = String.localize("To")
        self.toField.tintColor = Icon.system.color
        self.toField.delegate = self
        self.ccField.fieldName = String.localize("Cc")
        self.ccField.tintColor = Icon.system.color
        self.ccField.delegate = self
        self.bccField.fieldName = String.localize("Bcc")
        self.bccField.tintColor = Icon.system.color
        self.bccField.delegate = self
        
        ccHeightConstraint.constant = 0
        bccHeightConstraint.constant = 0
        
        if let content = initialText {
            editorView.html = content
        }
    }
    
    @IBAction func onClosePress(_ sender: Any) {
        delegate?.close()
    }
    
    @IBAction func onSendPress(_ sender: Any) {
        
    }
    
    @IBAction func onCollapsePress(_ sender: Any) {
        collapsed = !collapsed
        self.ccHeightConstraint.constant = collapsed ? previousCcHeight : 0
        self.bccHeightConstraint.constant = collapsed ? previousBccHeight : 0
        UIView.animate(withDuration: 0.5) {
            self.view.layoutIfNeeded()
        }
    }
    
}

extension ComposerUIView: RichEditorDelegate {
    func richEditorDidLoad(_ editor: RichEditorView) {
        
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
        
        if input.contains(",") || input.contains(" ") {
            let name = input.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " ", with: "")
            
            guard name.contains("@") else {
                let valueObject = NSString(string: "\(name)\(Env.domain)")
                let token = CLToken(displayText: "\(name)\(Env.domain)", context: valueObject)
                view.add(token)
                return
            }
            let valueObject = NSString(string: name)
            let token = CLToken(displayText: name, context: valueObject)
            view.add(token)
        }
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
}
