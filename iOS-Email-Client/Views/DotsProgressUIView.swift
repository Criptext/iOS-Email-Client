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
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        for offset in 0...(numberOfDots - 1) {
            drawDot(offset)
        }
    }
    
    func drawDot(_ offset: Int){
        let path = UIBezierPath(arcCenter: CGPoint(x: (Int(spacingValue) * offset + offset * radiusOfDots *  2 + radiusOfDots + 1), y: radiusOfDots), radius: CGFloat(radiusOfDots), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        let shape = CAShapeLayer()
        shape.fillColor = normalColor.cgColor
        shape.path = path.cgPath
        clipsToBounds = false
        layer.addSublayer(shape)
    }
}
