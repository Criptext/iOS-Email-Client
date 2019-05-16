//
//  WelcomeTourViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 9/10/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Lottie

class WelcomeTourViewController: UIViewController {
    
    @IBOutlet weak var envelopeView: UIView!
    @IBOutlet weak var pagesContainerView: UIView!
    @IBOutlet weak var welcomeView: UIView!
    @IBOutlet weak var lockView: UIView!
    @IBOutlet weak var privacyView: UIView!
    @IBOutlet weak var armView: UIView!
    @IBOutlet weak var powerView: UIView!
    @IBOutlet weak var pageOption1: UIButton!
    @IBOutlet weak var pageOption2: UIButton!
    @IBOutlet weak var pageOption3: UIButton!
    let spacing: CGFloat = 300
    let pageOptionColor = UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 0.58)
    let activeOptionColor = UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)
    var initialX: CGFloat = 0
    var envelopeAnimationView: AnimationView!
    var lockAnimationView: AnimationView!
    var armAnimationView: AnimationView!
    var onDismiss: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let emailPath = Bundle.main.path(forResource: "Email", ofType: "json")!
        self.envelopeAnimationView = AnimationView(filePath: emailPath)
        self.envelopeView.addSubview(envelopeAnimationView)
        envelopeAnimationView.center = self.envelopeView.center
        envelopeAnimationView.frame = self.envelopeView.bounds
        envelopeAnimationView.contentMode = .scaleAspectFit
        
        let lockPath = Bundle.main.path(forResource: "Lock", ofType: "json")!
        self.lockAnimationView = AnimationView(filePath: lockPath)
        self.lockView.addSubview(lockAnimationView)
        lockAnimationView.center = self.lockView.center
        lockAnimationView.frame = self.lockView.bounds
        lockAnimationView.contentMode = .scaleAspectFit
        
        let armPath = Bundle.main.path(forResource: "Arm", ofType: "json")!
        self.armAnimationView = AnimationView(filePath: armPath)
        self.armView.addSubview(armAnimationView)
        armAnimationView.center = self.armView.center
        armAnimationView.frame = self.armView.bounds
        armAnimationView.contentMode = .scaleAspectFit
        
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(self.draggedView(_:)))
        pagesContainerView.isUserInteractionEnabled = true
        pagesContainerView.addGestureRecognizer(gesture)
        
        initialX = welcomeView.center.x
        
        jumpToPage(1)
    }
    
    @objc func draggedView(_ sender: UIPanGestureRecognizer) {
        
        switch(sender.state) {
        case .changed:
            let translation = sender.translation(in: self.view)
            let newPositionX = welcomeView.center.x + translation.x * 1.5
            welcomeView.center = CGPoint(x: newPositionX, y: welcomeView.center.y)
            privacyView.center = CGPoint(x: newPositionX + self.spacing, y: privacyView.center.y)
            powerView.center = CGPoint(x: newPositionX + 2 * self.spacing, y: powerView.center.y)
            sender.setTranslation(CGPoint.zero, in: self.view)
        case .ended:
            repositionItems()
        default:
            break
        }
    }
    
    func repositionItems() {
        let welcomeDistance = abs(Int32(initialX - welcomeView.center.x))
        let privacyDistance = abs(Int32(initialX - privacyView.center.x))
        let powerDistance = abs(Int32(initialX - powerView.center.x))
        if (privacyDistance < welcomeDistance && privacyDistance  < powerDistance){
            jumpToPage(2)
            return
        } else if (powerDistance < welcomeDistance && powerDistance  < privacyDistance){
            jumpToPage(3)
            return
        }
        jumpToPage(1)
    }
    
    @IBAction func onContinuePress(_ sender: Any) {
        self.dismiss(animated: true, completion: {
            self.onDismiss?()
        })
    }
    
    @IBAction func onPagePress(_ sender: Any) {
        switch(sender as? UIButton){
        case pageOption1:
            jumpToPage(1)
        case pageOption2:
            jumpToPage(2)
        case pageOption3:
            jumpToPage(3)
        default:
            break
        }
    }
    
    func jumpToPage(_ page: Int){
        let newPositionX = self.initialX - CGFloat(page - 1) * self.spacing
        UIView.animate(withDuration: 0.3, animations: {
            self.pageOption1.backgroundColor = page == 1 ? self.activeOptionColor : self.pageOptionColor
            self.pageOption2.backgroundColor = page == 2 ? self.activeOptionColor : self.pageOptionColor
            self.pageOption3.backgroundColor = page == 3 ? self.activeOptionColor : self.pageOptionColor
            self.welcomeView.center = CGPoint(x: newPositionX, y: self.welcomeView.center.y)
            self.privacyView.center = CGPoint(x: newPositionX + self.spacing, y: self.privacyView.center.y)
            self.powerView.center = CGPoint(x: newPositionX + 2 * self.spacing, y: self.powerView.center.y)
        }) { (success) in
            switch(page){
            case 1:
                guard !self.envelopeAnimationView.isAnimationPlaying else {
                    break
                }
                self.envelopeAnimationView.play()
            case 2:
                guard !self.lockAnimationView.isAnimationPlaying else {
                    break
                }
                self.lockAnimationView.play(fromProgress: 0.1, toProgress: 0.9, completion: nil)
            case 3:
                guard !self.armAnimationView.isAnimationPlaying else {
                    break
                }
                self.armAnimationView.play()
            default:
                break
            }
        }
    }
}
