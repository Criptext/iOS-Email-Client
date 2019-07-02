//
//  CriptextDefaults.swift
//  iOS-Email-Client
//
//  Created by Allisson on 12/3/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class CriptextDefaults {
    let defaults = UserDefaults.standard
    let groupDefaults = UserDefaults.init(suiteName: Env.groupApp) ?? UserDefaults.standard
    
    var lastTimeResent: Double {
        get {
            return defaults.double(forKey: "lastTimeResent")
        }
        set (value) {
            defaults.set(value, forKey: "lastTimeResent")
        }
    }
    
    var welcomeTour: Bool {
        get {
            return defaults.bool(forKey: Guide.welcomeTour.rawValue)
        }
        set (value) {
            defaults.set(value, forKey: Guide.welcomeTour.rawValue)
        }
    }
    
    var guideAttachments: Bool {
        get {
            return defaults.bool(forKey: Guide.attachments.rawValue)
        }
        set (value) {
            defaults.set(value, forKey: Guide.attachments.rawValue)
        }
    }
    
    var guideComposer: Bool {
        get {
            return defaults.bool(forKey: Guide.composer.rawValue)
        }
        set (value) {
            defaults.set(value, forKey: Guide.composer.rawValue)
        }
    }
    
    var guideFeed: Bool {
        get {
            return defaults.bool(forKey: Guide.feed.rawValue)
        }
        set (value) {
            defaults.set(value, forKey: Guide.feed.rawValue)
        }
    }
    
    var guideUnsend: Bool {
        get {
            return defaults.bool(forKey: Guide.unsend.rawValue)
        }
        set (value) {
            defaults.set(value, forKey: Guide.unsend.rawValue)
        }
    }
    
    var guideLock: Bool {
        get {
            return defaults.bool(forKey: Guide.secureLock.rawValue)
        }
        set (value) {
            defaults.set(value, forKey: Guide.secureLock.rawValue)
        }
    }
    
    //SHARED DEFAULTS
    
    var hasActiveAccount: Bool {
        return groupDefaults.string(forKey: "activeAccount") != nil
    }
    
    var activeAccount: String? {
        get {
            return groupDefaults.string(forKey: "activeAccount")
        }
        set (value) {
            groupDefaults.set(value, forKey: "activeAccount")
        }
    }
    
    var hasPIN : Bool {
        return groupDefaults.string(forKey: PIN.lock.rawValue) != nil
    }
    
    var hasFingerPrint: Bool {
        return groupDefaults.bool(forKey: PIN.fingerprint.rawValue)
    }
    
    var hasFaceID : Bool {
        return groupDefaults.bool(forKey: PIN.faceid.rawValue)
    }
    
    var pin: String? {
        get {
            return groupDefaults.string(forKey: PIN.lock.rawValue)
        }
        set (value) {
            groupDefaults.set(value, forKey: PIN.lock.rawValue)
        }
    }
    
    var previewDisable: Bool {
        get {
            return groupDefaults.bool(forKey: Config.preview.rawValue)
        }
        set (value) {
            groupDefaults.set(value, forKey: Config.preview.rawValue)
        }
    }
    
    var fingerprintUnlock: Bool {
        get {
            return groupDefaults.bool(forKey: Config.fingerPrint.rawValue)
        }
        set (value) {
            groupDefaults.set(value, forKey: Config.fingerPrint.rawValue)
        }
    }
    
    var faceUnlock: Bool {
        get {
            return groupDefaults.bool(forKey: Config.faceid.rawValue)
        }
        set (value) {
            groupDefaults.set(value, forKey: Config.faceid.rawValue)
        }
    }
    
    var appStateActive: Bool {
        get {
            return groupDefaults.bool(forKey: Config.appStateActive.rawValue)
        }
        set (value) {
            groupDefaults.set(value, forKey: Config.appStateActive.rawValue)
        }
    }
    
    var lockTimer: String {
        get {
            return groupDefaults.string(forKey: Config.lockTimer.rawValue) ?? PIN.time.immediately.rawValue
        }
        set (value) {
            groupDefaults.set(value, forKey: Config.lockTimer.rawValue)
        }
    }
    
    var goneTimestamp: Double {
        get {
            return groupDefaults.double(forKey: Config.goneTimestamp.rawValue)
        }
        set (value) {
            groupDefaults.set(value, forKey: Config.goneTimestamp.rawValue)
        }
    }
    
    var pinAttempts: Int {
        get {
            return groupDefaults.integer(forKey: Config.pinAttempts.rawValue)
        }
        set (value) {
            groupDefaults.set(value, forKey: Config.pinAttempts.rawValue)
        }
    }
    
    var themeMode: String {
        get {
            return groupDefaults.string(forKey: ThemeMode.themeMode.rawValue) ?? "Default"
        }
        set (value) {
            groupDefaults.set(value, forKey: ThemeMode.themeMode.rawValue)
        }
    }
    
    enum Guide: String {
        case welcomeTour = "welcomeTour"
        case attachments = "guideAttachments"
        case composer = "guideComposer"
        case feed = "guideFeed"
        case unsend = "guideUnsend"
        case secureLock = "guideSecure"
    }
    
    enum Config: String {
        case preview = "previewDisable"
        case fingerPrint = "fingerprintUnlock"
        case faceid = "faceUnlock"
        case lockTimer = "lockTimer"
        case goneTimestamp = "goneTimestamp"
        case pinAttempts = "pinAttempts"
        case appStateActive = "appActive"
    }
    
}

