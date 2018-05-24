//
//  ProfileNameChangeViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class ProfileNameChangeViewController: BaseUIPopover {
    @IBOutlet weak var nameTextField: TextField!
    var currentName: String!
    
    init(){
        super.init("ProfileNameChangeUIView")
    }
    
    override func viewDidLoad() {
        nameTextField.text = currentName
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameTextField.becomeFirstResponder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func onOkPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
