//
//  DeviceLimitTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/28/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

protocol DeviceLimitTableViewCellDelegate: class {
    func onRemoveDevice(deviceId: Int)
}

class DeviceLimitTableViewCell: UITableViewCell {
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var activityLabel: UILabel!
    
    weak var delegate: DeviceLimitTableViewCellDelegate?
    var deviceId = 0
    
    @IBAction func onDeletePress(_ sender: Any) {
        delegate?.onRemoveDevice(deviceId: deviceId)
    }
    
    func setContent(device: Device) {
        deviceId = device.id
        deviceImageView.image = (Device.Kind(rawValue: device.type) ?? .pc) != .pc ? #imageLiteral(resourceName: "device-mobile") : #imageLiteral(resourceName: "device-desktop")
        nameLabel.text = device.friendlyName

        let attrString = NSMutableAttributedString(string: String.localize("DEVICE_LAST_ACTIVE"), attributes: [NSAttributedString.Key.font: Font.bold.size(12.0)!])
        guard let date = device.lastActivity else {
            attrString.append(NSAttributedString(string: String.localize("DEVICE_OVER_2_MONTHS"), attributes: [NSAttributedString.Key.font: Font.regular.size(12.0)!]))
            activityLabel.attributedText = attrString
            return
        }
        attrString.append(NSAttributedString(string: " \(String(DateUtils.beautyDate(date)!).replacingOccurrences(of: "at ", with: ""))", attributes: [NSAttributedString.Key.font: Font.regular.size(12.0)!]))
        activityLabel.attributedText = attrString
    }
}
