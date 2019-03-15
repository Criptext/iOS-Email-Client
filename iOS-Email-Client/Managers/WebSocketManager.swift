//
//  WebSocketManager.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftWebSocket

protocol WebSocketManagerDelegate: class {
    func newMessage(result: EventData.Socket)
}

final class WebSocketManager: NSObject {
    static let sharedInstance = WebSocketManager()
    weak var delegate : WebSocketManagerDelegate?
    var socket : WebSocket?
    var myAccount : Account?
    var shouldReconnect = true
    let SOCKET_URL = Env.socketURL
    
    private override init(){
        super.init()
    }
    
    func connect(account: Account){
        shouldReconnect = true
        myAccount = account
        socket = WebSocket("\(SOCKET_URL)?token=\(account.jwt)", subProtocol: "criptext-protocol")
        socket?.delegate = self
    }
    
    func reconnect(){
        shouldReconnect = true
        guard let mySocket = socket,
            mySocket.readyState != .open && mySocket.readyState != .connecting,
            let account = self.myAccount else {
            return
        }
        self.connect(account: account)
    }
    
    func pause() {
        shouldReconnect = false
        socket?.event.close = {_,_,_ in }
        socket?.close()
    }
    
    func close(){
        shouldReconnect = false
        myAccount = nil
        socket?.event.close = {_,_,_ in }
        socket?.close()
    }
    
    func swapAccount(_ account: Account) {
        self.close()
        self.connect(account: account)
    }
}

extension WebSocketManager: WebSocketDelegate{
    func webSocketOpen() {
        print("Websocket - Open")
    }
    
    func webSocketClose(_ code: Int, reason: String, wasClean: Bool) {
        print("Websocket - Close : \(code) -> \(reason)")
        guard shouldReconnect else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
            self.reconnect()
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
