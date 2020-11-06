//
//  ImportOptionsViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/28/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class ImportOptionsViewController: UIViewController {
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var deviceButton: UIButton!
    @IBOutlet weak var cloudButton: UIButton!
    @IBOutlet weak var fileButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    
    var myAccount: Account!
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFields()
        applyTheme()
    }
    
    func applyTheme() {
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.mainText
        skipButton.setTitleColor(theme.markedText, for: .normal)
    }
    
    func setupFields() {
        titleLabel.text = String.localize("IMPORT_TITLE")
        messageLabel.text = String.localize("IMPORT_MESSAGE")
        deviceButton.setTitle(String.localize("IMPORT_DEVICE"), for: .normal)
        cloudButton.setTitle(String.localize("IMPORT_CLOUD"), for: .normal)
        fileButton.setTitle(String.localize("IMPORT_FILE"), for: .normal)
        skipButton.setTitle(String.localize("SKIP"), for: .normal)
    }
    
    @IBAction func onFromOtherDevicePress(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "syncrequestviewcontroller") as! SyncRequestViewController
        controller.modalPresentationStyle = .fullScreen
        controller.myAccount = self.myAccount
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func onFromCloudPress(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "restorebackupviewcontroller") as! RestoreBackupViewController
        controller.myAccount = self.myAccount
        controller.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    @IBAction func onFromFilePress(_ sender: UIButton) {
        let providerList = UIDocumentPickerViewController(documentTypes: ["public.content", "public.data"], in: .import)
        providerList.delegate = self;
        
        providerList.popoverPresentationController?.sourceView = self.view
        providerList.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        let isSystemDarkMode = UIUtils.isSystemDarlkModeEnabled(controller: self)
        providerList.popoverPresentationController?.barButtonItem?.tintColor = isSystemDarkMode ? .white : .black
        providerList.modalPresentationStyle = .fullScreen
        self.present(providerList, animated: true, completion: nil)
    }
    
    @IBAction func onSkipPress(_ sender: UIButton) {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        if delegate.getInboxVC() != nil {
            delegate.swapAccount(account: myAccount, showRestore: false)
            return
        }
        
        let mailboxVC = delegate.initMailboxRootVC(nil, myAccount, showRestore: false)
        var options = UIWindow.TransitionOptions()
        options.direction = .toTop
        options.duration = 0.4
        options.style = .easeOut
        UIApplication.shared.keyWindow?.setRootViewController(mailboxVC, options: options)
    }
}

extension ImportOptionsViewController: UIDocumentPickerDelegate {
    
    func documentMenu(didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        //show document picker
        documentPicker.delegate = self;
        
        documentPicker.popoverPresentationController?.sourceView = self.view
        documentPicker.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        self.present(documentPicker, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        
        let filename = url.lastPathComponent
        
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "restorebackupviewcontroller") as! RestoreBackupViewController
        controller.step = .found
        controller.modalPresentationStyle = .fullScreen
        controller.isEncrypted = filename.contains(".enc")
        controller.myAccount = self.myAccount
        controller.fileUrl = url
        self.navigationController?.pushViewController(controller, animated: true)
    }
}
