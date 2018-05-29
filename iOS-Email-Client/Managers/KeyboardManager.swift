//
//  KeyboardHandler.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RichEditorView

class KeyboardManager: NSObject{
    
    weak var view: UIView?
    var toolbar: RichEditorToolbar
    
    init(view: UIView) {
        self.view = view
        toolbar = RichEditorToolbar(frame: CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: 44))
        toolbar.options = [.bold, .italic, .header(1), .header(2), .header(3), .header(4), .header(5), .alignLeft, .alignCenter, .alignRight, .indent, .outdent, .undo, .redo] as [RichEditorDefaultOption]
    }

    func beginMonitoring() {
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardManager.keyboardWillShowOrHide(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardManager.keyboardWillShowOrHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    @objc func keyboardWillShowOrHide(_ notification: Notification) {
        
        let info = (notification as NSNotification).userInfo ?? [:]
        let duration = TimeInterval((info[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.floatValue ?? 0.25)
        let curve = UInt((info[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0)
        let options = UIViewAnimationOptions(rawValue: curve)
        let keyboardRect = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        
        
        if notification.name == NSNotification.Name.UIKeyboardWillShow {
            self.view?.addSubview(self.toolbar)
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                if let view = self.view {
                    self.toolbar.frame.origin.y = view.frame.height - (keyboardRect.height + self.toolbar.frame.height)
                }
            }, completion: nil)
            
            
        } else if notification.name == NSNotification.Name.UIKeyboardWillHide {
            UIView.animate(withDuration: duration, delay: 0, options: options, animations: {
                if let view = self.view {
                    self.toolbar.frame.origin.y = view.frame.height
                }
            }, completion: nil)
        }
    }
    
}
