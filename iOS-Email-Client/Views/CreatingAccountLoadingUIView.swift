//
//  CreatingAccountLoadingUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/27/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class CreatingAccountLoadingUIView: UIView {
    
    @IBOutlet weak var loadingView: SwingingLoaderUIView!
    @IBOutlet weak var creatingLabel: UILabel!
    
    @IBOutlet var view: UIView!
    
    var display: Bool {
        get {
            return !self.isHidden
        }
        set(typeValue) {
            self.isHidden = !typeValue
            if (typeValue) {
                loadingView.startAnimating()
            } else {
                loadingView.stopAnimating()
            }
            
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    func commonInit() {
        UINib(nibName: "CreatingAccountLoadingUIView", bundle: Bundle(for: type(of: self))).instantiate(withOwner: self, options: nil)
        addSubview(view)

        view.translatesAutoresizingMaskIntoConstraints = false
        let leadingConstraint = NSLayoutConstraint(item: view!, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: view!, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1, constant: 0)
        let topConstraint = NSLayoutConstraint(item: view!, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0)
        let bottomConstraint = NSLayoutConstraint(item: view!, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0)
        self.addConstraints([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    }
}
