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
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var OnOffLabel: UILabel!
    var isEdited = false
    var myAccount: Account!
    var keyboardManager: KeyboardManager!
    
    override func viewDidLoad() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        navigationItem.title = String.localize("SIGNATURE_TITLE")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: String.localize("DONE"), style: .plain, target: self, action: #selector(saveAndReturn))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        signatureEnableSwitch.isOn = myAccount.signatureEnabled
        richEditor.isEditingEnabled = signatureEnableSwitch.isOn
        richEditor.isHidden = !signatureEnableSwitch.isOn
        OnOffLabel.text = myAccount.signatureEnabled ? String.localize("ON") : String.localize("OFF")
        richEditor.delegate = self
        richEditor.html = myAccount.signature
        richEditor.placeholder = String.localize("SIGNATURE")
        richEditor.setTextColor(.green)
        keyboardManager = KeyboardManager(view: self.view)
        keyboardManager.toolbar.editor = richEditor
        applyTheme()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        self.view.backgroundColor = theme.overallBackground
        richEditor.webView.backgroundColor = theme.overallBackground
        richEditor.webView.isOpaque = false
        separatorView.backgroundColor = theme.separator
        OnOffLabel.textColor = theme.mainText
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
        OnOffLabel.text = signatureEnableSwitch.isOn ? String.localize("ON") : String.localize("OFF")
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
        let popover = GenericDualAnswerUIPopover()
        popover.initialTitle = String.localize("UNSAVED_CHANGES")
        popover.initialMessage = String.localize("CHANGES_WERE_MADE")
        popover.leftOption = String.localize("RETURN_DONT_SAVE")
        popover.rightOption = String.localize("SAVE_RETURN")
        popover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    self?.navigationController?.popViewController(animated: true)
                    return
            }
            weakSelf.saveAndReturn()
        }
        self.presentPopover(popover: popover, height: 200)
    }
    
    @objc func saveAndReturn(){
        DBManager.update(account: myAccount, signature: richEditor.html, enabled: signatureEnableSwitch.isOn)
        navigationController?.popViewController(animated: true)
    }
}

extension SignatureEditorViewController: RichEditorDelegate {
    func richEditorDidLoad(_ editor: RichEditorView) {
        let theme = ThemeManager.shared.theme
        editor.setEditorFontColor(theme.mainText)
        editor.setEditorBackgroundColor(theme.overallBackground)
    }
    
    func richEditor(_ editor: RichEditorView, contentDidChange content: String) {
        if(myAccount.signature != content){
            isEdited = true
        }
    }
}

extension SignatureEditorViewController: LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData) {
        guard linkData.version == Env.linkVersion else {
            let popover = GenericAlertUIPopover()
            popover.myTitle = String.localize("VERSION_TITLE")
            popover.myMessage = String.localize("VERSION_MISMATCH")
            self.presentPopover(popover: popover, height: 220)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = myAccount
        self.present(linkDeviceVC, animated: true, completion: nil)
    }
    func onCancelLinkDevice(linkData: LinkData) {
        if case .sync = linkData.kind {
            APIManager.syncDeny(randomId: linkData.randomId, account: myAccount, completion: {_ in })
        } else {
            APIManager.linkDeny(randomId: linkData.randomId, account: myAccount, completion: {_ in })
        }
    }
}

extension SignatureEditorViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}
