//
//  EmailDetailData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class EmailDetailData{
    var emails: Results<Email>!
    var bodies = [Int: String]()
    var observerToken: NotificationToken?
    var emailStates = [Int: Email.State]()
    var labels = [Label]()
    var subject = ""
    var accountEmail = ""
    var selectedLabel : Int
    var threadId : String
    init(threadId: String, label: Int){
        self.threadId = threadId
        self.selectedLabel = label
    }
    
    func rebuildLabels(){
        var labelsSet = Set<Label>()
        for email in emails {
            labelsSet.formUnion(email.labels)
        }
        labels = Array(labelsSet)
    }
    
    func getState(_ key: Int) -> Email.State {
        guard let state = emailStates[key] else {
            var newState = Email.State()
            newState.isExpanded = true
            emailStates[key] = newState
            return getState(key)
        }
        return state
    }
    
    func setState(_ key: Int, isExpanded: Bool? = nil, isUnsending: Bool? = nil, cellHeight: CGFloat? = nil, trusted: Bool? = nil,
                  hasLightsOn: Bool? = nil) {
        guard var state = emailStates[key] else {
            emailStates[key] = Email.State()
            setState(key, isExpanded: isExpanded, isUnsending: isUnsending, cellHeight: cellHeight)
            return
        }
        if let expanded = isExpanded {
            state.isExpanded = expanded
        }
        if let unsending = isUnsending {
            state.isUnsending = unsending
        }
        if let height = cellHeight {
            state.cellHeight = height
        }
        if let trustedOnce = trusted {
            state.trustedOnce = trustedOnce
        }
        if let hasTurnedLights = hasLightsOn {
            state.hasTurnedOnLights = hasTurnedLights
        }
        emailStates[key] = state
    }
}
