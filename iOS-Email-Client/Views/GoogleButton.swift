//
//  GoogleButton.swift
//  Criptext Secure Email
//
//  Created by Erika Perugachi on 4/20/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import UIKit

class GoogleButton: UIButton {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 5
    }
    
    class func instanceFromNib() -> GoogleButton {
        return UINib(nibName: "GoogleButton", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! GoogleButton
    }
    
//    class func instanceFromNib() -> GoogleButton {
//        return UINib(nibName: "GoogleButton", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! GoogleButton
//    }
}
