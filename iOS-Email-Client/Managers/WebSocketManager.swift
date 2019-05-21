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
    private var socket : WebSocket?
    private var myAccounts = [Account?]()
    private var shouldReconnect = true
    private let SOCKET_URL = Env.socketURL
    
    private override init(){
        super.init()
    }
    
    func connect(accounts: [Account]){
        shouldReconnect = true
        let newAccounts = accounts.filter({ account in !myAccounts.contains(where: { $0?.compoundKey == account.compoundKey })  })
        myAccounts.append(contentsOf: newAccounts)
        let jwts: [String] = getValidAccounts().map({ $0.jwt })
        socket = WebSocket("\(SOCKET_URL)?token=\(jwts.joined(separator: "%2C"))", subProtocol: "criptext-protocol")
        socket?.delegate = self
    }
    
    func reconnect(){
        shouldReconnect = true
        guard let mySocket = socket,
            mySocket.readyState != .open && mySocket.readyState != .connecting else {
            return
        }
        self.connect(accounts: getValidAccounts())
    }
    
    func pause() {
        shouldReconnect = false
        socket?.event.close = {_,_,_ in }
        socket?.close()
    }
    
    func close(){
        shouldReconnect = false
        myAccounts.removeAll()
        socket?.event.close = {_,_,_ in }
        socket?.close()
    }
    
    private func getValidAccounts() -> [Account] {
        return self.myAccounts.filter({ !($0?.isInvalidated ?? true) }).map({$0!})
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
        guard let event = Utils.convertToDictionary(text: text) else {
            return
        }
        let eventParser = EventParser(accounts: getValidAccounts())
        let result = eventParser.handleSocketEvent(event: event)
        delegate?.newMessage(result: result)
    }
    
    func webSocketPong() {
        print("Pong")
    }
}
