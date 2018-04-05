//
//  HeaderViewController.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/29/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

class HeaderViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.text = ""
        CriptextSpinner.show(in: self.view, title: nil, image: UIImage(named: "icon_sent_chat.png"))
    }
    
    @IBAction func didPressCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func didPressSave(_ sender: UIBarButtonItem) {
        
        CriptextSpinner.show(in: self.view, title: nil, image: UIImage(named: "icon_sent_chat.png"))
        
    }
}
