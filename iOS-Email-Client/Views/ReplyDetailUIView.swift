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
    @IBOutlet weak var actionLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    var type : DirectionBorder = .none
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let maskPath = UIBezierPath(roundedRect: bounds, byRoundingCorners: getCornersByType(), cornerRadii: CGSize(width: 20, height: 20))
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        layer.mask = maskLayer
        
        let borderLayer = CAShapeLayer()
        borderLayer.frame = bounds
        borderLayer.path  = maskPath.cgPath
        borderLayer.lineWidth   = 2.0
        borderLayer.strokeColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1).cgColor
        borderLayer.fillColor   = UIColor.clear.cgColor
        
        layer.addSublayer(borderLayer)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        actionLabel.textColor = theme.mainText
        iconImageView.tintColor = theme.mainText
        backgroundColor = theme.secondBackground
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
