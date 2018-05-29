//
//  SignatureEditorViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/24/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RichEditorView

class SignatureEditorViewController: UIViewController {
    
    @IBOutlet weak var richEditor: RichEditorView!
    @IBOutlet weak var signatureEnableSwitch: UISwitch!
    @IBOutlet weak var OnOffLabel: UILabel!
    var myAccount: Account!
    var keyboardManager: KeyboardManager!
    
    override func viewDidLoad() {
        navigationItem.title = "Signature"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        signatureEnableSwitch.isOn = myAccount.signatureEnabled
        richEditor.isEditingEnabled = signatureEnableSwitch.isOn
        OnOffLabel.text = myAccount.signatureEnabled ? "On" : "Off"
        richEditor.html = myAccount.signature
        richEditor.placeholder = "Signature"
        richEditor.setTextColor(.green)
        keyboardManager = KeyboardManager(view: self.view)
        keyboardManager.toolbar.editor = richEditor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        keyboardManager.beginMonitoring()
        richEditor.focus()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        keyboardManager.stopMonitoring()
    }
    
    @IBAction func onSwitchToggle(_ sender: Any) {
        richEditor.isEditingEnabled = signatureEnableSwitch.isOn
        OnOffLabel.text = signatureEnableSwitch.isOn ? "On" : "Off"
        if(signatureEnableSwitch.isOn){
            richEditor.focus()
        } else {
            richEditor.webView.endEditing(true)
        }
        
    }
    
    @objc func goBack(){
        DBManager.update(account: myAccount, signature: richEditor.html, enabled: signatureEnableSwitch.isOn)
        navigationController?.popViewController(animated: true)
    }
}
