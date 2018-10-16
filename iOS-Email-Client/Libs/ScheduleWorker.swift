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
    func dangled()
}

class ScheduleWorker {
    
    let interval: Double
    let maxRetries: Int
    var worker: DispatchWorkItem?
    var delegate: ScheduleWorkerDelegate?
    var isRunning = false
    var retries: Int = 0
    
    init(interval: Double, maxRetries: Int = 0){
        self.interval = interval
        self.maxRetries = maxRetries
    }
    
    func start() {
        retries = 0
        worker?.cancel()
        let newWorker = DispatchWorkItem(block: {
            if self.maxRetries > 0 {
                self.retries += 1
                if (self.retries > self.maxRetries) {
                    self.delegate?.dangled()
                    self.isRunning = false
                    return
                }
            }
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
