//
//  DetailGuideView.swift
//  Criptext
//
//  Created by Criptext Mac on 8/18/15.
//  Copyright (c) 2015 Criptext INC. All rights reserved.
//

import Foundation
import FLAnimatedImage

class DetailGuideView: UIView{
    @IBOutlet weak var detailContainerView: UIView!
    @IBOutlet weak var detailTitleLabel: UILabel!
    @IBOutlet weak var detailTitleHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var detailToHeaderTopSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var headerGifView: FLAnimatedImageView!
    @IBOutlet weak var headerGifHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var headerImageView: UIImageView!
    @IBOutlet weak var headerImageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var headerTopConstraint: NSLayoutConstraint!
    
    var index: Int!
    
    class func instanceFromNib() -> DetailGuideView {
        return UINib(nibName: "DetailGuideView", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! DetailGuideView
    }

}
