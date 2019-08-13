//
//  RestoreUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 4/9/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import Material

protocol RestoreDelegate: class {
    func cancelRestore()
    func changeFile()
    func retryRestore(password: String?)
    func restore(password: String?)
}

class RestoreUIView: UIView {
    enum State {
        case found
        case searching
        case restoring
        case error
        case missing
    }
    
    @IBOutlet weak var passwordTextField: TextField!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var warningMessageLabel: UILabel!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var changeFileButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var cloudImageView: UIImageView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var percentageContainerView: TipUIView!
    @IBOutlet weak var percentageLabel: CounterLabelUIView!
    @IBOutlet weak var passwordHeightConstraint: NSLayoutConstraint!
    weak var delegate: RestoreDelegate?
    var state = State.searching
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    func applyTheme(view: UIView) {
        progressBar.layer.cornerRadius = 5
        progressBar.layer.sublayers![1].cornerRadius = 5
        progressBar.subviews[1].clipsToBounds = true

        cloudImageView.tintColor = theme.criptextBlue
        
        cancelButton.setTitle(String.localize("RESTORE_CANCEL"), for: .normal)
        cancelButton.setTitleColor(theme.criptextBlue, for: .normal)
        
        passwordTextField.textColor = theme.mainText
        passwordTextField.attributedPlaceholder = NSAttributedString(string: String.localize("ENTER_PASSPHRASE"), attributes: [.foregroundColor: theme.placeholder, .font: 
            Font.regular.size(passwordTextField.minimumFontSize)!])
        passwordTextField.visibilityIconButton?.tintColor = theme.placeholder
        
        warningMessageLabel.textColor = theme.secondText
        
        view.backgroundColor = theme.overallBackground
    }
    
    @IBAction func onTextFieldChange(_ sender: TextField) {
        switch(sender){
        case passwordTextField:
            guard passwordTextField.text!.count >= 3 else {
                setValidField(passwordTextField, valid: false, error: String.localize("AT_LEAST_3_CHARS"))
                break
            }
            setValidField(passwordTextField, valid: true)
        default:
            break
        }
        restoreButton.isEnabled = validateForm()
        restoreButton.alpha = restoreButton.isEnabled ? 1.0 : 0.6
    }
    
    func validateForm() -> Bool {
        return passwordTextField.text!.count >= 3
    }
    
    func setValidField(_ field: TextField, valid: Bool, error: String = "") {
        field.detail = error
        field.dividerActiveColor = valid ? .mainUI : .alert
    }
    
