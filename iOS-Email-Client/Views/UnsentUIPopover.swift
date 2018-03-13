//
//  UnsentUIPop.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/13/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class UnsentUIPopover: UIViewController{
    @IBOutlet weak var dateLabel: UILabel!
    var overlay: UIView?
    
    init(){
        super.init(nibName: "UnsentUIPopover", bundle: nil)
        self.modalPresentationStyle = UIModalPresentationStyle.popover;
        self.popoverPresentationController?.delegate = self;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        guard let overlay = overlay else {
            return
        }
        DispatchQueue.main.async() {
            UIView.animate(withDuration: 0.1, animations: {
                overlay.alpha = 0.0
            }, completion: { _ in
                overlay.removeFromSuperview()
            })
        }
    }
}

extension UnsentUIPopover: UIPopoverPresentationControllerDelegate{
    dynamic func presentationController(_ presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        
        let parentView = presentationController.presentingViewController.view
        
        let overlay = UIView(frame: (parentView?.bounds)!)
        overlay.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
        parentView?.addSubview(overlay)
        
        let views: [String: UIView] = ["parentView": parentView!, "overlay": overlay]
        
        parentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[overlay]|", options: [], metrics: nil, views: views))
        parentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[overlay]|", options: [], metrics: nil, views: views))
        
        overlay.alpha = 0.0
        
        transitionCoordinator?.animate(alongsideTransition: { _ in
            overlay.alpha = 1.0
        }, completion: nil)
        
        self.overlay = overlay
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle{
        return .none
    }
}
