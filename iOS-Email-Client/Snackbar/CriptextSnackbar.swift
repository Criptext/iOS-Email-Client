//
//  CriptextSnackBar.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/11/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class CriptextSnackbar: Snackbar {
    internal(set) var bottomPadding: CGFloat = 0.0
    
    override var text: String? {
        get {
            return customLabel.text
        }
        set(value) {
            customLabel.text = value
            layoutSubviews()
        }
    }
    
    override var attributedText: NSAttributedString? {
        get {
            return customLabel.attributedText
        }
        set(value) {
            customLabel.attributedText = value
            layoutSubviews()
        }
    }
    
    open let customLabel = PaddingUILabel()
    open internal(set) var myStatus = SnackbarStatus.hidden
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: 49 + bottomPadding)
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for v in subviews {
            let p = v.convert(point, from: self)
            if v.bounds.contains(p) {
                return v.hitTest(p, with: event)
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard willLayout else {
            return
        }
        
        centerViews = [customLabel]
    }
    
    override func prepare() {
        super.prepare()
        depthPreset = .none
        interimSpacePreset = .interimSpace8
        contentEdgeInsets.left = interimSpace
        contentEdgeInsets.right = interimSpace
        backgroundColor = Color.grey.darken3
        clipsToBounds = false
        prepareTextLabel()
    }
    
    private func prepareTextLabel() {
        customLabel.bottomTextInset = bottomPadding
        customLabel.contentScaleFactor = Screen.scale
        customLabel.font = RobotoFont.medium(with: 14)
        customLabel.textAlignment = .left
        customLabel.textColor = .white
        customLabel.numberOfLines = 0
    }
    
    func setBottomPadding(padding: CGFloat){
        frame = CGRect(x: frame.center.x, y: frame.center.y, width: frame.width, height: frame.height + padding)
        bottomPadding = padding
        prepareTextLabel()
        layoutIfNeeded()
    }
}
