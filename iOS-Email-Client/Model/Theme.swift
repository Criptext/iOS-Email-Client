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
    let composeButton: UIColor
    let cellOpaque: UIColor
    let sectionHeader: UIColor
    let underSelector: UIColor
    let placeholder: UIColor
    let popoverButton: UIColor
    let loader: UIColor
    let icon: UIColor
    let highlight: UIColor
    let separator: UIColor
    let attachment: UIColor
    
    init(name: String = "Default", main: UIColor = .mainUI, toolbar: UIColor = .charcoal, background: UIColor = .white, popoupBackground: UIColor = .lightIcon, mainText: UIColor = .charcoal, secondText: UIColor = .bright, alert: UIColor = .alert, composeButton: UIColor = .mainUI, cellOpaque: UIColor = .opaque, sectionHeader: UIColor = .opaque, underSelector: UIColor = .mainUI, placeholder: UIColor = .placeholderLight, popoverButton: UIColor = .popoverButton, loader: UIColor = .gray, icon: UIColor = .lightIcon, highlight: UIColor = .itemSelected, separator: UIColor = .separator, attachment: UIColor = .opaque) {
        self.name = name
        self.main = main
        self.toolbar = toolbar
        self.background = background
        self.popoupBackground = popoupBackground
        self.mainText = mainText
        self.secondText = secondText
        self.alert = alert
        self.composeButton = composeButton
        self.cellOpaque = cellOpaque
        self.sectionHeader = sectionHeader
        self.underSelector = underSelector
        self.placeholder = placeholder
        self.popoverButton = popoverButton
        self.loader = loader
        self.icon = icon
        self.highlight = highlight
        self.separator = separator
        self.attachment = attachment
    }
    
    class func dark() -> Theme {
        return Theme(name: "Night", main: .charcoal, toolbar: .black, background: .charcoal, popoupBackground: .charcoal, mainText: .white, secondText: .bright, alert: .alert, composeButton: .composeButton, cellOpaque: .composeButton, sectionHeader: .black, underSelector: .white, placeholder: .placeholderDark, popoverButton: .composeButton, loader: .white, icon: .lightIcon, highlight: .bright, separator: .composeButton, attachment: .composeButton)
    }
}
