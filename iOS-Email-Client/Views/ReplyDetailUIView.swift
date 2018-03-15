//
//  ReplyDetailUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/1/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ReplyDetailUIView: UIButton{
    @IBInspectable var typeAdapter: Int{
        get {
            return self.type.rawValue
        }
        set(typeValue) {
            self.type = DirectionBorder(rawValue: typeValue) ?? .none
        }
    }
    var type : DirectionBorder = .none
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: getCornersByType(), cornerRadii: CGSize(width: 20, height: 20))
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
        
        let borderLayer = CAShapeLayer()
        borderLayer.frame = bounds
        borderLayer.path  = maskPath.cgPath
        borderLayer.lineWidth   = 4.0
        borderLayer.strokeColor = UIColor(red: 232/255, green: 232/255, blue: 232/255, alpha: 1).cgColor
        borderLayer.fillColor   = UIColor.clear.cgColor
        
        layer.addSublayer(borderLayer)
    }
    
    func getCornersByType() -> UIRectCorner{
        switch(type){
        case .left: return [UIRectCorner.topLeft, UIRectCorner.bottomLeft]
        case .right: return [UIRectCorner.topRight, UIRectCorner.bottomRight]
        default: return []
        }
    }
    
    enum DirectionBorder: Int {
        case none = 0
        case left = 1
        case right = 2
    }
}