extension CriptextDefaults {
    func removeActiveAccount(){
        groupDefaults.removeObject(forKey: "activeAccount")
    }
    
    func removePasscode() {
        groupDefaults.removeObject(forKey: PIN.lock.rawValue)
    }
    
    func removeConfig() {
        groupDefaults.removeObject(forKey: "activeAccount")
        groupDefaults.removeObject(forKey: PIN.lock.rawValue)
        groupDefaults.removeObject(forKey: PIN.fingerprint.rawValue)
        groupDefaults.removeObject(forKey: PIN.faceid.rawValue)
        groupDefaults.removeObject(forKey: PIN.goneTimestamp.rawValue)
        groupDefaults.removeObject(forKey: PIN.lockTimer.rawValue)
        groupDefaults.removeObject(forKey: ThemeMode.themeMode.rawValue)
    }
    
    func removeQuickGuideFlags(){
        defaults.removeObject(forKey: "guideAttachments")
        defaults.removeObject(forKey: "guideUnsend")
        defaults.removeObject(forKey: "guideFeed")
        defaults.removeObject(forKey: "guideComposer")
    }
    
    func migrate(){
        if let activeAccount = defaults.string(forKey: "activeAccount"),
            groupDefaults.string(forKey: "activeAccount") == nil {
            defaults.removeObject(forKey: "activeAccount")
            groupDefaults.setValue(activeAccount, forKey: "activeAccount")
        }
        if let pin = defaults.string(forKey: PIN.lock.rawValue) {
            let fingerprint = defaults.bool(forKey: PIN.fingerprint.rawValue)
            let faceid = defaults.bool(forKey: PIN.faceid.rawValue)
            let goneTimestamp = defaults.double(forKey: PIN.goneTimestamp.rawValue)
            let lockTimer = defaults.string(forKey: PIN.lockTimer.rawValue)
            
            self.pin = pin
            self.fingerprintUnlock = fingerprint
            self.faceUnlock = faceid
            self.goneTimestamp = goneTimestamp
            
            if let stringTimer = lockTimer {
                self.lockTimer = stringTimer
            }
            defaults.removeObject(forKey: PIN.lock.rawValue)
        }
    }
    
}

enum ThemeMode: String {
    case themeMode = "Default"
}

enum PIN: String {
    case lock = "lock"
    case fingerprint = "fingerprintUnlock"
    case faceid = "faceUnlock"
    case lockTimer = "lockTimer"
    case goneTimestamp = "goneTimestamp"
    
    enum time: String {
        case immediately = "Immediately"
        case oneminute = "1 minute"
        case fiveminutes = "5 minutes"
        case fifteenminutes = "15 minutes"
        case onehour = "1 hour"
        case oneday = "24 hours"
    }
}
