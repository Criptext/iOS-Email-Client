//
//  WebSocketManager.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftWebSocket

final class WebSocketManager: NSObject {
    static let sharedInstance = WebSocketManager()
    var eventDelegate : EventHandlerDelegate?
    var socket : WebSocket!
    var myAccount : Account?
    let SOCKET_URL = "ws://stage.socket.criptext.com"
    
    private override init(){
        super.init()
    }
    
    func connect(account: Account){
        myAccount = account
        socket = WebSocket("\(SOCKET_URL)?token=\(account.jwt)", subProtocol: "criptext-protocol")
        socket.delegate = self
    }
    
    func close(){
        myAccount = nil
        socket.event.close = {_,_,_ in }
        socket.close()
    }
}

extension WebSocketManager: WebSocketDelegate{
    func webSocketOpen() {
        print("Websocket - Open")
    }
    
    func webSocketClose(_ code: Int, reason: String, wasClean: Bool) {
        print("Websocket - Close : \(code) -> \(reason)")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
            if let account = self.myAccount {
                self.connect(account: account)
            }
        }
    }
    
    func webSocketError(_ error: NSError) {
        print("Websocket - Error : \(error.description)")
    }
    
    func webSocketMessageText(_ text: String) {
        guard let event = Utils.convertToDictionary(text: text),
            let account = self.myAccount else {
            return
        }
        let eventHandler = EventHandler(account: account, fromWS: true)
        eventHandler.eventDelegate = self
        eventHandler.handleEvents(events: [event])
    }
    
    func webSocketPong() {
        print("Pong")
    }
}

extension WebSocketManager: EventHandlerDelegate {
    func didReceiveEvents(result: EventData.Result) {
        eventDelegate?.didReceiveEvents(result: result)
    }
}
