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
    @IBInspectable var numberOfDots: Int = 4
    @IBInspectable var radiusOfDots: Int = 4
    @IBInspectable var normalColor: UIColor = UIColor.blue
    var spacingValue: Float = 0.0
    var loadingTimer: Timer?
    var currentDot = 0
    var flowRight = true
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup(){
        currentDot = numberOfDots / 2
        spacingValue = Float(Int(frame.width) - 2 * radiusOfDots)/Float(numberOfDots - 1)
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
        let path = UIBezierPath(arcCenter: CGPoint(x: (Int(spacingValue) * offset + radiusOfDots), y: radiusOfDots), radius: CGFloat(radiusOfDots), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        let shape = CAShapeLayer()
        shape.strokeColor = UIColor.clear.cgColor
        shape.fillColor = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1.0).cgColor
        shape.path = path.cgPath
        clipsToBounds = false
        layer.addSublayer(shape)
    }
    
    @objc func progressDots(){
        setNeedsDisplay()
    }
    
    func generateColor(_ offset: Int) -> UIColor {
        var myRed: CGFloat = 0
        var myBlue: CGFloat = 0
        var myGreen: CGFloat = 0
        var myAlpha: CGFloat = 0
        normalColor.getRed(&myRed, green: &myGreen, blue: &myBlue, alpha: &myAlpha)
        return UIColor(red: myRed, green: myGreen, blue: myBlue, alpha: CGFloat(getTintOffset(offset)))
    }
    
    func incrementDot(){
        currentDot += flowRight ? 1 : -1
        if(flowRight && currentDot >= numberOfDots){
            currentDot = numberOfDots / 2
            flowRight = false
        }else if(!flowRight && currentDot <= 0){
            currentDot = numberOfDots / 2
            flowRight = true
        }
    }
    
    func getTintOffset(_ offset: Int) -> Float{
        if(flowRight){
            if(offset >= currentDot || offset < currentDot - numberOfDots / 2){
                return Float(0.25)
            }
            return Float(1)
        }else{
            if(offset < currentDot || offset >= currentDot + numberOfDots / 2){
                return Float(0.25)
            }
            return Float(1)
        }
    }
}
