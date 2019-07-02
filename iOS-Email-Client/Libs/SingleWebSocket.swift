//
//  SingleWebSocket.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Starscream

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
        let url = URL(string: "\(SOCKET_URL)?token=\(jwt)")!
        socket = WebSocket(url: url, protocols: ["criptext-protocol"])
        socket.delegate = self
        socket.connect()
    }
    
    func close(){
        jwt = nil
        socket.disconnect()
    }
}

extension SingleWebSocket: WebSocketDelegate{
    func websocketDidConnect(socket: WebSocketClient) {
        print("SingleSocket - Connected")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        print("SingleSocket - Disconnected : \(error?.localizedDescription ?? "Clean")")
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)){
            if let jwt = self.jwt {
                self.connect(jwt: jwt)
            }
        }
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        guard let event = Utils.convertToDictionary(text: text),
            let cmd = event["cmd"] as? Int32 else {
                return
        }
        let params = event["params"] as? [String: Any]
        delegate?.newMessage(cmd: cmd, params: params)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        
    }
}
