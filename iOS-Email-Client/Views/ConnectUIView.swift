//
//  ConnectUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/19/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ConnectUIView: UIView {
    
    @IBOutlet var view: UIView!
    
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dotsProgressView: DotsProgressUIView!
    @IBOutlet weak var loadingWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var successImage: UIImageView!
    @IBOutlet weak var backgroundCircle: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var goBackButton: UIButton!
    var goBack: (() -> Void)?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "ConnectView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
    }
    
    func initialLoad(email: String) {
        emailLabel.text = email
        successImage.isHidden = true
        backgroundCircle.isHidden = true
    }
    
    func handleSuccess(){
        dotsProgressView.isHidden = true
        backgroundCircle.isHidden = false
        UIView.animate(withDuration: 0.5, animations: {
            self.loadingWidthConstraint.constant = CGFloat(30)
            self.view.layoutIfNeeded()
        }, completion: { (completed) in
            self.successImage.isHidden = false
        })
    }

    @IBAction func goBack(_ sender: Any) {
        goBack?()
    }
}
