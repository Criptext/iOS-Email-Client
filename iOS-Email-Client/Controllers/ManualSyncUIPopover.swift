//
//  ManualSyncUIPopover.swift
//  iOS-Email-Client
//
//  Created by Allisson on 1/3/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class ManualSyncUIPopover: BaseUIPopover {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var promptLabel: UILabel!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bottomLabel: UILabel!
    @IBOutlet weak var resendButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var hourglassImage: UIImageView!
    @IBOutlet weak var alertImage: UIImageView!
    @IBOutlet weak var progressArrowView: ProgressArrowUIView!
    var onAccept: ((AcceptData) -> Void)?
    weak var myAccount: Account!
    weak var previousWebsocketDelegate: WebSocketManagerDelegate?
    var scheduleWorker = ScheduleWorker(interval: 5.0, maxRetries: 12)
    
    init(){
        super.init("ManualSyncUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.hourglassImage.transform = CGAffineTransform(rotationAngle: (20.0 * .pi) / 180.0)
        self.previousWebsocketDelegate = WebSocketManager.sharedInstance.delegate
        self.alertImage.isHidden = true
        self.bottomLabel.isHidden = true
        self.titleLabel.text = String.localize("SYNC_REQUEST")
        WebSocketManager.sharedInstance.delegate = self
        applyTheme()
        shouldDismiss = false
        self.startSync()
        scheduleWorker.delegate = self
    }
    
    func startSync() {
        APIManager.syncBegin(token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            self.scheduleWorker.start()
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        scheduleWorker.cancel()
        WebSocketManager.sharedInstance.delegate = self.previousWebsocketDelegate
        self.previousWebsocketDelegate = nil
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        progressArrowView.progressColor = theme.criptextBlue.cgColor
        view.backgroundColor = theme.background
        titleLabel.textColor = theme.mainText
        topLabel.textColor = theme.mainText
        promptLabel.textColor = theme.mainText
        bottomLabel.textColor = theme.mainText
        cancelButton.backgroundColor = theme.popoverButton
        hourglassImage.tintColor = theme.criptextBlue
        alertImage.tintColor = theme.alert
        resendButton.setTitleColor(theme.criptextBlue, for: .normal)
        cancelButton.setTitleColor(theme.mainText, for: .normal)
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onResend(_ sender: Any) {
        APIManager.syncBegin(token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                self.dismiss(animated: true, completion: nil)
                return
            }
        }
    }
}

extension ManualSyncUIPopover: WebSocketManagerDelegate {
    func newMessage(result: EventData.Socket) {
        guard case let .SyncAccept(acceptData) = result else {
            self.bottomView.isHidden = true
            self.hourglassImage.isHidden = true
            self.progressArrowView.isHidden = true
            self.bottomLabel.isHidden = false
            self.alertImage.isHidden = false
            self.topLabel.text = String.localize("SYNC_FAIL")
            self.titleLabel.text = String.localize("SYNC_REJECTED")
            self.cancelButton.setTitle(String.localize("OK"), for: .normal)
            return
        }
        self.onAccept?(acceptData)
    }
}

extension ManualSyncUIPopover: ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void) {
        APIManager.syncStatus(token: myAccount.jwt) { (responseData) in
            if case .AuthDenied = responseData {
                completion(true)
                self.newMessage(result: .SyncDeny)
            }
            guard case let .SuccessDictionary(params) = responseData,
                let acceptData = AcceptData.fromDictionary(params) else {
                completion(false)
                return
            }
            completion(true)
            self.newMessage(result: .SyncAccept(acceptData))
        }
    }
    
    func dangled() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.scheduleWorker.start()
        }
    }
}
