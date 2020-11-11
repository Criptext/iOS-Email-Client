//
//  RestoreViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/4/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class RestoreBackupViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    
    @IBOutlet weak var searchingContainerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var downloadingProgressView: CircleProgressBarUIView!
    @IBOutlet weak var errorImageView: UIImageView!
    
    @IBOutlet weak var restoreDetailContainerView: UIView!
    @IBOutlet weak var lastLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var passphraseTextField: StatusTextField!
    
    @IBOutlet weak var progressContainerView: UIView!
    @IBOutlet weak var progressView: CircleProgressBarUIView!
    @IBOutlet weak var progressLabel: UILabel!
    @IBOutlet weak var progressImageView: UIImageView!

    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var backupImageTopConstraint: NSLayoutConstraint!
    
    var TOP_NOT_ENCRYPTED: CGFloat = 40
    var TOP_ENCRYPTED: CGFloat = 5.0
    
    enum STEP {
        case searching
        case found
        case none
        case restoring
        case odd
        case ready
    }
    
    var cloudRestorer: CloudRestorer?
    weak var myAccount: Account!
    var step: STEP = .searching
    var isEncrypted = false
    var fileUrl: URL?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyTheme()
        applyStep()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.secondText
        skipButton.setTitleColor(theme.markedText, for: .normal)
        
        lastLabel.textColor = theme.markedText
        dateLabel.textColor = theme.mainText
        
        passphraseTextField.applyMyTheme()
        
        progressView.progressColor = theme.criptextBlue.cgColor
        progressLabel.textColor = theme.markedText
        
        view.backgroundColor = theme.overallBackground
    }
    
    func applyStep() {
        restoreDetailContainerView.isHidden = true
        progressContainerView.isHidden = true
        searchingContainerView.isHidden = true
        errorImageView.isHidden = true
        skipButton.isHidden = false
        restoreButton.alpha = 1
        restoreButton.isEnabled = true
        checkImageView.isHidden = true
        progressImageView.isHidden = false
        
        switch step {
        case .searching:
            if let restorer = cloudRestorer {
                restorer.delegate = nil
            }
            
            titleLabel.text = String.localize("BACKUP_SEARCH")
            messageLabel.text = String.localize("BACKUP_SEARCH_MESSAGE")
    
            restoreButton.setTitle(String.localize("BACKUP_RESTORE"), for: .normal)
            restoreButton.alpha = 0.5
            restoreButton.isEnabled = false
            skipButton.setTitle(String.localize(""), for: .normal)
            
            searchingContainerView.isHidden = false
            downloadingProgressView.isHidden = true
            downloadingProgressView.reset(angle: 0)
            
            cloudRestorer = CloudRestorer()
            cloudRestorer?.myAccount = myAccount
            cloudRestorer?.delegate = self
            cloudRestorer?.check()
        case .found:
            if let path = fileUrl?.path,
               let fileAttributes = try? FileManager.default.attributesOfItem(atPath: path) {
                let lastDate = Date(timeIntervalSinceReferenceDate: (fileAttributes[.modificationDate] as! NSDate).timeIntervalSinceReferenceDate)
                let dateString = DateString.backup(date: lastDate)
                dateLabel.text = dateString
            }
            
            if isEncrypted {
                passphraseTextField.becomeFirstResponder()
            }
            
            backupImageTopConstraint.constant = isEncrypted ? self.TOP_ENCRYPTED : self.TOP_NOT_ENCRYPTED
            titleLabel.text = String.localize("BACKUP_FOUND")
            messageLabel.text = String.localize("BACKUP_FOUND_MESSAGE")
            lastLabel.text = String.localize("LAST_BACKUP")
            restoreButton.setTitle(String.localize("BACKUP_RESTORE"), for: .normal)
            skipButton.setTitle(String.localize("SKIP"), for: .normal)
            
            restoreDetailContainerView.isHidden = false
            passphraseTextField.isHidden = !isEncrypted
        case .none:
            titleLabel.text = String.localize("BACKUP_NONE")
            messageLabel.text = String.localize("BACKUP_NONE_MESSAGE")
            
            restoreButton.setTitle(String.localize("RETRY"), for: .normal)
            skipButton.setTitle(String.localize("SKIP"), for: .normal)
            
            errorImageView.isHidden = false
        case .restoring:
            skipButton.isHidden = true
            progressContainerView.isHidden = false
            restoreButton.isEnabled = false
            
            titleLabel.text = String.localize("BACKUP_RESTORING")
            messageLabel.text = String.localize("BACKUP_RESTORING_MESSAGE")
            
            restoreButton.alpha = 0.5
            restoreButton.setTitle(String.localize("BACKUP_RESTORING"), for: .normal)
        case .odd:
            titleLabel.text = String.localize("ODD")
            messageLabel.text = String.localize("BACKUP_DELAY")
            
            restoreButton.setTitle(String.localize("RETRY"), for: .normal)
            skipButton.setTitle(String.localize("CANCEL"), for: .normal)
            
            errorImageView.isHidden = false
        case .ready:
            skipButton.isHidden = true
            checkImageView.isHidden = false
            restoreButton.alpha = 0
            restoreButton.isEnabled = false
            progressContainerView.isHidden = false
            progressImageView.isHidden = true
            break
        }
        
    }
    
    @IBAction func onSkipPress(_ sender: Any) {
        goToMailbox()
    }
    
    @IBAction func onRestorePress(_ sender: Any) {
        switch step {
        case .found:
            importDatabase()
        case .none, .odd:
            retry()
        default:
            break
        }
    }
    
    @IBAction func onBackPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func retry() {
        if fileUrl == nil {
            step = .searching
        } else {
            step = .found
        }
        applyStep()
    }
    
    func importDatabase() {
        guard let path = fileUrl?.path else {
            return
        }
        
        passphraseTextField.resignFirstResponder()
        
        var zippedPath = path
        if isEncrypted {
            guard let pass = passphraseTextField.text,
                  let decryptPath = AESCipher.streamEncrypt(path: path, outputName: StaticFile.decryptedDB.name, bundle: AESCipher.KeyBundle(password: pass, salt: nil), ivData: nil, operation: kCCDecrypt) else {
                step = .odd
                applyStep()
                handleError(error: String.localize("IMPORT_WRONG_PASSWORD"))
                return
            }
            zippedPath = decryptPath
        }
        
        guard let decompressedPath = try? AESCipher.compressFile(path: zippedPath, outputName: StaticFile.unzippedDB.name, compress: false) else {
            step = .odd
            applyStep()
            handleError(error: String.localize("IMPORT_FORMAT"))
            return
        }
        
        step = .restoring
        applyStep()
        
        self.progressView.reset(angle: 0)
        self.progressLabel.text = "0 %"
        
        DBManager.clearMailbox(account: myAccount)
        FileUtils.deleteAccountDirectory(account: myAccount)
        
        let restoreTask = RestoreDBAsyncTask(path: decompressedPath, accountId: myAccount.compoundKey, initialProgress: 80)
        restoreTask.start(progressHandler: { (progress) in
            self.progressView.targetAngle = Double(progress * 360 / 100)
            self.progressLabel.text = "\(progress) %"
        }) {_ in
            self.step = .ready
            self.applyStep()
            self.progressView.reset(angle: 360)
            self.progressLabel.text = "100 %"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.goToMailbox()
            }
        }
    }
    
    func handleError(error: String) {
        messageLabel.text = error
        step = .odd
        applyStep()
    }
    
    func goToMailbox() {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        if delegate.getInboxVC() != nil {
            delegate.swapAccount(account: myAccount, showRestore: false)
            return
        }
        
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "setsettingsviewcontroller") as! SetSettingsViewController
        controller.myAccount = self.myAccount
        self.navigationController?.pushViewController(controller, animated: true)
    }
}

extension RestoreBackupViewController: CloudRestorerDelegate {
    func error(message: String) {
        handleError(error: message)
    }
    
    func success(url: URL) {
        self.fileUrl = url
        step = .found
        applyStep()
    }
    
    func downloading(progress: Float) {
        guard step == .searching else {
            return
        }
        downloadingProgressView.isHidden = false
        downloadingProgressView.angle = Double(progress * 360 / 100)
    }
}
