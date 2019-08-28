//
//  MoreOptionsInterface.swift
//  iOS-Email-Client
//
//  Created by Allisson on 8/27/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol EmailDetailOptionsInterfaceDelegate: class {
    func onMoveToPress()
    func onAddLabesPress()
    func onArchivePress()
    func onRestorePress()
    func onPrintAllPress()
    func onClose()
}

class EmailDetailOptionsInterface: MoreOptionsViewInterface {
    internal enum Option {
        case moveTo
        case addLabels
        case archive
        case printAll
        case restoreSpam
        case recoverTrash
        
        var description: String {
            switch self {
            case .moveTo:
                return String.localize("MOVE_TO")
            case .addLabels:
                return String.localize("ADD_LABELS")
            case .archive:
                return String.localize("ARCHIVE")
            case .printAll:
                return String.localize("PRINT_ALL")
            case .restoreSpam:
                return String.localize("REMOVE_SPAM")
            case .recoverTrash:
                return String.localize("RECOVER_TRASH")
            }
        }
    }
    
    var optionsCount: Int
    var options: [Option]
    var delegate: EmailDetailOptionsInterfaceDelegate?
    
    init(currentLabel: Int) {
        switch currentLabel {
        case SystemLabel.draft.id:
            options = []
            optionsCount = 0
        case SystemLabel.spam.id:
            options = [.addLabels, .restoreSpam, .printAll]
            optionsCount = 3
        case SystemLabel.trash.id:
            options = [.addLabels, .recoverTrash, .printAll]
            optionsCount = 3
        case SystemLabel.all.id:
            options = [.moveTo, .printAll]
            optionsCount = 2
        default:
            options = [.moveTo, .addLabels, .archive, .printAll]
            optionsCount = 4
        }
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
        case .moveTo:
            delegate?.onMoveToPress()
        case .addLabels:
            delegate?.onAddLabesPress()
        case .archive:
            delegate?.onArchivePress()
        case .printAll:
            delegate?.onPrintAllPress()
        case .restoreSpam:
            delegate?.onRestorePress()
        case .recoverTrash:
            delegate?.onRestorePress()
        }
    }
    
    func onClose() {
        delegate?.onClose()
    }
    
    func changeOptions(label: Int) {
        
    }
}
