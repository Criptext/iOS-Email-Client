//
//  EmailMoreOptionsInterface.swift
//  iOS-Email-Client
//
//  Created by Pedro Iñiguez on 8/28/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol EmailMoreOptionsInterfaceDelegate: class {
    func onReplyPress()
    func onReplyAllPress()
    func onForwardPress()
    func onDeletePress()
    func onMarkPress()
    func onSpamPress()
    func onUnsendPress()
    func onPrintPress()
    func onRetryPress()
    func onShowSourcePress()
    func onClose()
}

class EmailMoreOptionsInterface: MoreOptionsViewInterface {
    internal enum Option {
        case reply
        case replyAll
        case forward
        case delete
        case mark
        case notSpam
        case spam
        case unsend
        case print
        case retry
        case showSource
        
        var description: String {
            switch self {
            case .reply:
                return String.localize("REPLY")
            case .replyAll:
                return String.localize("REPLY_ALL")
            case .forward:
                return String.localize("FORWARD")
            case .delete:
                return String.localize("DELETE")
            case .mark:
                return String.localize("MARK_FROM_HERE")
            case .notSpam:
                return String.localize("REMOVE_SPAM")
            case .spam:
                return String.localize("MARK_SPAM")
            case .unsend:
                return String.localize("UNSEND")
            case .print:
                return String.localize("PRINT")
            case .retry:
                return String.localize("RETRY")
            case .showSource:
                return String.localize("SHOW_SOURCE")
            }
        }
    }
    
    var optionsCount: Int
    var options: [Option]
    var delegate: EmailMoreOptionsInterfaceDelegate?
    
    init(email: Email) {
        options = [.reply, .replyAll, .forward, .delete, .mark]
        optionsCount = options.count
        if (email.isSpam) {
            options.append(.notSpam)
            optionsCount += 1
        } else {
            options.append(.spam)
            optionsCount += 1
        }
        if (email.secure && email.status != .unsent && email.status != .none && email.status != .sending && email.status != .fail) {
            options.append(.unsend)
            optionsCount += 1
        }
        if (email.status == .fail || email.status == .sending) {
            options.append(.retry)
            optionsCount += 1
        }
        if (!email.boundary.isEmpty) {
            options.append(.showSource)
            optionsCount += 1
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
        case .reply:
            delegate?.onReplyPress()
        case .replyAll:
            delegate?.onReplyAllPress()
        case .forward:
            delegate?.onForwardPress()
        case .delete:
            delegate?.onDeletePress()
        case .mark:
            delegate?.onMarkPress()
        case .notSpam:
            delegate?.onSpamPress()
        case .spam:
            delegate?.onSpamPress()
        case .unsend:
            delegate?.onUnsendPress()
        case .print:
            delegate?.onPrintPress()
        case .retry:
            delegate?.onRetryPress()
        case .showSource:
            delegate?.onShowSourcePress()
        }
    }
    
    func onClose() {
        delegate?.onClose()
    }
    
    func changeOptions(label: Int) {
        
    }
}
