//
//  SyncDeviceViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/4/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class SyncRequestViewController: UIViewController {
    @IBOutlet weak var requestView: SyncRequestUIView!
    @IBOutlet weak var deniedView: SyncDeniedUIView!
    
    weak var previousWebsocketDelegate: WebSocketManagerDelegate?
    var scheduleWorker = ScheduleWorker(interval: 5.0, maxRetries: 12)
    weak var myAccount: Account!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestView.onResend = {
            self.startSync()
        }
        
        deniedView.onRetry = {
            self.startSync()
        }
        
        self.previousWebsocketDelegate = WebSocketManager.sharedInstance.delegate
        WebSocketManager.sharedInstance.delegate = self
        startSync()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        scheduleWorker.cancel()
        WebSocketManager.sharedInstance.delegate = self.previousWebsocketDelegate
        self.previousWebsocketDelegate = nil
    }
    
    func startSync() {
        requestView.isHidden = false
        deniedView.isHidden = true
        APIManager.syncBegin(token: myAccount.jwt) { (responseData) in
            guard case .Success = responseData else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            self.scheduleWorker.start()
        }
    }
    
    func accept(_ acceptData: AcceptData, _ recipientId: String, _ domain: String) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "syncviewcontroller") as! SyncViewController
        controller.modalPresentationStyle = .fullScreen
        controller.acceptData = acceptData
        controller.myAccount = myAccount
        self.present(controller, animated: true, completion: nil)
    }
    
    func notAccept() {
        self.requestView.isHidden = true
        self.deniedView.isHidden = false
    }
    
    @IBAction func onBackPress(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
}

extension SyncRequestViewController: WebSocketManagerDelegate {
    func newMessage(result: EventData.Socket) {
        guard case let .SyncAccept(acceptData, recipientId, domain) = result else {
            notAccept()
            return
        }
        accept(acceptData, recipientId, domain)
    }
}

extension SyncRequestViewController: ScheduleWorkerDelegate {
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
            self.newMessage(result: .SyncAccept(acceptData, self.myAccount.username, self.myAccount.domain ?? Env.plainDomain))
        }
    }
    
    func dangled() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.scheduleWorker.start()
        }
    }
}
