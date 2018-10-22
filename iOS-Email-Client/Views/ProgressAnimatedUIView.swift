//
//  ProgressAnimatedUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iñiguez on 10/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class ProgressAnimatedUIView: UIView{
    let fps = 0.02
    let width = 15
    var progress: Float = 0.0
    var initialOffset = 0
    var loadingTimer: Timer?
    
    lazy var progressLayer: CALayer = {
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: frame.width * CGFloat(progress), height: frame.height)
        layer.contentsGravity = kCAGravityLeft
        layer.masksToBounds = true
        layer.cornerRadius = frame.height / 2
        return layer
    }()
    
    lazy var backgroundLayer: CALayer = {
        let layer = CALayer()
        layer.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        layer.backgroundColor = UIColor(red: 0, green: 145/255, blue: 1, alpha: 0.25).cgColor
        layer.contentsGravity = kCAGravityLeft
        layer.masksToBounds = true
        layer.cornerRadius = frame.height / 2
        return layer
    }()
    
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
        if(loadingTimer == nil){
            loadingTimer = Timer.scheduledTimer(timeInterval: fps, target: self, selector: #selector(continueProgress), userInfo: nil, repeats: true)
        }
        layer.cornerRadius = frame.height / 2
        clipsToBounds = true
        layoutIfNeeded()
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(progressLayer)
    }
    
    @objc func continueProgress(){
        setNeedsDisplay()
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        clearCanvas()
        drawStripes()
        incrementRadius()
    }
    
    func incrementRadius(){
        initialOffset += 1
        if initialOffset >= width * 2 {
            initialOffset = 0
        }
    }
    
    func clearCanvas(){
        guard let sublayers = progressLayer.sublayers else { return }
        for layer in sublayers {
            layer.removeFromSuperlayer()
        }
    }
    
    func drawStripes() {
        let numberOfStripes = Int(ceil(Double(frame.width) / Double(width)) + 6)
        for stripeOffset in 0...numberOfStripes {
            drawStripe(offset: stripeOffset - 3)
        }
    }
    
    func drawStripe(offset: Int){
        let height = frame.height
        let path = UIBezierPath()
        path.move(to: CGPoint(x: offset * width + initialOffset, y: 0))
        path.addLine(to: CGPoint(x: CGFloat(offset * width + initialOffset - width / 2), y: height))
        path.addLine(to: CGPoint(x: CGFloat(offset * width + initialOffset + width - width / 2), y: height))
        path.addLine(to: CGPoint(x: offset * width + initialOffset + width, y: 0))
        path.close()
        
        let shape = CAShapeLayer()
        shape.fillColor = offset % 2 == 0 ? UIColor.mainUI.cgColor : UIColor(red: 86/255, green: 195/255, blue: 255/255, alpha: 1.0).cgColor
        shape.path = path.cgPath
        clipsToBounds = false
        progressLayer.addSublayer(shape)
    }
    
    func animateProgress(value: Double, duration: Double) {
        self.progress = Float(value / 100)
        let oldFrame = (self.progressLayer.presentation()?.value(forKey: #keyPath(CALayer.frame)) as? CGRect) ?? self.progressLayer.frame
        let newFrame = CGRect(x: 0, y: 0, width: self.frame.width * CGFloat(self.progress), height: self.frame.height)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut))

        let frameAnimation = CABasicAnimation(keyPath: #keyPath(CALayer.frame))
        frameAnimation.fromValue = oldFrame
        frameAnimation.toValue = newFrame
        
        self.progressLayer.frame = newFrame
        self.progressLayer.add(frameAnimation, forKey: #keyPath(CALayer.frame))
        CATransaction.commit()
    }
}
