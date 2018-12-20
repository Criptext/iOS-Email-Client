//
//  ThemeManager.swift
//  iOS-Email-Client
//
//  Created by Allisson on 12/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol ThemeDelegate: class {
    func swapTheme(_ theme: Theme)
}

final class ThemeManager: NSObject {
    static let shared = ThemeManager()
    var theme: Theme
    private var delegates = [String: ThemeDelegate]()
    
    private override init() {
        self.theme = Theme.dark()
        super.init()
    }
    
    func swapTheme(theme: Theme) {
        self.theme = theme
        for (_, delegate) in delegates {
            delegate.swapTheme(theme)
        }
    }
    
    func addListener(id: String, delegate: ThemeDelegate) {
        delegates[id] = delegate
    }
    
    func removeListener(id: String) {
        delegates[id] = nil
    }
}
