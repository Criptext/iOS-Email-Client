//
//  ScheduleWorker.swift
//  iOS-Email-Client
//
//  Created by Allisson on 10/4/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

typealias WorkCompletion = ((Bool) -> Void)

protocol ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void)
}

class ScheduleWorker {
    
    var interval: Double
    var worker: DispatchWorkItem?
    var delegate: ScheduleWorkerDelegate?
    var isRunning = false
    
    init(interval: Double){
        self.interval = interval
    }
    
    func start() {
        worker?.cancel()
        let newWorker = DispatchWorkItem(block: {
            self.isRunning = self.delegate != nil
            self.delegate?.work { (success) in
                self.isRunning = false
                guard !success,
                    let currentWorker = self.worker else {
                    return
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + self.interval, execute: currentWorker)
            }
        })
        self.worker = newWorker
        DispatchQueue.main.asyncAfter(deadline: .now() + interval, execute: self.worker!)
    }
    
    func cancel() {
        worker?.cancel()
        worker = nil
    }
}
