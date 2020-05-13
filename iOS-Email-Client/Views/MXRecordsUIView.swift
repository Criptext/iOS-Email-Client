//
//  MXRecordsUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 3/20/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class MXRecordsUIView: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet weak var typeHeaderLabel: UILabel!
    @IBOutlet weak var priorityHeaderLabel: UILabel!
    @IBOutlet weak var hostHeaderlabel: UILabel!
    @IBOutlet weak var valueHeaderLabel: UILabel!
    
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var priorityLabel: UILabel!
    @IBOutlet weak var hostlabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    @IBOutlet weak var copyButton: UIButton!
    var onCopy: ((String) -> Void)?
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "MXRecordsUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        layer.borderColor = theme.emailBorder.cgColor
        layer.borderWidth = 1.0
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        typeHeaderLabel.textColor = theme.markedText
        priorityHeaderLabel.textColor = theme.markedText
        hostHeaderlabel.textColor = theme.markedText
        valueHeaderLabel.textColor = theme.markedText
        
        typeHeaderLabel.backgroundColor = theme.sectionHeader
        priorityHeaderLabel.backgroundColor = theme.sectionHeader
        hostHeaderlabel.backgroundColor = theme.sectionHeader
        valueHeaderLabel.backgroundColor = theme.sectionHeader
        
        typeLabel.textColor = theme.mainText
        priorityLabel.textColor = theme.mainText
        hostlabel.textColor = theme.mainText
        valueLabel.textColor = theme.mainText
        
        copyButton.setTitleColor(theme.criptextBlue, for: .normal)
        view.backgroundColor = theme.overallBackground
    }
    
    func setLabels(type: String, priority: String, host: String, value: String) {
        typeLabel.text = type
        priorityLabel.text = priority
        hostlabel.text = host
        valueLabel.text = value
    }
    
    @IBAction func onCopyTouchUp(_ sender: Any) {
        guard let copyText = valueLabel.text else {
            return
        }
        onCopy?(copyText)
    }
}
