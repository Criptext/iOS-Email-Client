//
//  ProfileNameChangeViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/23/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class SingleTextInputViewController: BaseUIPopover {
    @IBOutlet weak var nameTextField: TextField!
    @IBOutlet weak var titleLabel: UILabel!
    var myTitle = ""
    var initInputText = ""
    var onOk: ((String) -> Void)?
    
    init(){
        super.init("SingleTextInputUIPopover")
    }
    
    override func viewDidLoad() {
        titleLabel.text = myTitle
        nameTextField.text = initInputText
        nameTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        nameTextField.becomeFirstResponder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func onDonePress(_ sender: Any){
        self.onOkPress(sender)
    }
    
    @IBAction func onDidEndOnExit(_ sender: Any) {
        self.onOkPress(sender)
    }
    
    @IBAction func onOkPress(_ sender: Any) {
        if(!nameTextField.text!.isEmpty){
            self.onOk?(nameTextField.text!)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
