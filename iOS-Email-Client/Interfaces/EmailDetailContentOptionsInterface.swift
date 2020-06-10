//
//  EmailDetailContentOptionsInterface.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 5/5/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

protocol EmailContentOptionsDelegate: class {
    func onOncePress()
    func onAlwaysPress()
    func onDisablePress()
    func onContentOptionsClose()
}

class EmailDetailContentOptionsInterface: MoreOptionsViewInterface {
    enum Option {
        case once
        case always
        case disable
        
        var description: String {
            switch self {
            case .once:
                return String.localize("CONTENT_BLOCK_ONCE")
            case .always:
                return String.localize("CONTENT_BLOCK_ALWAYS")
            case .disable:
                return String.localize("CONTENT_BLOCK_TURN_OFF")
            }
        }
    }
    
    var optionsCount: Int
    var options: [Option]
    var delegate: EmailContentOptionsDelegate?
    
    init() {
        options = [.once, .always, .disable]
        optionsCount = options.count
    }
    
    init(options: [Option]) {
        self.options = options
        optionsCount = options.count
    }
    
    func handleOptionCell(cell: AccountFromCell, index: Int) {
        if index >= optionsCount {
            return
        }
        let option = options[index]
        cell.emailLabel.text = option.description
    }
    
    func handleOptionSelected(index: Int) {
        if index > optionsCount - 1 {
            return
        }
        let option = options[index]
        switch option {
        case .once:
            delegate?.onOncePress()
        case .always:
            delegate?.onAlwaysPress()
        case .disable:
            delegate?.onDisablePress()
        }
    }
    
    func changeOptions(label: Int) {
        
    }
    
    func onClose() {
        delegate?.onContentOptionsClose()
    }
}
