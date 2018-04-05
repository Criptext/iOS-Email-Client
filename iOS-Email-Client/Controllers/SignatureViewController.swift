//
//  SignatureViewController.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/30/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

class SignatureViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.text = ""
        self.textView.becomeFirstResponder()
    }
    
    @IBAction func didPressCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didPressSave(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}
