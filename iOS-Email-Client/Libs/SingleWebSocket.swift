//
//  SingleWebSocket.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftWebSocket

protocol SingleSocketDelegate {
    func newMessage(cmd: Int32, params: [String: Any]?)
}

class SingleWebSocket {
    var delegate : SingleSocketDelegate?
    var socket : WebSocket!
    var jwt: String?
    let SOCKET_URL = Env.socketURL
    
    func connect(jwt: String){
        self.jwt = jwt
        socket = WebSocket("\(SOCKET_URL)?token=\(jwt)", subProtocol: "criptext-protocol")
        socket.delegate = self
    }
    
    func close(){
        jwt = nil
        socket.event.close = {_,_,_ in }
        socket.close()
    }
}

extension SingleWebSocket: WebSocketDelegate{
    func webSocketOpen() {
        print("SingleSocket - Open")
    }
    
    func webSocketClose(_ code: Int, reason: String, wasClean: Bool) {
        print("SingleSocket - Close : \(code) -> \(reason)")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
            if let jwt = self.jwt {
                self.connect(jwt: jwt)
            }
        }
    }
    
    func webSocketError(_ error: NSError) {
        print("SingleSocket - Error : \(error.description)")
    }
    
    func webSocketMessageText(_ text: String) {
        guard let event = Utils.convertToDictionary(text: text),
            let cmd = event["cmd"] as? Int32 else {
                return
        }
        let params = event["params"] as? [String: Any]
        print(params)
        delegate?.newMessage(cmd: cmd, params: params)
    }
    
    func webSocketPong() {
        print("Pong")
    }
}
