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
    var isEdited = false
    var myAccount: Account!
    var keyboardManager: KeyboardManager!
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("Signature")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(saveAndReturn))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        signatureEnableSwitch.isOn = myAccount.signatureEnabled
        richEditor.isEditingEnabled = signatureEnableSwitch.isOn
        richEditor.isHidden = !signatureEnableSwitch.isOn
        OnOffLabel.text = myAccount.signatureEnabled ? String.localize("On") : String.localize("Off")
        richEditor.delegate = self
        richEditor.html = myAccount.signature
        richEditor.placeholder = String.localize("Signature")
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
        isEdited = true
        richEditor.isEditingEnabled = signatureEnableSwitch.isOn
        richEditor.isHidden = !signatureEnableSwitch.isOn
        OnOffLabel.text = signatureEnableSwitch.isOn ? "On" : "Off"
        if(signatureEnableSwitch.isOn){
            richEditor.focus()
        } else {
            richEditor.webView.endEditing(true)
        }
        
    }
    
    @objc func goBack(){
        guard isEdited else {
            navigationController?.popViewController(animated: true)
            return
        }
        let saveAction = UIAlertAction(title: String.localize("Save and return"), style: .default){ (alert : UIAlertAction!) -> Void in
            self.saveAndReturn()
        }
        let discardAction = UIAlertAction(title: String.localize("Return without saving"), style: .destructive){ (alert : UIAlertAction!) -> Void in
            self.navigationController?.popViewController(animated: true)
        }
        showAlert(String.localize("Unsaved Changes"), message: String.localize("You have made changes that were not saved. Do you wish to save and return?"), style: .alert, actions: [saveAction, discardAction])
    }
    
    @objc func saveAndReturn(){
        DBManager.update(account: myAccount, signature: richEditor.html, enabled: signatureEnableSwitch.isOn)
        navigationController?.popViewController(animated: true)
    }
}

extension SignatureEditorViewController: RichEditorDelegate {
    func richEditor(_ editor: RichEditorView, contentDidChange content: String) {
        if(myAccount.signature != content){
            isEdited = true
        }
    }
}

extension SignatureEditorViewController: LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = myAccount
        self.present(linkDeviceVC, animated: true, completion: nil)
    }
    func onCancelLinkDevice(linkData: LinkData) {
        APIManager.linkDeny(randomId: linkData.randomId, account: myAccount, completion: {_ in })
    }
}
