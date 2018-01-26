//
//  CriptextSpinner.swift
//  SwiftSpinnerDemo
//
//  Created by Gianni Carlo on 5/12/17.
//  Copyright © 2017 Underplot ltd. All rights reserved.
//

import UIKit
import MMMaterialDesignSpinner

class CriptextSpinner: UIView {
    let spinner = MMMaterialDesignSpinner.init(frame: CGRect(x: 0, y: 0, width: 65, height: 65))
    let logo = UIImageView(frame: CGRect(x: 0, y: 0, width: 42, height: 34))
    var backgroundView: UIView!
    var containerView: UIView!
    var titleLabel:UILabel!
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let parent = self.superview else {
            return
        }
        
        self.frame = parent.bounds
        self.backgroundView.frame = parent.bounds
        let maxWidth = self.bounds.width
        let totalSize = CGSize.zero
        
        self.containerView.center = parent.center
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundView = UIView(frame: frame)
        self.backgroundView.backgroundColor = UIColor.white
        self.backgroundView.alpha = 0.8
        
        self.containerView = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 90 ))

        self.titleLabel = UILabel(frame: CGRect(x: 0, y: 70, width: frame.width, height: 20 ))
        self.titleLabel.text = ""
        self.titleLabel.font = UIFont.systemFont(ofSize: 14.0)
        self.titleLabel.textAlignment = .center
        self.titleLabel.textColor = UIColor.gray
        
        self.spinner.addSubview(self.logo)
        self.spinner.lineWidth = 6.0
        self.logo.center = self.spinner.center
        
        self.containerView.addSubview(self.spinner)
        self.containerView.addSubview(self.titleLabel)
        self.spinner.center = containerView.center
        self.spinner.frame = CGRect(x: self.spinner.frame.origin.x,
                                    y: 0,
                                    width: self.spinner.frame.width,
                                    height: self.spinner.frame.height)
        
        self.addSubview(backgroundView)
        self.addSubview(containerView)
        self.containerView.center = self.center
        
        self.tintColor = UIColor.lightGray
        
        self.registerForNotifications()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func registerForNotifications(){
        NotificationCenter.default.addObserver(self, selector: #selector(statusBarOrientationDidChange(_:)), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    func unregisterForNotifications(){
        NotificationCenter.default.removeObserver(self, name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    func statusBarOrientationDidChange(_ notification:Notification){
        if let _ = self.superview {
            self.updateForCurrentOrientationAnimated()
        }
    }
    
    func updateForCurrentOrientationAnimated(){
        let bounds = self.superview!.bounds
        
        print(bounds)
        self.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
        self.backgroundView.bounds = self.bounds
        self.center = self.superview!.center
        self.setNeedsDisplay()
        
    }
    
    class func show(in view:UIView?, title:String?){
        
        guard let view = view else {
            return
        }
        
        let spinner = CriptextSpinner(frame: view.bounds)
        spinner.titleLabel.text = title
        
        view.addSubview(spinner)
        spinner.startAnimating()
    }
    
    class func show(in view:UIView?, title:String?, image:UIImage?){
        
        guard let view = view else {
            return
        }
        
        let spinner = CriptextSpinner(frame: view.bounds)
        spinner.titleLabel.text = title
        spinner.logo.image = image
        
        view.addSubview(spinner)
        spinner.startAnimating()
        spinner.alpha = 0
        UIView.animate(withDuration: 0.5) {
            spinner.alpha = 1
        }
    }
    
    class func hide(from view:UIView?) {
        
        guard let view = view else {
            return
        }
        
        var found = false
        
        for subview in view.subviews {
            if subview is CriptextSpinner {
                (subview as! CriptextSpinner).unregisterForNotifications()
                found = true
                UIView.animate(withDuration: 0.5, animations: {
                    subview.alpha = 0
                }, completion: { (completed) in
                    subview.removeFromSuperview()
                })
            }
        }
        
        if !found {
            self.hide(from: view.superview)
        }
    }
    
    func startAnimating(){
        self.spinner.startAnimating()
    }
    
    func stopAnimating(){
        self.spinner.stopAnimating()
    }
}
