//
//  CheckMarkUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class CheckMarkUIView : UIView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup(){
        clipsToBounds = true
        layer.borderWidth = 2.0
        layer.cornerRadius = frame.width / 10
    }
    
    func setChecked(_ checked: Bool){
        guard checked else {
            for subview in subviews {
                subview.removeFromSuperview()
            }
            backgroundColor = .white
            layer.borderColor = UIColor.lightIcon.cgColor
            return
        }
        let image = #imageLiteral(resourceName: "check")
        let imageView = UIImageView(image: image)
        imageView.tintColor = .white
        imageView.frame = CGRect(x: 2, y: 2, width: frame.width - 4, height: frame.height - 4)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        backgroundColor = .mainUI
        layer.borderColor = UIColor.mainUI.cgColor
    }
}
