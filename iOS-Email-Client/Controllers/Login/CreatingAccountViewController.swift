//
//  CreatingAccountViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/9/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class CreatingAccountViewController: UIViewController{
    
    @IBOutlet weak var logoImageView: UIImageView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var percentageLabel: UILabel!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        logoImageView.tintColor = UIColor(displayP3Red: 0.0, green: 0.65, blue: 1.0, alpha: 1.0)
        progressBar.clipsToBounds = true
        progressBar.layer.cornerRadius = 5
        progressBar.layer.sublayers![1].cornerRadius = 5
        progressBar.subviews[1].clipsToBounds = true
        
        percentageLabel.clipsToBounds = true
        percentageLabel.layer.cornerRadius = 8
    }
}
