//
//  CheckMarkUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class CheckMarkUIView : UIView {
    
    var checkImageView : UIImageView!
    
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
        checkImageView = UIImageView(image: #imageLiteral(resourceName: "check"))
        checkImageView.tintColor = .white
        checkImageView.frame = CGRect(x: 2, y: 2, width: frame.width - 4, height: frame.height - 4)
        checkImageView.contentMode = .scaleAspectFit
        addSubview(checkImageView)
    }
    
    func setChecked(_ checked: Bool){
        checkImageView.isHidden = !checked
        guard checked else {
            backgroundColor = .white
            layer.borderColor = UIColor.lightIcon.cgColor
            return
        }
        backgroundColor = .mainUI
        layer.borderColor = UIColor.mainUI.cgColor
    }
}
