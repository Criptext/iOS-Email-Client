
//
//  SettingsDeviceTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

protocol DeviceTableViewCellDelegate {
    func tableViewCellDidLongPress(_ cell: SettingsDeviceTableViewCell)
}

class SettingsDeviceTableViewCell: UITableViewCell {
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceLocationLabel: UILabel!
    @IBOutlet weak var currentDeviceLabel: UILabel!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var checkBox: CheckMarkUIView!
    var delegate: DeviceTableViewCellDelegate?
    private var longPressGesture:UILongPressGestureRecognizer?
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        longPressGestureSetup()
        applyTheme()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        applyTheme()
    }
    
    func applyTheme() {
        trashButton.tintColor = theme.secondText
        deviceNameLabel.textColor = theme.mainText
        deviceLocationLabel.textColor = theme.mainText
        self.tintColor = theme.criptextBlue
        let selectedView = UIView()
        selectedView.backgroundColor = theme.cellHighlight
        self.selectedBackgroundView = selectedView
        backgroundColor = .clear
    }
    
    func longPressGestureSetup(){
        let longPressGesture:UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.onCellLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0
        self.longPressGesture = longPressGesture
    }
    
    func setContent(device: Device){
        deviceImageView.image = (Device.Kind(rawValue: device.type) ?? .pc) != .pc ? #imageLiteral(resourceName: "device-mobile") : #imageLiteral(resourceName: "device-desktop")
        deviceNameLabel.text = device.friendlyName
        if(device.isFromLogin){
            self.trashButton.isHidden = true
            self.currentDeviceLabel.isHidden = true
            self.addGestureRecognizer(self.longPressGesture!)
        } else {
            displayAsActive(device.active)
            guard !device.active else {
                return
            }
        }
        let attrString = NSMutableAttributedString(string: String.localize("DEVICE_LAST_ACTIVE"), attributes: [NSAttributedString.Key.font: Font.bold.size(12.0)!])
        guard let date = device.lastActivity else {
            attrString.append(NSAttributedString(string: String.localize("DEVICE_OVER_2_MONTHS"), attributes: [NSAttributedString.Key.font: Font.regular.size(12.0)!]))
            deviceLocationLabel.attributedText = attrString
            return
        }
        attrString.append(NSAttributedString(string: " \(String(DateUtils.beautyDate(date)!).replacingOccurrences(of: "at ", with: ""))", attributes: [NSAttributedString.Key.font: Font.regular.size(12.0)!]))
        deviceLocationLabel.attributedText = attrString
    }
    
    func displayAsActive(_ active: Bool){
        deviceLocationLabel.isHidden = active
        currentDeviceLabel.isHidden = !active
        trashButton.isHidden = active
    }
    
    @objc func onCellLongPress(_ sender: Any){
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidLongPress(self)
    }
    
    @IBAction func onTrashPress(_ sender: Any) {
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidLongPress(self)
    }
}
