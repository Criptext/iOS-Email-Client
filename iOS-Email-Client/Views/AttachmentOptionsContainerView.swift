//
//  AttachmentOptionsContainerView.swift
//  iOS-Email-Client
//
//  Created by Allisson on 12/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class AttachmentOptionsContainerView: UIView {
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var docsButton: UIButton!
    @IBOutlet weak var galleryButton: UIButton!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let theme = ThemeManager.shared.theme
        backgroundColor = theme.background
        cameraButton.setTitleColor(theme.composerMenu, for: .normal)
        docsButton.setTitleColor(theme.composerMenu, for: .normal)
        galleryButton.setTitleColor(theme.composerMenu, for: .normal)
        cameraButton.imageView?.tintColor = theme.composerMenu
        docsButton.imageView?.tintColor = theme.composerMenu
        galleryButton.imageView?.tintColor = theme.composerMenu
        separatorView.backgroundColor = theme.separator
    }
}
