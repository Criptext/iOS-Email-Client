//
//  SyncViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/4/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Lottie

class SyncViewController: UIViewController {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var processLabel: UILabel!
    @IBOutlet weak var cancelProcessButton: UIButton!
    @IBOutlet weak var checkImageView: UIImageView!
    @IBOutlet weak var animateView: UIView!
    @IBOutlet weak var circleProgressView: CircleProgressBarUIView!
    
    var animationView: AnimationView? = nil
    var acceptData: AcceptData!
    var socket : SingleWebSocket?
    weak var previousWebsocketDelegate: WebSocketManagerDelegate?
    var scheduleWorker = ScheduleWorker(interval: 10.0, maxRetries: 18)
    weak var myAccount: Account!
    
    internal struct LinkSuccessData {
        var key: String
        var address: String
    }
    
    internal enum CODE: Int {
        case waiting = 1
        case downloading = 2
        case key = 3
        case dekey = 4
        case signal = 5
        case encode = 6
        case importing = 7
    }
    
    enum STEP {
        case waiting
        case downloading(LinkSuccessData)
        case restoring(String, LinkSuccessData)
        case importing(String)
        case ready
        
        var message: String {
            switch self {
            case .waiting:
                return String.localize("SYNC_WAITING")
            case .downloading:
                return String.localize("SYNC_DOWNLOADING")
            case .restoring, .importing:
                return String.localize("SYNC_RESTORING")
            case .ready:
                return String.localize("SYNC_READY")
            }
        }
        
        var image: UIImage {
            switch self {
            case .waiting:
                return UIImage(named: "import-waiting-mailbox")!
            case .downloading:
                return UIImage(named: "import-downloading-mailbox")!
            case .restoring, .importing:
                return UIImage(named: "import-restore")!
            case .ready:
                return UIImage(named: "import-check")!
            }
        }
    }
    
    var step: STEP = .waiting
    var animationStep: STEP = .waiting
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        previousWebsocketDelegate = WebSocketManager.sharedInstance.delegate
        WebSocketManager.sharedInstance.delegate = nil
        socket = SingleWebSocket()
        socket?.delegate = self
        socket?.connect(jwt: myAccount.jwt)
        scheduleWorker.delegate = self
        scheduleWorker.start()
        
