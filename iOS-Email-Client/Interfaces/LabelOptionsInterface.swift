//
//  LabelOptionsInterface.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 10/31/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol LabelOptionsInterfaceDelegate: class {
    func onEditPress()
    func onDeletePress()
    func onClose()
}

class LabelOptionsInterface: MoreOptionsViewInterface {
    internal enum Option {
        case edit
        case delete
        
        var description: String {
            switch self {
            case .edit:
                return String.localize("EDIT")
            case .delete:
                return String.localize("DELETE")
            }
        }
    }
    
    var optionsCount: Int
    var options: [Option]
    var delegate: LabelOptionsInterfaceDelegate?
    
    init(label: Label) {
        options = [.edit, .delete]
        optionsCount = options.count
    }
    
    func handleOptionCell(cell: AccountFromCell, index: Int) {
        if index > optionsCount - 1 {
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
        case .edit:
            delegate?.onEditPress()
        case .delete:
            delegate?.onDeletePress()
        }
    }
    
    func onClose() {
        delegate?.onClose()
    }
    
    func changeOptions(label: Int) {
        
    }
}
