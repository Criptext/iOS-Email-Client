//
//  Env.swift
//  iOS-Email-Client
//
//  Created by Pedro Iñiguez on 10/2/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

struct Env {
    private static let production: Bool = {
        let dic = ProcessInfo.processInfo.environment
        if let force = dic["forceProduction"],
            force == "true" {
            return true
        }
        
        #if DEBUG
            return false
        #elseif SUPPORT
            return true
        #else
            return true
        #endif
    }()
    
    static let googleFileName: String = {
        #if SUPPORT
        return "GoogleService-Info-Support.plist"
        #else
        return "GoogleService-Info.plist"
        #endif
    }()
    
    static let groupApp: String = {
        #if SUPPORT
        return "group.criptext.support"
        #else
        return "group.criptext.team"
        #endif
    }()
    
    static var isProduction: Bool {
        return self.production
    }
    
    static var socketURL: String {
        return "wss://stagesocket.criptext.com:3002"
    }
    
    static var domain: String {
        return "@jigl.com"
    }
    
    static var apiURL: String {
        return "https://stage.mail.criptext.com"
    }
    
    static let databaseVersion: UInt64 = 11
    static let maxRetryAttempts: Int = 10
}
