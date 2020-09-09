//
//  EmailMoreOptionsInterface.swift
//  iOS-Email-Client
//
//  Created by Pedro Iñiguez on 8/28/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol EmailMoreOptionsInterfaceDelegate: class {
    func onTurnOnLightsPressed()
    func onReplyPress()
    func onReplyAllPress()
    func onForwardPress()
    func onDeletePress()
    func onMarkPress()
    func onSpamPress()
    func onPhishingPress()
    func onUnsendPress()
    func onPrintPress()
    func onRetryPress()
    func onShowSourcePress()
    func onClose()
}

class EmailMoreOptionsInterface: MoreOptionsViewInterface {
    internal enum Option {
        case turnOnLights
        case turnOffLights
        case reply
        case replyAll
        case forward
        case delete
        case mark
        case notSpam
        case spam
        case phishing
        case unsend
        case print
        case retry
        case showSource
        
        var description: String {
            get {
                switch self {
                case .turnOnLights:
                    return String.localize("TURN_ON_LIGHTS")
                case .turnOffLights:
                    return String.localize("TURN_OFF_LIGHTS")
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
                case .phishing:
                    return String.localize("REPORT_PHISHING")
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
    }
    
    var optionsCount: Int
    var options: [Option]
    var delegate: EmailMoreOptionsInterfaceDelegate?
    
    init(email: Email, state: Email.State) {
        let theme = ThemeManager.shared.theme
        let turnLightsOption: Option = state.hasTurnedOnLights ?? false ? .turnOffLights : .turnOnLights
        options = theme.name == "Dark" ? [turnLightsOption, .reply, .replyAll, .forward, .delete, .mark] : [.reply, .replyAll, .forward, .delete, .mark]
        optionsCount = options.count
        if (email.isSpam) {
            options.append(.notSpam)
            optionsCount += 1
        } else {
            options.append(.spam)
            options.append(.phishing)
            optionsCount += 2
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
        case .turnOnLights, .turnOffLights:
            delegate?.onTurnOnLightsPressed()
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
        case .phishing:
            delegate?.onPhishingPress()
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
