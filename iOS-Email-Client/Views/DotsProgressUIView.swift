//
//  DotsProgressUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/15/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

@IBDesignable
final class DotsProgressUIView: UIView {
    @IBInspectable var numberOfDots: Int = 12
    @IBInspectable var radiusOfDots: Int = 3
    @IBInspectable var normalColor: UIColor = UIColor.blue
    var spacingValue: Float = 0.0
    var loadingTimer: Timer!
    var currentDot = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup(){
        spacingValue = (Float(frame.width) - Float(2 * numberOfDots * radiusOfDots))/Float(numberOfDots - 1)
        if(loadingTimer == nil){
            loadingTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(progressDots), userInfo: nil, repeats: true)
        }
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        clearDots()
        for offset in 0...(numberOfDots - 1) {
            drawDot(offset)
        }
        incrementDot()
    }
    
    func clearDots(){
        guard let sublayers = layer.sublayers else { return }
        for layer in sublayers {
            layer.removeFromSuperlayer()
        }
    }
    
    func drawDot(_ offset: Int){
        let path = UIBezierPath(arcCenter: CGPoint(x: (Int(spacingValue) * offset + offset * radiusOfDots *  2 + radiusOfDots + 1), y: radiusOfDots), radius: CGFloat(radiusOfDots), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        let shape = CAShapeLayer()
        shape.strokeColor = UIColor.clear.cgColor
        shape.fillColor = generateRandomColor(offset).cgColor
        shape.path = path.cgPath
        clipsToBounds = false
        layer.addSublayer(shape)
    }
    
    @objc func progressDots(){
        setNeedsDisplay()
    }
    
    func generateRandomColor(_ offset: Int) -> UIColor {
        var myRed: CGFloat = 0
        var myBlue: CGFloat = 0
        var myGreen: CGFloat = 0
        var myAlpha: CGFloat = 0
        normalColor.getRed(&myRed, green: &myGreen, blue: &myBlue, alpha: &myAlpha)
        return UIColor(red: myRed, green: myGreen, blue: myBlue, alpha: CGFloat(getTintOffset(offset) / Float(numberOfDots)))
    }
    
    func incrementDot(){
        currentDot += 1
        if(currentDot >= numberOfDots){
            currentDot = 0
        }
        NSLog(currentDot.description)
    }
    
    func getTintOffset(_ offset: Int) -> Float{
        var tintOffset = offset - currentDot
        if(tintOffset < 0){
            tintOffset += numberOfDots
        }
        NSLog(tintOffset.description)
        return Float(tintOffset)
    }
}
