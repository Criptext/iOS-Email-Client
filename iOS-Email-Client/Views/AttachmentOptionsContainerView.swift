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
        cameraButton.setTitleColor(theme.mainText, for: .normal)
        docsButton.setTitleColor(theme.mainText, for: .normal)
        galleryButton.setTitleColor(theme.mainText, for: .normal)
        cameraButton.imageView?.tintColor = theme.mainText
        docsButton.imageView?.tintColor = theme.mainText
        galleryButton.imageView?.tintColor = theme.mainText
        separatorView.backgroundColor = theme.separator
    }
}
