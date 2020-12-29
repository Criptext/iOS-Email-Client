//
//  CustomWebview.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 12/28/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

protocol WebviewToolbarDelegate: class {
    func onBoldPress()
    func onItalicPress()
    func onTextAlignLeft()
    func onTextAlignRight()
    func onTextAlignCenter()
    func onIndentPress()
    func onOutdentPress()
    func onClearPress()
    func onUndoPress()
    func onRedoPress()
}

class CustomWebview: WKWebView {
    
    enum Modifier {
        case bold
        case italic
        case textAlignLeft
        case textAlignCenter
        case textAlignRight
        case indent
        case outdent
        case clear
        case undo
        case redo
        
        var desc: String {
            switch(self) {
            case .bold:
                return "Bold"
            case .italic:
                return "Italic"
            case .textAlignLeft:
                return "Left"
            case .textAlignCenter:
                return "Center"
            case .textAlignRight:
                return "Right"
            case .indent:
                return "Indent"
            case .outdent:
                return "Outdent"
            case .clear:
                return "Clear"
            case .undo:
                return "Undo"
            case .redo:
                return "Redo"
            }
        }
        
        var image: UIImage {
            switch(self) {
            case .bold:
                return UIImage(named: "bold")!
            case .italic:
                return UIImage(named: "italic")!
            case .textAlignLeft:
                return UIImage(named: "alignLeft")!
            case .textAlignCenter:
                return UIImage(named: "alignCenter")!
            case .textAlignRight:
                return UIImage(named: "alignRight")!
            case .indent:
                return UIImage(named: "indent")!
            case .outdent:
                return UIImage(named: "outdent")!
            case .clear:
                return UIImage(named: "clear")!
            case .undo:
                return UIImage(named: "undo")!
            case .redo:
                return UIImage(named: "redo")!
            }
        }
    }
    weak var toolbarDelegate: WebviewToolbarDelegate? = nil
    var enableAccessoryView = true
    var accessoryView: UIView? = nil
    var modifiers: [Modifier] = [.bold, .italic, .textAlignRight, .textAlignCenter, .textAlignLeft, .indent, .outdent, .clear, .undo, .redo]
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override var inputAccessoryView: UIView? {
        get {
            if enableAccessoryView,
               accessoryView == nil {
                let layout = UICollectionViewFlowLayout()
                layout.scrollDirection = .horizontal
                
                let collectionView = UICollectionView(frame: CGRect(x: 0, y: 0, width: 100, height: 50), collectionViewLayout: layout)
                collectionView.backgroundColor = theme.background
                collectionView.dataSource = self
                collectionView.delegate = self
                collectionView.isScrollEnabled = true
                collectionView.bounces = false
                collectionView.showsHorizontalScrollIndicator = false
                
                let accessoryNib = UINib(nibName: "AccessoryUICollectionViewCell", bundle: nil)
                collectionView.register(accessoryNib, forCellWithReuseIdentifier: "accessoryCell")
                
                accessoryView = collectionView
            }
            return accessoryView
        }
        set {
            accessoryView = newValue
        }
    }
}

extension CustomWebview: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return modifiers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let modifier = modifiers[indexPath.item]

        let collectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: "accessoryCell", for: indexPath) as! AccessoryUICollectionViewCell
        collectionCell.iconImageView.image = modifier.image
        return collectionCell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 40, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let modifier = modifiers[indexPath.item]
        switch modifier {
        case .bold:
            self.toolbarDelegate?.onBoldPress()
        case .italic:
            self.toolbarDelegate?.onItalicPress()
        case .textAlignLeft:
            self.toolbarDelegate?.onTextAlignLeft()
        case .textAlignRight:
            self.toolbarDelegate?.onTextAlignRight()
        case .textAlignCenter:
            self.toolbarDelegate?.onTextAlignCenter()
        case .indent:
            self.toolbarDelegate?.onIndentPress()
        case .outdent:
            self.toolbarDelegate?.onOutdentPress()
        case .clear:
            self.toolbarDelegate?.onClearPress()
        case .undo:
            self.toolbarDelegate?.onUndoPress()
        case .redo:
            self.toolbarDelegate?.onRedoPress()
        }
    }
}
