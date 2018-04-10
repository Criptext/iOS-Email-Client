//
//  MenuItemUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import UIKit

class MenuItemUIView: UIButton {
    @IBOutlet weak var badgeView: UIView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var itemLabel: UILabel!
    @IBInspectable var itemImage: UIImage? {
        get {
            return iconView.image
        }
        set(image) {
            iconView.image = image
        }
    }
    @IBInspectable var itemLabelText: String? {
        get {
            return itemLabel.text
        }
        set(text) {
            itemLabel.text = text
        }
    }
    @IBInspectable var labelId: Int = SystemLabel.all.id
    @IBOutlet var view: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "MenuItemUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        showBadge(0)
        showAsSelected(false)
    }
    
    func showBadge(_ count: Int){
        guard count > 0 else {
            badgeView.isHidden = true
            return
        }
        badgeView.isHidden = false
        badgeLabel.text = count.description
    }
    
    func showAsSelected(_ selected: Bool){
        backgroundColor = selected ? .itemSelected : .clear
        itemLabel.textColor = selected ? .black : .lightText
        iconView.tintColor = selected ? .black : .lightIcon
    }
}
