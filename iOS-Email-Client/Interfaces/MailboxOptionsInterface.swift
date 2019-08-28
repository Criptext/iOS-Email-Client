//
//  MailboxOptionsInterface.swift
//  iOS-Email-Client
//
//  Created by Allisson on 8/28/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol MailboxOptionsInterfaceDelegate: class {
    func onMoveToPress()
    func onAddLabesPress()
    func onArchivePress()
    func onRestorePress()
    func onClose()
}

class MailboxOptionsInterface: MoreOptionsViewInterface {
    internal enum Option {
        case moveTo
        case addLabels
        case archive
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
            case .restoreSpam:
                return String.localize("REMOVE_SPAM")
            case .recoverTrash:
                return String.localize("RECOVER_TRASH")
            }
        }
    }
    
    var optionsCount: Int
    var options: [Option]
    var delegate: MailboxOptionsInterfaceDelegate?
    
    init(currentLabel: Int) {
        switch currentLabel {
        case SystemLabel.draft.id:
            options = []
            optionsCount = 0
        case SystemLabel.spam.id:
            options = [.addLabels, .restoreSpam]
            optionsCount = 2
        case SystemLabel.trash.id:
            options = [.addLabels, .recoverTrash]
            optionsCount = 2
        case SystemLabel.all.id:
            options = [.moveTo]
            optionsCount = 1
        default:
            options = [.moveTo, .addLabels, .archive]
            optionsCount = 3
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
        switch label {
        case SystemLabel.draft.id:
            options = []
            optionsCount = 0
        case SystemLabel.spam.id:
            options = [.addLabels, .restoreSpam]
            optionsCount = 2
        case SystemLabel.trash.id:
            options = [.addLabels, .recoverTrash]
            optionsCount = 2
        case SystemLabel.all.id:
            options = [.moveTo]
            optionsCount = 1
        default:
            options = [.moveTo, .addLabels, .archive]
            optionsCount = 3
        }
    }
}
