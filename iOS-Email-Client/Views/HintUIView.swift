//
//  HintUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 8/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Instructions

class HintUIView: UIView, CoachMarkBodyView {
    
    @IBOutlet weak var rightConstraint: NSLayoutConstraint!
    @IBOutlet weak var topCenterConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet var view: UIView!
    var nextControl: UIControl?
    var highlightArrowDelegate: CoachMarkBodyHighlightArrowDelegate?
    
    
    override init (frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func setupView(){
        UINib(nibName: "HintUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
    }
}
