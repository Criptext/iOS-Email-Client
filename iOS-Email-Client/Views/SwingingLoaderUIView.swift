//
//  SwingingLoader.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/15/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class SwingingLoaderUIView: UIView{
    let fps = 0.02
    let width = 60.0
    var initialOffset = 0
    var loadingTimer: Timer?
    
    var nextPositionOne: CGFloat = 0.0
    var nextPositionTwo: CGFloat = 0.0
    var moveForwardOne = true
    var moveForwardTwo = true
    
    lazy var progressLayerOne: CALayer = {
        let layer = CALayer()
        nextPositionOne = frame.width/2 - CGFloat(width)
        layer.frame = CGRect(x: nextPositionOne, y: 0, width: CGFloat(width), height: frame.height)
        layer.backgroundColor = Theme().criptextBlue.cgColor
        layer.masksToBounds = true
        return layer
    }()
    
    lazy var progressLayerTwo: CALayer = {
        nextPositionTwo = frame.width/2
        let layer = CALayer()
        layer.frame = CGRect(x: self.nextPositionTwo, y: 0, width: CGFloat(width), height: frame.height)
        layer.backgroundColor = Theme().criptextBlue.cgColor
        layer.masksToBounds = true
        return layer
    }()
    
    var frameRate: CGFloat {
        return CGFloat(fps / 1.2) * (frame.width / 2.0)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        loadingTimer?.invalidate()
    }
    
    func setup(){
        layoutIfNeeded()
        layer.addSublayer(progressLayerOne)
        layer.addSublayer(progressLayerTwo)
    }
    
    @objc func continueProgress(){
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        animateFrameOne()
    }
    
    func clearCanvas(){
        guard let sublayers = progressLayerOne.sublayers else { return }
        for layer in sublayers {
            layer.removeFromSuperlayer()
        }
    }
    
    func animateFrameOne() {
        if (moveForwardOne) {
            nextPositionOne = nextPositionOne + frameRate
            if ( nextPositionOne >= frame.width / 2 - CGFloat(width) ) {
                nextPositionOne = frame.width / 2 - CGFloat(width)
                moveForwardOne = false
            }
        } else {
            nextPositionOne = nextPositionOne - frameRate
            if (nextPositionOne <= 0) {
                nextPositionOne = 0
                moveForwardOne = true
            }
        }
        nextPositionTwo = frame.width - CGFloat(width) - nextPositionOne
        
        CATransaction.setDisableActions(true)
        let newFrameOne = CGRect(x: nextPositionOne, y: 0, width: CGFloat(width), height: self.frame.height)
        self.progressLayerOne.frame = newFrameOne
        
        let newFrameTwo = CGRect(x: nextPositionTwo, y: 0, width: CGFloat(width), height: self.frame.height)
        self.progressLayerTwo.frame = newFrameTwo
        CATransaction.commit()
    }
    
    func startAnimating() {
        if(loadingTimer == nil){
            loadingTimer = Timer.scheduledTimer(timeInterval: fps, target: self, selector: #selector(continueProgress), userInfo: nil, repeats: true)
        }
    }
    
    func stopAnimating() {
        loadingTimer?.invalidate()
    }
}
