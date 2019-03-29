//
//  ReplyToEditorViewController.swift
//  iOS-Email-Client
//
//  Created by Saul Mestanza on 1/21/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import RichEditorView
import Material

class ReplyToEditorViewController: UIViewController {
    
    @IBOutlet weak var saveReplyTo: UIButton!
    @IBOutlet weak var emailText: TextField!
    @IBOutlet weak var replyToEnableSwitch: UISwitch!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var OnOffLabel: UILabel!
    @IBOutlet weak var disableContainerView: UIView!
    @IBOutlet weak var editContainerView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    var generalData: GeneralSettingsData!
    var myAccount: Account!
    
    override func viewDidLoad() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        navigationItem.title = String.localize("REPLY_TO_TITLE")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes(
[NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        replyToEnableSwitch.isOn = self.generalData.replyTo == "" ? false : true
        emailText.text = self.generalData.replyTo == "" ? "" : self.generalData.replyTo!
        setSwitchAttributes()
        applyTheme()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        self.view.backgroundColor = theme.overallBackground
        emailText.backgroundColor = theme.overallBackground
        emailText.textColor = theme.mainText
        emailText.attributedPlaceholder = NSAttributedString(
            string: String.localize("REPLY_TO"),
            attributes: [NSAttributedString.Key.foregroundColor: theme.placeholder]
        )
        separatorView.backgroundColor = theme.separator
        OnOffLabel.textColor = theme.mainText
        disableContainerView.backgroundColor = theme.cellHighlight
        messageLabel.textColor = theme.secondText
        titleLabel.textColor = theme.markedText
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func onSave(_ sender: Any) {
        saveReplyToAPI(enable: true)
    }
    
    private func saveReplyToAPI(enable: Bool){
        let email = enable ? (emailText.text ?? "") : ""
        replyToEnableSwitch.isEnabled = false
        APIManager.updateReplyTo(email: email, enable: enable, token: myAccount.jwt) { (responseData) in
            self.replyToEnableSwitch.isEnabled = true
            if case .Unauthorized = responseData {
                self.logout(account: self.myAccount)
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("SOMETHING_WRONG"), message: String.localize("UNABLE_UPDATE_REPLYTO"), style: .alert)
                return
            }
            if(enable){
                self.showAlert(String.localize("REPLY_TO_TITLE"), message: String.localize("REPLY_TO_SUCCESS"), style: .alert)
            }
            else{
                self.showAlert(String.localize("REPLY_TO_TITLE"), message: String.localize("REPLY_TO_REMOVED"), style: .alert)
            }
            self.generalData.replyTo = email
        }
    }
    
    @IBAction func onSwitchToggle(_ sender: Any) {
        setSwitchAttributes()
        if !replyToEnableSwitch.isOn {
            saveReplyToAPI(enable: false)
        }
    }
    
    private func setSwitchAttributes(){
        disableContainerView.isHidden = replyToEnableSwitch.isOn
        editContainerView.isHidden = !replyToEnableSwitch.isOn
        OnOffLabel.text = replyToEnableSwitch.isOn ? String.localize("ON") : String.localize("OFF")
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
        return
    }
}

extension ReplyToEditorViewController: LinkDeviceDelegate {
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
            APIManager.syncDeny(randomId: linkData.randomId, token: myAccount.jwt, completion: {_ in })
        } else {
            APIManager.linkDeny(randomId: linkData.randomId, token: myAccount.jwt, completion: {_ in })
        }
    }
}

extension ReplyToEditorViewController: UIGestureRecognizerDelegate {
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

