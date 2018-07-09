//
//  GeneralMoreOptionsUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol GeneralMoreOptionsViewDelegate {
    func onDismissPress()
    func onMoveToPress()
    func onAddLabesPress()
    func onArchivePress()
    func onRestorePress()
}

class GeneralMoreOptionsUIView : UIView {
    @IBOutlet weak var backgroundOverlayView: UIView!
    @IBOutlet weak var optionsContainerView: UIView!
    @IBOutlet weak var optionsContainerOffsetConstraint: NSLayoutConstraint!
    var tapGestureRecognizer:UITapGestureRecognizer!
    @IBOutlet var view: UIView!
    @IBOutlet weak var optionsHeightConstraint: NSLayoutConstraint!
    
    
    @IBOutlet weak var moveTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var moveButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var restoreTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var restoreButtonHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var archiveTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var archiveButtonHeightConstraint: NSLayoutConstraint!
    
    var neededHeight: CGFloat = -196.0
    var delegate : GeneralMoreOptionsViewDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "GeneralMoreOptionsUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        view.backgroundColor = .clear
        
        isHidden = true
        optionsContainerView.isHidden = false
        backgroundOverlayView.isHidden = true
        backgroundOverlayView.alpha = 0.0
        optionsContainerOffsetConstraint.constant = neededHeight
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDismiss))
        backgroundOverlayView.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    func handleCurrentLabel(currentLabel: Int){
        moveTopMarginConstraint.constant = 15
        moveButtonHeightConstraint.constant = 25
        restoreTopMarginConstraint.constant = 15
        restoreButtonHeightConstraint.constant = 25
        archiveTopMarginConstraint.constant = 15
        archiveButtonHeightConstraint.constant = 25
        switch currentLabel {
        case SystemLabel.draft.id:
            moveTopMarginConstraint.constant = 0
            moveButtonHeightConstraint.constant = 0
            archiveTopMarginConstraint.constant = 0
            archiveButtonHeightConstraint.constant = 0
            restoreTopMarginConstraint.constant = 0
            restoreButtonHeightConstraint.constant = 0
            optionsHeightConstraint.constant = 49.0
            neededHeight = -49.0
        case SystemLabel.spam.id:
            moveTopMarginConstraint.constant = 0
            moveButtonHeightConstraint.constant = 0
            archiveTopMarginConstraint.constant = 0
            archiveButtonHeightConstraint.constant = 0
            optionsHeightConstraint.constant = 98.0
            neededHeight = -98.0
        case SystemLabel.trash.id:
            archiveTopMarginConstraint.constant = 0
            archiveButtonHeightConstraint.constant = 0
            optionsHeightConstraint.constant = 147
            neededHeight = -147.0
        case SystemLabel.all.id:
            archiveTopMarginConstraint.constant = 0
            archiveButtonHeightConstraint.constant = 0
            restoreTopMarginConstraint.constant = 0
            restoreButtonHeightConstraint.constant = 0
            optionsHeightConstraint.constant = 98.0
            neededHeight = -98.0
        default:
            restoreTopMarginConstraint.constant = 0
            restoreButtonHeightConstraint.constant = 0
            optionsHeightConstraint.constant = 147
            neededHeight = -147.0
        }
        self.view.layoutIfNeeded()
    }
    
    func showMoreOptions(){
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
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            self.optionsContainerOffsetConstraint.constant = self.neededHeight
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
        delegate?.onDismissPress()
    }
    
    @IBAction func onMoveToPress(_ sender: Any) {
        delegate?.onMoveToPress()
    }
    
    @IBAction func onAddLabelsPress(_ sender: Any) {
        delegate?.onAddLabesPress()
    }
    
    @IBAction func onArchivePress(_ sender: Any) {
        delegate?.onArchivePress()
    }
    
    @IBAction func onRestorePress(_ sender: Any) {
        delegate?.onRestorePress()
    }
    
}