    func setSearching() {
        state = .searching
        
        let attrText = NSMutableAttributedString(string: String.localize("BACKUP_SEARCH"), attributes: [.font: Font.bold.size(16)!, .foregroundColor: theme.markedText])
        let attrText2 = NSAttributedString(string: "\n\(String.localize("TAKE_WHILE"))", attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        
        attrText.append(attrText2)
        
        messageLabel.isHidden = false
        messageLabel.attributedText = attrText
        titleLabel.text = String.localize("BACKUP_LOOKING")
        titleLabel.textColor = theme.markedText
        cloudImageView.image = UIImage(named: "cloud-big")
        
        restoreButton.isHidden = true
        changeFileButton.isHidden = true
        progressBar.isHidden = true
        cancelButton.isHidden = false
        percentageContainerView.isHidden = true
        warningMessageLabel.isHidden = true
        passwordHeightConstraint.constant = 0
        passwordTextField.isHidden = true
    }
    
    func setFound(email: String, lastDate: Date, size: Int, isLocal: Bool, isEncrypted: Bool) {
        state = .found
        
        let attrText = NSMutableAttributedString(string: email, attributes: [.font: Font.bold.size(16)!, .foregroundColor: theme.markedText])
        let attrDate = NSAttributedString(string: "\n\(String.localize("LAST_BACKUP")) \(DateString.backup(date: lastDate))", attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        let attrSize = NSAttributedString(string: "\n\(String.localize("BACKUP_SIZE")) \(File.prettyPrintSize(size: size))", attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        
        attrText.append(attrDate)
        attrText.append(attrSize)
        
        messageLabel.isHidden = false
        messageLabel.attributedText = attrText
        titleLabel.text = String.localize("BACKUP_FOUND")
        titleLabel.textColor = theme.markedText
        if(isLocal) {
            cloudImageView.image = UIImage(named: "imgRestoremail")
        } else {
            cloudImageView.image = UIImage(named: "cloud-big")
        }
        
        restoreButton.isHidden = false
        changeFileButton.isHidden = false
        restoreButton.setTitle(String.localize("BACKUP_RESTORE"), for: .normal)
        changeFileButton.setTitle(String.localize("BACKUP_RESTORE_CHANGE_FILE"), for: .normal)
        cancelButton.isHidden = false
        progressBar.isHidden = true
        percentageContainerView.isHidden = true
        warningMessageLabel.isHidden = true
        if(isEncrypted){
            passwordHeightConstraint.constant = 30
            passwordTextField.isHidden = false
        } else {
            passwordHeightConstraint.constant = 0
            passwordTextField.isHidden = true
        }
    }
    
    func setMissing(isLocal: Bool) {
        state = .missing
        let attrText = NSMutableAttributedString(string: String.localize("BACKUP_NOT_FOUND_MESSAGE"), attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        
        messageLabel.isHidden = false
        messageLabel.attributedText = attrText
        titleLabel.text = String.localize("BACKUP_NOT_FOUND")
        titleLabel.textColor = theme.markedText
        cloudImageView.image = UIImage(named: "cloud-fail")
        
        restoreButton.isHidden = false
        changeFileButton.isHidden = false
        restoreButton.setTitle(String.localize("RETRY"), for: .normal)
        changeFileButton.setTitle(String.localize("BACKUP_RESTORE_CHANGE_FILE"), for: .normal)
        cancelButton.isHidden = false
        progressBar.isHidden = true
        percentageContainerView.isHidden = true
        warningMessageLabel.isHidden = true
        passwordHeightConstraint.constant = 0
        passwordTextField.isHidden = true
    }
    
    func setError(isLocal: Bool, isEncrypted: Bool) {
        state = .error
        
        let attrText = NSMutableAttributedString(string: String.localize("DELAYED_PROCESS"), attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        let attrQ = NSAttributedString(string: "\n\n\(String.localize("KEEP_RETRY"))", attributes: [.font: Font.bold.size(16)!, .foregroundColor: theme.markedText])
        
        attrText.append(attrQ)
        
        messageLabel.isHidden = false
        messageLabel.attributedText = attrText
        titleLabel.text = String.localize("ODD")
        titleLabel.textColor = theme.markedText
        if(isLocal) {
            cloudImageView.image = UIImage(named: "imgRestorefail")
        } else {
            cloudImageView.image = UIImage(named: "cloud-rip")
        }
        
        restoreButton.isHidden = false
        changeFileButton.isHidden = false
        restoreButton.setTitle(String.localize("RETRY"), for: .normal)
        changeFileButton.setTitle(String.localize("BACKUP_RESTORE_CHANGE_FILE"), for: .normal)
        cancelButton.isHidden = false
        progressBar.isHidden = true
        percentageContainerView.isHidden = true
        warningMessageLabel.isHidden = true
        if(isEncrypted){
            passwordTextField.text = nil
            passwordHeightConstraint.constant = 30
            passwordTextField.isHidden = false
        } else {
            passwordHeightConstraint.constant = 0
            passwordTextField.isHidden = true
        }
    }
    
    func setRestoring(isLocal: Bool) {
        state = .restoring
        
        titleLabel.text = String.localize("BACKUP_RESTORING")
        
        if(isLocal){
            cloudImageView.image = UIImage(named: "imgRestoremail")
        } else {
            cloudImageView.image = UIImage(named: "cloud-big")
        }
        warningMessageLabel.text = String.localize("SYNC_WARNING_MESSAGE")
        
        messageLabel.isHidden = true
        restoreButton.isHidden = true
        changeFileButton.isHidden = true
        cancelButton.isHidden = true
        
        progressBar.isHidden = false
        percentageContainerView.isHidden = false
        warningMessageLabel.isHidden = false
        passwordHeightConstraint.constant = 0
        passwordTextField.isHidden = true
    }
    
    func animateProgress(_ value: Double, _ duration: Double, completion: @escaping () -> Void){
        self.percentageLabel.setValue(value, interval: duration)
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
            self.progressBar.setProgress(Float(value/100), animated: true)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + duration){
            completion()
        }
    }
    
    @IBAction func didPressRetry(_ sender: Any) {
        if state == .found {
            delegate?.restore(password: passwordTextField.text)
            return
        }
        delegate?.retryRestore(password: passwordTextField.text)
    }
    
    @IBAction func didPressChangeFile(_ sender: Any) {
        delegate?.changeFile()
    }
    
    @IBAction func didPressCancel(_ sender: Any) {
        delegate?.cancelRestore()
    }
}
