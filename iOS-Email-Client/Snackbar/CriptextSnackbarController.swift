//
//  CriptextSnackbarController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 7/11/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material
import Motion

class CriptextSnackbarController : SnackbarController {    
    let customSnackbar = CriptextSnackbar()
    var isMyAnimating = false
    
    override func animate(snackbar status: SnackbarStatus, delay: TimeInterval = 0, animations: ((Snackbar) -> Void)? = nil, completion: ((Snackbar) -> Void)? = nil) -> MotionCancelBlock? {
        return Motion.delay(delay) { [weak self, status = status, animations = animations, completion = completion] in
            guard let s = self else {
                return
            }
            
            if .visible == status {
                s.delegate?.snackbarController?(snackbarController: s, willShow: s.customSnackbar)
            } else {
                s.delegate?.snackbarController?(snackbarController: s, willHide: s.customSnackbar)
            }
            
            s.isMyAnimating = true
            s.isUserInteractionEnabled = false
            
            UIView.animate(withDuration: 0.25, animations: { [weak self, status = status, animations = animations] in
                guard let s = self else {
                    return
                }
                
                s.layoutSnackbar(status: status)
                
                animations?(s.customSnackbar)
            }) { [weak self, status = status, completion = completion] _ in
                guard let s = self else {
                    return
                }
                
                s.isMyAnimating = false
                s.isUserInteractionEnabled = true
                s.customSnackbar.myStatus = status
                s.layoutSubviews()
                
                if .visible == status {
                    s.delegate?.snackbarController?(snackbarController: s, didShow: s.customSnackbar)
                } else {
                    s.delegate?.snackbarController?(snackbarController: s, didHide: s.customSnackbar)
                }
                
                completion?(s.customSnackbar)
            }
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        reload()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard !isAnimating else {
            return
        }
        reload()
    }
    
    override func reload() {
        customSnackbar.frame.origin.x = snackbarEdgeInsets.left
        customSnackbar.frame.size.width = view.bounds.width - snackbarEdgeInsets.left - snackbarEdgeInsets.right
        rootViewController.view.frame = view.bounds
        layoutSnackbar(status: customSnackbar.myStatus)
    }
    
    override func prepare() {
        super.prepare()
        prepareSnackbar()
    }
    
    func setBottomPadding(padding: CGFloat){
        customSnackbar.setBottomPadding(padding: padding)
    }
    
    /// Prepares the snackbar.
    private func prepareSnackbar() {
        customSnackbar.layer.zPosition = 10000
        view.addSubview(customSnackbar)
    }
    
    private func layoutSnackbar(status: SnackbarStatus) {
        if .bottom == snackbarAlignment {
            customSnackbar.frame.origin.y = .visible == status ? view.bounds.height - customSnackbar.bounds.height - snackbarEdgeInsets.bottom : view.bounds.height
        } else {
            customSnackbar.frame.origin.y = .visible == status ? snackbarEdgeInsets.top : -customSnackbar.bounds.height
        }
    }
}
