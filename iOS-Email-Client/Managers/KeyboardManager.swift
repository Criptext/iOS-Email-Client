//
//  KeyboardHandler.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class KeyboardManager: NSObject{
    
    weak var view: UIView?
    //var toolbar: RichEditorToolbar
    
    init(view: UIView) {
        self.view = view
        //toolbar = RichEditorToolbar(frame: CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: 44))
        //toolbar.options = [.bold, .italic, .header(1), .header(2), .header(3), .header(4), .header(5), .alignLeft, .alignCenter, .alignRight, .indent, .outdent, .undo, .redo] as [RichEditorDefaultOption]
    }

    func beginMonitoring() {
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardManager.keyboardWillShowOrHide(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(KeyboardManager.keyboardWillShowOrHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func stopMonitoring() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShowOrHide(_ notification: Notification) {
        
        let info = (notification as NSNotification).userInfo ?? [:]
        let duration = TimeInterval((info[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.floatValue ?? 0.25)
        let curve = UInt((info[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0)
        let options = UIView.AnimationOptions(rawValue: curve)
        let keyboardRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        
    }
    
}