        applyTheme()
        applyLocalization()
        setupAnimations()
        handleState()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        
        checkImageView.tintColor = theme.criptextBlue
        circleProgressView.progressColor = theme.criptextBlue.cgColor
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.mainText
        processLabel.textColor = theme.mainText
        cancelProcessButton.setTitleColor(theme.markedText, for: .normal)
        view.backgroundColor = theme.overallBackground
    }
    
    func setupAnimations() {
        let animationPath = Bundle.main.path(forResource: "ImportingMobile", ofType: "json")!
        animationView = AnimationView(filePath: animationPath)
        self.animateView.addSubview(animationView!)
        animationView!.center = self.animateView.center
        animationView!.frame = self.animateView.bounds
        animationView!.contentMode = .scaleAspectFit
    }
    
    func applyLocalization() {
        titleLabel.text = String.localize("SYNC_TITLE")
        messageLabel.text = String.localize("SYNC_MESSAGE")
        cancelProcessButton.setTitle(String.localize("SYNC_CANCEL"), for: .normal)
    }
    
    func handleState(){
        cancelProcessButton.isHidden = true
        circleProgressView.isHidden = true
        checkImageView.isHidden = true
        animateView.isHidden = false
        setProcessLabel()
        
        switch(step){
        case .waiting:
            handleAnimation()
            cancelProcessButton.isHidden = false
            break
        case .downloading(let successData):
            handleAnimation()
            circleProgressView.isHidden = false
            circleProgressView.angle = 0
            circleProgressView.targetAngle = 0
            downloadMailbox(data: successData)
        case .restoring(let path, let successData):
            handleAnimation()
            restore(path: path, data: successData)
        case .importing(let path):
            circleProgressView.isHidden = false
            circleProgressView.reset(angle: 0)
            importDatabase(path: path)
        case .ready:
            animationView?.stop()
            circleProgressView.isHidden = false
            circleProgressView.reset(angle: 360)
            checkImageView.isHidden = false
            animateView.isHidden = true
            break
        }
    }
    
    func handleAnimation(){
        switch(animationStep){
        case .waiting:
            animationView?.play(fromFrame: AnimationFrameTime(181), toFrame: AnimationFrameTime(240), loopMode: .playOnce, completion: { (done) in
                guard case .downloading = self.step else {
                    self.handleAnimation()
                    return
                }
                self.animationView?.play(fromFrame: AnimationFrameTime(241), toFrame: AnimationFrameTime(300), loopMode: .playOnce, completion: { (done) in
                    self.animationStep = self.step
                    self.handleState()
                })
            })
        case .downloading:
            animationView?.play(fromFrame: AnimationFrameTime(301), toFrame: AnimationFrameTime(420), loopMode: .playOnce, completion: { (done) in
                guard case .restoring = self.step else {
                    self.handleAnimation()
                    return
                }
                self.animationView?.play(fromFrame: AnimationFrameTime(421), toFrame: AnimationFrameTime(480), loopMode: .playOnce, completion: { (done) in
                    self.animationStep = self.step
                    self.handleState()
                })
            })
        case .restoring:
            self.animationView?.play(fromFrame: AnimationFrameTime(481), toFrame: AnimationFrameTime(600), loopMode: .loop, completion: nil)
        case .importing:
            break
        case .ready:
            break
        }
    }
    
    func downloadMailbox(data: LinkSuccessData) {
        APIManager.downloadLinkDBFile(address: data.address, token: myAccount.jwt, progressCallback: { (progress) in
            self.circleProgressView.targetAngle = Double(progress * 360)
        }) { (responseData) in
            guard case let .SuccessString(filepath) =  responseData else {
                self.presentProcessInterrupted(code: .downloading)
                return
            }
            self.step = .restoring(filepath, data)
        }
    }
    
    func restore(path: String, data: LinkSuccessData) {
        guard let keyData = Data(base64Encoded: data.key) else {
            self.presentProcessInterrupted(code: .key)
            return
        }
        guard let decryptedKey = SignalHandler.decryptData(keyData, messageType: .preKey, account: myAccount, recipientId: myAccount.username, deviceId: acceptData.authorizerId) else {
            self.presentProcessInterrupted(code: .dekey)
            return
        }
        guard let decryptedPath = AESCipher.streamEncrypt(path: path, outputName: StaticFile.decryptedDB.name, keyData: decryptedKey, ivData: nil, operation: kCCDecrypt) else {
            self.presentProcessInterrupted(code: .signal)
            return
        }
        guard let decompressedPath = try? AESCipher.compressFile(path: decryptedPath, outputName: StaticFile.unzippedDB.name, compress: false) else {
            self.presentProcessInterrupted(code: .encode)
            return
        }
        CriptextFileManager.deleteFile(path: path)
        CriptextFileManager.deleteFile(path: decryptedPath)
        step = .importing(decompressedPath)
        self.handleState()
    }
    
    func importDatabase(path: String) {
        DBManager.clearMailbox(account: myAccount)
        FileUtils.deleteAccountDirectory(account: myAccount)
        
        let restoreTask = RestoreDBAsyncTask(path: path, accountId: myAccount.compoundKey, initialProgress: 80)
        restoreTask.start(progressHandler: { (progress) in
            self.circleProgressView.targetAngle = Double(progress * 360 / 100)
        }) {_ in
            self.circleProgressView.targetAngle = 360
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.step = .ready
                self.handleState()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.goToMailbox()
                }
            }
        }
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
    
    func setProcessLabel() {
        processLabel.text = step.message
    }
    
    func presentProcessInterrupted(code: CODE){
        let retryPopup = GenericDualAnswerUIPopover()
        retryPopup.initialMessage = String.localize("SYNC_CONNECTION_ISSUES")
        retryPopup.initialTitle = String.localize("SYNC_INTERRUPTED") + " (\(code.rawValue)"
        retryPopup.leftOption = String.localize("CANCEL")
        retryPopup.rightOption = String.localize("RETRY")
        retryPopup.onResponse = { accept in
            guard accept else {
                return
            }
            self.handleState()
        }
        self.presentPopover(popover: retryPopup, height: 235)
    }
}

extension SyncViewController: ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void) {
        APIManager.getLinkData(token: myAccount.jwt) { (responseData) in
            guard case let .SuccessDictionary(event) = responseData,
                let eventString = event["params"] as? String,
                let eventParams = Utils.convertToDictionary(text: eventString) else {
                    completion(false)
                    return
            }
            completion(true)
            self.newMessage(cmd: Event.Link.success.rawValue, params: eventParams)
        }
    }
    
    func dangled(){
        let retryPopup = GenericDualAnswerUIPopover()
        retryPopup.initialMessage = String.localize("DELAYED_PROCESS_RETRY")
        retryPopup.initialTitle = String.localize("ODD")
        retryPopup.onResponse = { accept in
            guard accept else {
                return
            }
            self.scheduleWorker.start()
        }
        self.presentPopover(popover: retryPopup, height: 205)
    }
}

extension SyncViewController: SingleSocketDelegate {
    func newMessage(cmd: Int32, params: [String : Any]?) {
        guard case .waiting = step else {
            return
        }
        switch(cmd){
        case Event.Link.success.rawValue:
            guard let address = params?["dataAddress"] as? String,
                let key = params?["key"] as? String else {
                    break
            }
            scheduleWorker.cancel()
            let data = LinkSuccessData(key: key, address: address)
            step = .downloading(data)
        default:
            break
        }
    }
}
