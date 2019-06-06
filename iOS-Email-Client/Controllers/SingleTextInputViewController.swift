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
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var nameTextField: TextField!
    @IBOutlet weak var titleLabel: UILabel!
    var keyboardType =  UIKeyboardType.default
    var capitalize:UITextAutocapitalizationType = .sentences
    var myTitle = ""
    var initInputText = ""
    var onOk: ((String) -> Void)?
    
    init(){
        super.init("SingleTextInputUIPopover")
    }
    
    override func viewDidLoad() {
        titleLabel.text = myTitle
        nameTextField.text = initInputText
        nameTextField.keyboardType = keyboardType
        nameTextField.autocapitalizationType = capitalize
        nameTextField.keyboardToolbar.doneBarButton.setTarget(self, action: #selector(onDonePress(_:)))
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let _ = nameTextField.becomeFirstResponder()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        nameTextField.detailColor = theme.alert
        nameTextField.textColor = theme.mainText
        nameTextField.placeholderLabel.textColor = theme.mainText
        titleLabel.textColor = theme.mainText
        okButton.backgroundColor = theme.popoverButton
        cancelButton.backgroundColor = theme.popoverButton
        okButton.setTitleColor(theme.mainText, for: .normal)
        cancelButton.setTitleColor(theme.mainText, for: .normal)
    }
    
    @objc func onDonePress(_ sender: Any){
        self.onOkPress(sender)
    }
    
    @IBAction func onDidEndOnExit(_ sender: Any) {
        self.onOkPress(sender)
    }
    
    @IBAction func onOkPress(_ sender: Any) {
        let text = nameTextField.text!
        self.dismiss(animated: true){ [weak self] in
            if(!text.isEmpty){
                self?.onOk?(text)
            }
        }
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
