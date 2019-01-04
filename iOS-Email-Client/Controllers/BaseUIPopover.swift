//
//  BaseUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation


struct PopoverComponent {
    var activePopover: BaseUIPopover?
}

protocol HasPopoverComponent {
    var popoverComponent: PopoverComponent { get set }
}

protocol PopoverInterface: HasPopoverComponent { }

extension PopoverInterface {
    var activePopover: BaseUIPopover? {
        get { return popoverComponent.activePopover }
        set { popoverComponent.activePopover = newValue }
    }
}

class BaseUIPopover: UIViewController{
    var overlay: UIView?
    var shouldDismiss = true
    
    init(_ nibName: String){
        super.init(nibName: nibName, bundle: nil)
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

extension BaseUIPopover: UIPopoverPresentationControllerDelegate{
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
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        return shouldDismiss
    }
}

extension UIViewController {
    func presentPopover(popover: UIViewController, height: Int, arrowDirections: UIPopoverArrowDirection = []){
        let theme: Theme = ThemeManager.shared.theme
        popover.preferredContentSize = CGSize(width: Constants.popoverWidth, height: height)
        popover.popoverPresentationController?.sourceView = self.view
        popover.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: self.view.frame.size.height)
        popover.popoverPresentationController?.permittedArrowDirections = arrowDirections
        popover.popoverPresentationController?.backgroundColor = theme.overallBackground
        
        if let activePopover = self.presentedViewController as? BaseUIPopover {
            activePopover.dismiss(animated: false, completion: nil)
            self.present(popover, animated: false)
            return
        }
        if let overViewController = self.presentedViewController {
            overViewController.presentPopover(popover: popover, height: height)
            return
        }
        if let overViewController = self.navigationController?.presentedViewController {
            overViewController.presentPopover(popover: popover, height: height)
            return
        }
        if let topViewController = self.navigationController?.topViewController,
            topViewController != self {
            topViewController.presentPopover(popover: popover, height: height)
            return
        }
        if let navController = self as? UINavigationController,
            let topViewController = navController.topViewController {
            topViewController.presentPopover(popover: popover, height: height)
            return
        }
        self.present(popover, animated: true)
    }
}
