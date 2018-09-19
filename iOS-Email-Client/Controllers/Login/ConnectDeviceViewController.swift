//
//  ConnectDeviceViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ConnectDeviceViewController: UIViewController{
    var loginData: LoginData?
    var linkData: LinkData?
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var dotsProgressView: DotsProgressUIView!
    @IBOutlet weak var loadingWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var successImage: UIImageView!
    @IBOutlet weak var backgroundCircle: UIView!
    
    override func viewDidLoad() {
        setEmailLabel()
        successImage.isHidden = true
        backgroundCircle.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)){
            self.handleSuccess()
        }
    }
    
    func setEmailLabel(){
        if let loginData = self.loginData {
            emailLabel.text = loginData.email
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
    
    func linkAccept(){
        APIManager.linkAccept(randomId: <#T##String#>, token: <#T##String#>, completion: <#T##((ResponseData) -> Void)##((ResponseData) -> Void)##(ResponseData) -> Void#>)
    }
}
