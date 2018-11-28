//
//  MailboxNewsHeaderUITableCell.swift
//  iOS-Email-Client
//
//  Created by Pedro on 11/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SDWebImage

class MailboxNewsHeaderUITableCell: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var newsImageView: UIImageView!
    var feature: MailboxData.Feature!
    var onClose: (() -> Void)?
    
    @IBAction func onClosePress(_ sender: Any) {
        onClose?()
    }
    
    func fillFields(feature: MailboxData.Feature) {
        titleLabel.text = feature.title
        subtitleLabel.text = feature.subtitle
        newsImageView.sd_setImage(with: URL(string: feature.imageUrl), completed: nil)
    }
}
