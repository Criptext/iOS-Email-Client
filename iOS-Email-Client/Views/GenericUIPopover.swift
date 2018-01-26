//
//  GenericUIPopover.swift
//  Criptext Secure Email
//
//  Created by Daniel Tigse on 4/11/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

class GenericUIPopover: UIViewController, UIPopoverPresentationControllerDelegate{
    
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    var titleCard: String!
    var imageCard: UIImage!
    var overlay: UIView?
    
    init() {
        super.init(nibName: "GenericUIPopover", bundle: nil)
        self.modalPresentationStyle = UIModalPresentationStyle.popover;
        self.popoverPresentationController?.delegate = self;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle{
        return .none
    }
    
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
    
    deinit {
        
        guard let overlay = overlay else {
            return
        }
        DispatchQueue.main.async() {
            UIView.animate(withDuration: 0.2, animations: {
                overlay.alpha = 0.0
            }, completion: { _ in
                overlay.removeFromSuperview()
            })
        }
    }
    
    override func viewDidLoad() {
        self.labelTitle.text = titleCard
        self.imageView.image = imageCard
    }
}
