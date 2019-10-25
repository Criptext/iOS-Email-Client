//
//  LabelsLabelTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol LabelTableViewCellDelegate: class {
    func tableViewCellDidTapCheck(_ cell: LabelsLabelTableViewCell)
}

class LabelsLabelTableViewCell: UITableViewCell{
    @IBOutlet weak var checkMarkView: CheckMarkUIView!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var labelLabel: UILabel!
    @IBOutlet weak var colorDotsContainer: UIView!
    @IBOutlet weak var colorDotsView: UIView!
    
    weak var delegate: LabelTableViewCellDelegate?
    
    var clickTrash: (() -> Void)? = nil
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        checkMarkView.addGestureRecognizer(tap)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
    
    func applyTheme() {
        labelLabel.textColor = theme.mainText
        backgroundColor = .clear
    }
    
    func fillFields(label: Label) {
        let isDisabled = label.id == SystemLabel.starred.id
        trashButton.isHidden = isDisabled
        labelLabel.text = label.localized
        checkMarkView.setChecked(label.visible, disabled: isDisabled)
        colorDotsView.backgroundColor = UIColor(hex: label.color)
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidTapCheck(self)
    }
    
    @IBAction func didTapButton(sender: UIButton) {
        clickTrash?()
    }
}
