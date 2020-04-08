//
//  RichEditorWrapperView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 4/8/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import RichEditorView

class RichEditorWrapperView: RichEditorView {
    public var lastFocus: CGPoint?
    public var tap: UITapGestureRecognizer!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    public func configure() {
        tap = super.gestureRecognizers![0] as? UITapGestureRecognizer
        tap.addTarget(self, action: #selector(wasTapped))
        tap.delegate = self
        addGestureRecognizer(tap)
    }
    
    @objc private func wasTapped() {
        lastFocus = tap.location(in: super.webView)
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            guard let focusPoint = self.lastFocus else {
                return
            }
            self.focus(at: focusPoint)
        }
    }
}
