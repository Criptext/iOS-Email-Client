
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

class SettingsDeviceTableViewCell: TableViewCell {
    @IBOutlet weak var deviceImageView: UIImageView!
    @IBOutlet weak var deviceNameLabel: UILabel!
    @IBOutlet weak var deviceLocationLabel: UILabel!
    @IBOutlet weak var currentDeviceLabel: UILabel!
    var delegate: DeviceTableViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        let hold = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        self.addGestureRecognizer(hold)
        self.pulseAnimation = .pointWithBacking
    }
    
    @objc func handleLongPress(_ gestureRecognizer:UILongPressGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidLongPress(self)
    }
}
