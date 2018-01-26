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
    
    var currentUser:User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.textView.text = currentUser.emailHeader
        CriptextSpinner.show(in: self.view, title: nil, image: UIImage(named: "icon_sent_chat.png"))
        
        APIManager.getHeader(self.currentUser) { (error, header) in
            CriptextSpinner.hide(from: self.view)
            guard let header = header else {
                print(String(describing: error))
                return
            }
            
            DBManager.update(self.currentUser, header: header)
            
            self.textView.text = header
            self.textView.becomeFirstResponder()
        }
    }
    
    @IBAction func didPressCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func didPressSave(_ sender: UIBarButtonItem) {
        
        guard self.currentUser.emailHeader != self.textView.text else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        CriptextSpinner.show(in: self.view, title: nil, image: UIImage(named: "icon_sent_chat.png"))
        
        APIManager.update(self.textView.text, of: self.currentUser) { (error, header) in
            CriptextSpinner.hide(from: self.view)
            guard let header = header else {
                self.showAlert("Network connection error", message: "Please try again later", style: .alert)
                print(String(describing: error))
                return
            }
            
            DBManager.update(self.currentUser, header: header)
            self.dismiss(animated: true, completion: nil)
        }
    }
}
