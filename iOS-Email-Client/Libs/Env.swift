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
        guard !Env.isProduction else {
            return "wss://socket.criptext.com"
        }
        return "wss://stagesocket.criptext.com"
    }
    
    static var domain: String {
        guard !Env.isProduction else {
            return "@\(plainDomain)"
        }
        return "@\(plainDomain)"
    }
    
    static var plainDomain: String {
        guard !Env.isProduction else {
            return "criptext.com"
        }
        return "jigl.com"
    }
    
    static var apiURL: String {
        guard !Env.isProduction else {
            return "https://api.criptext.com"
        }
        return "https://stage.mail.criptext.com"
    }
    
    static var transferURL: String {
        guard !Env.isProduction else {
            return "https://transfer.criptext.com"
        }
        return "https://stagetransfer.criptext.com"
    }
    
    static var language: String {
        return Locale.current.languageCode ?? "en"
    }
    
    static let databaseVersion: UInt64 = 25
    static let maxRetryAttempts: Int = 10
    static let linkVersion = 6
    static let maxAllowedDevices = 10
    
    enum linkFileExtensions: String {
        case normal = "db"
        case compressed = "gz"
        case encrypted = "enc"
        
        static let allValues: [String] = [normal.rawValue, compressed.rawValue, encrypted.rawValue]
    }
}
