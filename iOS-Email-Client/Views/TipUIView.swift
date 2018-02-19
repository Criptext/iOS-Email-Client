//
//  LabelTipUI.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/9/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

@IBDesignable
final class TipUIView: UIView {
    @IBInspectable var tipColor: UIColor = UIColor.clear
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        let path = UIBezierPath()
        path.move(to: CGPoint(x: (self.frame.width / 2) - 5, y: 0))
        path.addLine(to: CGPoint(x: (self.frame.width / 2), y: -5))
        path.addLine(to: CGPoint(x: (self.frame.width / 2) + 5, y: 0))
        path.close()
        
        let shape = CAShapeLayer()
        shape.fillColor = tipColor.cgColor
        shape.path = path.cgPath
        clipsToBounds = false
        layer.addSublayer(shape)
    }
}
