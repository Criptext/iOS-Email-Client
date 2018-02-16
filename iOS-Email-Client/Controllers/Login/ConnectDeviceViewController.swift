//
//  ConnectDeviceViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ConnectDeviceViewController: UIViewController{
    var loginData: LoginData!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dotsProgressView: DotsProgressUIView!
    @IBOutlet weak var loadingWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var successImage: UIImageView!
    @IBOutlet weak var backgroundCircle: UIView!
    
    override func viewDidLoad() {
        emailLabel.text = loginData.email
        successImage.isHidden = true
        backgroundCircle.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)){
            self.handleSuccess()
        }
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
}
