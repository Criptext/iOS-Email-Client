//
//  CircleProgressBarUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 11/5/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class CircleProgressBarUIView: UIView{
    var progressColor: CGColor = UIColor.white.cgColor
    let fps = 0.01
    let radius = 5.0
    let width = 7.0
    var angle = 0.0
    var targetAngle = 0.0
    var loadingTimer: Timer?
    var centerPositionX = 0.0
    var centerPositionY = 0.0
    var DoublePi = Double.pi * 2
    
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
        centerPositionX = Double(self.frame.width / 2)
        centerPositionY = Double(self.frame.height / 2)
        if(loadingTimer == nil){
            loadingTimer = Timer.scheduledTimer(timeInterval: fps, target: self, selector: #selector(continueProgress), userInfo: nil, repeats: true)
        }
    }
    
    @objc func continueProgress(){
        setNeedsDisplay()
    }
    
    func reset(angle: Double) {
        self.angle = angle
        self.targetAngle = angle
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        clearCanvas()
        drawArc()
        incrementRadius()
    }
    
    func incrementRadius(){
        angle += (fps * 3)
        if(angle > targetAngle){
            angle = targetAngle
        }
    }
    
    func clearCanvas(){
        guard let sublayers = layer.sublayers else { return }
        for layer in sublayers {
            layer.removeFromSuperlayer()
        }
    }
    
    func drawArc(){
        let path = UIBezierPath(arcCenter: CGPoint(x: centerPositionX, y: centerPositionY), radius: self.frame.width / 2 + CGFloat(width - 2), startAngle: 0, endAngle:CGFloat(angle), clockwise: true)
        let shape = CAShapeLayer()
        shape.strokeColor = progressColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = 4.0
        shape.path = path.cgPath
        clipsToBounds = false
        layer.addSublayer(shape)
    }
}
