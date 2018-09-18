//
//  WebSocketManager.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftWebSocket

protocol WebSocketManagerDelegate {
    func newMessage(result: EventData.Socket)
}

final class WebSocketManager: NSObject {
    static let sharedInstance = WebSocketManager()
    var delegate : WebSocketManagerDelegate?
    var socket : WebSocket!
    var myAccount : Account?
    let SOCKET_URL = "wss://socket.criptext.com:3002"
    
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
        let eventHandler = EventHandler(account: account)
        let result = eventHandler.handleSocketEvent(event: event)
        delegate?.newMessage(result: result)
    }
    
    func webSocketPong() {
        print("Pong")
    }
}
