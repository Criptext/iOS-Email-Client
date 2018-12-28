//
//  Theme.swift
//  iOS-Email-Client
//
//  Created by Allisson on 12/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class Theme {
    let name: String
    let main: UIColor
    let toolbar: UIColor
    let background: UIColor
    let popoupBackground: UIColor
    let mainText: UIColor
    let secondText: UIColor
    let alert: UIColor
    let criptextBlue: UIColor
    let secondBackground: UIColor
    let sectionHeader: UIColor
    let underSelector: UIColor
    let placeholder: UIColor
    let popoverButton: UIColor
    let loader: UIColor
    let icon: UIColor
    let highlight: UIColor
    let separator: UIColor
    let attachment: UIColor
    let cellHighlight: UIColor
    let menuBackground: UIColor
    let menuItem: UIColor
    let menuText: UIColor
    let menuHeader: UIColor
    let markedText: UIColor
    let overallBackground: UIColor
    let attachmentCell: UIColor
    let attachmentBorder: UIColor
    let emailBorder: UIColor
    let threadBadge: UIColor
    let settingsDetail: UIColor
    let emailBubble: UIColor
    let emailBubbleCriptext: UIColor
    let bgBubble: UIColor
    let bgBubbleCriptext: UIColor
    let composerMenu: UIColor
    
    init(name: String = "Default", main: UIColor = .mainUI, toolbar: UIColor = .charcoal, background: UIColor = .strongOpaque, popoupBackground: UIColor = .lightIcon, mainText: UIColor = .charcoal, secondText: UIColor = .defaultSecondary, alert: UIColor = .alert, criptextBlue: UIColor = .mainUI, secondBackground: UIColor = .white, sectionHeader: UIColor = .opaque, underSelector: UIColor = .mainUI, placeholder: UIColor = .placeholderLight, popoverButton: UIColor = .popoverButton, loader: UIColor = .gray, icon: UIColor = .lightIcon, highlight: UIColor = .itemSelected, separator: UIColor = .separator, attachment: UIColor = .opaque, cellHighlight: UIColor = .cellHighlight, menuBackground: UIColor = .white, menuItem: UIColor = .disableIcon, menuHeader: UIColor = .strongOpaque, markedText: UIColor = .black, overallBackground: UIColor = .white, attachmentCell: UIColor = .attachmentCell, attachmentBorder: UIColor = .attachmentBorder, emailBorder: UIColor = .emailBorder, threadBadge: UIColor = .threadBadge, settingsDetail: UIColor = .opaque, emailBubble: UIColor = .emailBubble, emailBubbleCriptext: UIColor = .mainUI, bgBubble: UIColor = .bgBubble, bgBubbleCriptext: UIColor = .bgBubbleCriptext, composerMenu: UIColor = .mainUI, menuText: UIColor = .charcoal) {
        self.name = name
        self.main = main
        self.toolbar = toolbar
        self.background = background
        self.popoupBackground = popoupBackground
        self.mainText = mainText
        self.secondText = secondText
        self.alert = alert
        self.criptextBlue = criptextBlue
        self.secondBackground = secondBackground
        self.sectionHeader = sectionHeader
        self.underSelector = underSelector
        self.placeholder = placeholder
        self.popoverButton = popoverButton
        self.loader = loader
        self.icon = icon
        self.highlight = highlight
        self.separator = separator
        self.attachment = attachment
        self.cellHighlight = cellHighlight
        self.menuBackground = menuBackground
        self.markedText = markedText
        self.menuHeader = menuHeader
        self.overallBackground = overallBackground
        self.attachmentCell = attachmentCell
        self.attachmentBorder = attachmentBorder
        self.threadBadge = threadBadge
        self.settingsDetail = settingsDetail
        self.emailBorder = emailBorder
        self.menuItem = menuItem
        self.emailBubble = emailBubble
        self.emailBubbleCriptext = emailBubbleCriptext
        self.bgBubbleCriptext = bgBubbleCriptext
        self.bgBubble = bgBubble
        self.composerMenu = composerMenu
        self.menuText = menuText
    }
    
    class func dark() -> Theme {
        return Theme(name: "Dark", main: .charcoal, toolbar: .black, background: .darkBG, popoupBackground: .charcoal, mainText: .strongText, secondText: .darkSecondary, alert: .alert, criptextBlue: .darkUI, secondBackground: .darkOpaque, sectionHeader: .darkOpaque, underSelector: .white, placeholder: .placeholderDark, popoverButton: .charcoal, loader: .white, icon: .lightIcon, highlight: .darkSelected, separator: .darkSeparator, attachment: .darkBadge, cellHighlight: .darkCellHighlight, menuBackground: .darkOpaque, menuItem: .darkMenuText, menuHeader: .darkBG, markedText: .white, overallBackground: .darkBG, attachmentCell: .darkBadge, attachmentBorder: .darkBadge, emailBorder: .darkEmailBorder, threadBadge: .darkBadge, settingsDetail: .darkDetail, emailBubble: .white, emailBubbleCriptext: .darkEmailBubble, bgBubble: .darkBgBubble, bgBubbleCriptext: .darkBgBubbleCriptext, composerMenu: .white, menuText: .darkMenuText)
    }
}
