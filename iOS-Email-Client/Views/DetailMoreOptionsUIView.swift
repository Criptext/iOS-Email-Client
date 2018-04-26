//
//  EmailDetailMoreOptionsView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol DetailMoreOptionsViewDelegate{
    func onReplyPress()
    func onReplyAllPress()
    func onForwardPress()
    func onDeletePress()
    func onMarkPress()
    func onSpamPress()
    func onPrintPress()
    func onOverlayPress()
}

class DetailMoreOptionsUIView: UIView {
    @IBOutlet weak var backgroundOverlayView: UIView!
    @IBOutlet weak var optionsContainerView: UIView!
    @IBOutlet weak var optionsContainerOffsetConstraint: NSLayoutConstraint!
    var tapGestureRecognizer:UITapGestureRecognizer!
    @IBOutlet var view: UIView!
    var delegate: DetailMoreOptionsViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "DetailMoreOptionsUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        view.backgroundColor = .clear
        
        isHidden = true
        optionsContainerView.isHidden = false
        backgroundOverlayView.isHidden = true
        backgroundOverlayView.alpha = 0.0
        optionsContainerOffsetConstraint.constant = -300.0
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDismiss))
        backgroundOverlayView.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    func showMoreOptions(){
        guard isHidden else {
            return
        }
        self.isHidden = false
        self.optionsContainerView.isHidden = false
        self.backgroundOverlayView.isHidden = false
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
            self.optionsContainerOffsetConstraint.constant = 0.0
            self.backgroundOverlayView.alpha = 1.0
            self.view.layoutIfNeeded()
        })
    }
    
    func closeMoreOptions(){
        guard !isHidden else {
            return
        }
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            self.optionsContainerOffsetConstraint.constant = -300.0
            self.backgroundOverlayView.alpha = 0.0
            self.view.layoutIfNeeded()
        }, completion: {
            finished in
            self.optionsContainerView.isHidden = true
            self.backgroundOverlayView.isHidden = true
            self.isHidden = true
        })
    }
    
    @objc func onDismiss(){
        delegate?.onOverlayPress()
    }
    
    @IBAction func onReplyPress(_ sender: Any) {
        delegate?.onReplyPress()
    }
    
    @IBAction func onReplyAllPress(_ sender: Any) {
        delegate?.onReplyAllPress()
    }
    
    @IBAction func onForwardPress(_ sender: Any) {
        delegate?.onForwardPress()
    }
    
}
