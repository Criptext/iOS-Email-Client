//
//  AvatarUI.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 5/15/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class AvatarUIView: UIView {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var borderImageView: UIImageView!
    
    @IBOutlet var view: UIView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "AvatarUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
    }
    
    func setAvatar(email: String, name: String) {
        UIUtils.setProfilePictureImage(imageView: avatarImageView, contact: (email, name))
    }
}
