//
//  ProgressArrowUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/17/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ProgressArrowUIView: UIView{
    let fps = 0.01
    let radius = 5.0
    let width = 7.0
    var angle = 0.0
    var loadingTimer: Timer?
    var centerPositionX = 0.0
    var centerPositionY = 0.0
    var loadinDots : [Double] = []
    var DoublePi = Double.pi * 2
    var dotsSpacing = 0.3
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup(){
        centerPositionX = Double(self.frame.width / 2)
        centerPositionY = Double(self.frame.height / 2)
        if(loadingTimer == nil){
            loadingTimer = Timer.scheduledTimer(timeInterval: fps, target: self, selector: #selector(continueProgress), userInfo: nil, repeats: true)
        }
        for offset in 0...5 {
            loadinDots.append(angle - Double.pi * 1.25 - Double(offset) * dotsSpacing)
        }
    }
    
    @objc func continueProgress(){
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        clearCanvas()
        drawArrow()
        drawArc()
        drawOval()
        for offset in loadinDots {
            drawDot(offset)
        }
        checkForNewDot()
        incrementRadius()
    }
    
    func incrementRadius(){
        angle += (fps * 3)
        if(angle > DoublePi){
            angle = 0
        }
    }
    
    func clearCanvas(){
        guard let sublayers = layer.sublayers else { return }
        for layer in sublayers {
            layer.removeFromSuperlayer()
        }
    }
    
    func drawArrow(){
        let x1 = Double(self.frame.width / 2) - width
        let y1 = 0.0
        let x2 = Double(self.frame.width / 2)
        let y2 = width
        let x3 = Double(self.frame.width / 2) + width
        let y3 = 0.0
        let newPosX1 = x1 * cos(angle) - y1 * sin(angle) + radius * cos(angle)
        let newPosY1 = y1 * cos(angle) + x1 * sin(angle) + radius * sin(angle)
        let newPosX2 = x2 * cos(angle) - y2 * sin(angle) + radius * cos(angle)
        let newPosY2 = y2 * cos(angle) + x2 * sin(angle) + radius * sin(angle)
        let newPosX3 = x3 * cos(angle) - y3 * sin(angle) + radius * cos(angle)
        let newPosY3 = y3 * cos(angle) + x3 * sin(angle) + radius * sin(angle)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: newPosX1 + centerPositionX, y: newPosY1 + centerPositionY))
        path.addLine(to: CGPoint(x: newPosX2 + centerPositionX, y: newPosY2 + centerPositionY))
        path.addLine(to: CGPoint(x: newPosX3 + centerPositionX, y: newPosY3 + centerPositionY))
        path.close()
        
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.white.cgColor
        shape.path = path.cgPath
        clipsToBounds = false
        layer.addSublayer(shape)
    }
    
    func drawArc(){
        let path = UIBezierPath(arcCenter: CGPoint(x: centerPositionX, y: centerPositionY), radius: self.frame.width / 2 + CGFloat(width - 2), startAngle: CGFloat(angle - Double.pi * 1.25), endAngle:CGFloat(angle), clockwise: true)
        let shape = CAShapeLayer()
        shape.strokeColor = UIColor.white.cgColor
        shape.fillColor = UIColor.clear.cgColor
        shape.lineWidth = 4.0
        shape.path = path.cgPath
        clipsToBounds = false
        layer.addSublayer(shape)
    }
    
    func drawOval(_ offset : Double = 0.0){
        let posX = (Double(self.frame.width / 2) + width - 2) * cos(angle - Double.pi * 1.25 - offset * 0.2)
        let posY = (Double(self.frame.height / 2) + width - 2) * sin(angle - Double.pi * 1.25 - offset * 0.2)
        let path = UIBezierPath(arcCenter: CGPoint(x: posX + centerPositionX, y: posY + centerPositionY), radius: CGFloat(2), startAngle: CGFloat(0), endAngle:CGFloat(DoublePi), clockwise: true)
        let shape = CAShapeLayer()
        shape.strokeColor = UIColor.clear.cgColor
        shape.fillColor = UIColor.white.cgColor
        shape.path = path.cgPath
        clipsToBounds = false
        layer.addSublayer(shape)
    }
    
    func drawDot(_ offset : Double = 0.0){
        let posX = (Double(self.frame.width / 2) + width - 2) * cos(offset)
        let posY = (Double(self.frame.height / 2) + width - 2) * sin(offset)
        let path = UIBezierPath(arcCenter: CGPoint(x: posX + centerPositionX, y: posY + centerPositionY), radius: CGFloat(2 * getDotSizeFactor(offset)), startAngle: CGFloat(0), endAngle:CGFloat(DoublePi), clockwise: true)
        let shape = CAShapeLayer()
        shape.strokeColor = UIColor.clear.cgColor
        shape.fillColor = UIColor.white.cgColor
        shape.path = path.cgPath
        clipsToBounds = false
        layer.addSublayer(shape)
    }
    
    func getAngleDiff(_ angle: Double) -> Double{
        let myAngle = angle < 0 ? angle + DoublePi : angle
        var priorAngle = self.angle - Double.pi * 1.25
        priorAngle = priorAngle < 0 ? priorAngle + DoublePi : priorAngle
        if priorAngle < myAngle {
            priorAngle += DoublePi
        }
        return priorAngle - myAngle
    }
    
    func getDotSizeFactor(_ angle: Double) -> Double{
        let angleDiff = getAngleDiff(angle)
        return (0.31 * 6 - angleDiff)/(0.31 * 6)
    }
    
    func checkForNewDot(){
        let angleDiff = getAngleDiff(loadinDots[5])
        guard angleDiff > (dotsSpacing * 6) else {
            return
        }
        loadinDots.removeLast()
        loadinDots.insert(self.angle - Double.pi * 1.25, at: 0)
    }
}
