//
//  TourViewController.swift
//  Criptext Secure Email
//
//  Created by Erika Perugachi on 4/7/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import UIKit
import GoogleAPIClientForREST
import Material

class TourViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    var index: Int!
    var titleText: String!
    var photoFile: String!
    var descriptionText: String!
  
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.titleLabel.text = self.titleText
        self.photoImageView.image = UIImage(named: self.photoFile)
        self.descriptionLabel.text = self.descriptionText
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

