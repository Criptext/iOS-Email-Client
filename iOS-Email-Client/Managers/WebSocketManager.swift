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
    var eventDelegates = [String: EventHandlerDelegate]()
    var socket : WebSocket!
    var myAccount : Account!
    let SOCKET_URL = "ws://stage.socket.criptext.com"
    
    private override init(){
        super.init()
    }
    
    func connect(account: Account){
        myAccount = account
        socket = WebSocket("\(SOCKET_URL)?recipientId=\(account.username)&deviceId=\(1)", subProtocol: "criptext-protocol")
        socket.delegate = self
    }
    
    func close(){
        socket.event.close = {_,_,_ in }
        socket.close()
    }
    
    func addListener(identifier: String, listener: EventHandlerDelegate){
        eventDelegates[identifier] = listener
    }
    
    func removeListener(identifier: String){
        eventDelegates[identifier] = nil
    }
}

extension WebSocketManager: WebSocketDelegate{
    func webSocketOpen() {
        print("Websocket - Open")
    }
    
    func webSocketClose(_ code: Int, reason: String, wasClean: Bool) {
        print("Websocket - Close : \(code) -> \(reason)")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
            self.connect(account: self.myAccount)
        }
    }
    
    func webSocketError(_ error: NSError) {
        print("Websocket - Error : \(error.description)")
    }
    
    func webSocketMessageText(_ text: String) {
        guard let event = Utils.convertToDictionary(text: text) else {
            return
        }
        let eventHandler = EventHandler(account: myAccount)
        eventHandler.eventDelegate = self
        eventHandler.handleEvents(events: [event])
    }
    
    func webSocketPong() {
        print("Pong")
    }
}

extension WebSocketManager: EventHandlerDelegate {
    func didReceiveNewEmails() {
        eventDelegates.values.forEach { (eventDelegate) in
            eventDelegate.didReceiveNewEmails()
        }
    }
}
