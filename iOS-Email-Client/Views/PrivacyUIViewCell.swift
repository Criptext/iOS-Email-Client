//
//  PrivacyUIViewCell.swift
//  iOS-Email-Client
//
//  Created by Allisson on 12/6/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class PrivacyUIViewCell: UITableViewCell {
    var switchToggle: ((Bool) -> Void)?
    var didTap: (() -> Void)?
    @IBOutlet weak var detailContainerView: UIView!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var optionSwitch: UISwitch!
    @IBOutlet weak var optionNextImage: UIImageView!
    @IBOutlet weak var optionTextLabel: UILabel!
    @IBOutlet weak var optionPickLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        optionSwitch.transform = CGAffineTransform(scaleX: 0.67, y: 0.67)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    func fillFields(option: SecurityPrivacyViewController.PrivacyOption) {
        detailContainerView.isHidden = option.detail == nil
        detailLabel.text = option.detail
        optionNextImage.isHidden = !option.hasFlow
        optionSwitch.isHidden = option.isOn == nil
        optionSwitch.isOn = option.isOn ?? false
        optionTextLabel.text = option.label.rawValue
        optionPickLabel.isHidden = option.pick == nil
        optionPickLabel.text = option.pick
        if option.isEnabled {
            optionTextLabel.textColor = .lightText
            optionPickLabel.textColor = .mainUI
            optionSwitch.isEnabled = true
        } else {
            optionTextLabel.textColor = .bright
            optionPickLabel.textColor = .bright
            optionSwitch.isEnabled = false
        }
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        let touchPt = gestureRecognizer.location(in: self.contentView)
        guard optionSwitch.isEnabled,
            let toggle = switchToggle,
            let tappedView = self.hitTest(touchPt, with: nil),
            tappedView != detailContainerView,
            tappedView != optionSwitch else {
                didTap?()
                return
        }
        let isOn = !optionSwitch.isOn
        optionSwitch.setOn(isOn, animated: true)
        toggle(isOn)
    }
    
    @IBAction func onSwitchToggle(_ sender: Any) {
        switchToggle?(optionSwitch.isOn)
    }
}
