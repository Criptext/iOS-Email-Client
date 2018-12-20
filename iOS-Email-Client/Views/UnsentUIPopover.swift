//
//  UnsentUIPop.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class UnsentUIPopover: BaseUIPopover{
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    var date: String?
    
    init() {
        super.init("UnsentUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dateLabel.text = date
        applyTheme()
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        titleLabel.textColor = theme.mainText
        dateLabel.textColor = theme.mainText
    }
}
