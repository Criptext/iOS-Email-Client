//
//  CounterLabelUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class CounterLabelUIView: UILabel{
    let fps = 1.0/15.0
    var currentValue = 0.0
    var targetValue = 0.0
    var ratio = 0.0
    var loadingTimer: Timer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup(){
        
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        currentValue += ratio
        text = "\(Int(currentValue).description)%"
        if(currentValue >= targetValue + 1){
            text = "\(Int(targetValue).description)%"
            loadingTimer?.invalidate()
            loadingTimer = nil
        }
    }
    
    func setValue(_ value: Double, interval: Double){
        if loadingTimer == nil {
            loadingTimer = Timer.scheduledTimer(timeInterval: fps, target: self, selector: #selector(continueProgress), userInfo: nil, repeats: true)
        }
        ratio = Double(value - currentValue) * fps / interval
        targetValue = value
    }
    
    @objc func continueProgress(){
        if targetValue != currentValue {
            setNeedsDisplay()
        } else {
            loadingTimer?.invalidate()
            loadingTimer = nil
        }
    }
}
