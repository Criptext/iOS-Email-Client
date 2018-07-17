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
    let COLLAPSED_HEIGHT : CGFloat = 0.0
    let COLLAPSED_MARGIN : CGFloat = 0.0
    let OPTION_HEIGHT : CGFloat = 25.0
    let OPTION_MARGIN : CGFloat = 15.0
    let OPTION_VERTICAL_SPACE : CGFloat = 49.0
    @IBOutlet weak var backgroundOverlayView: UIView!
    @IBOutlet weak var optionsContainerView: UIView!
    @IBOutlet weak var optionsContainerOffsetConstraint: NSLayoutConstraint!
    @IBOutlet weak var restoreButton: UIButton!
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
        moveTopMarginConstraint.constant = OPTION_MARGIN
        moveButtonHeightConstraint.constant = OPTION_HEIGHT
        restoreTopMarginConstraint.constant = OPTION_MARGIN
        restoreButtonHeightConstraint.constant = OPTION_HEIGHT
        archiveTopMarginConstraint.constant = OPTION_MARGIN
        archiveButtonHeightConstraint.constant = OPTION_HEIGHT
        switch currentLabel {
        case SystemLabel.draft.id:
            moveTopMarginConstraint.constant = COLLAPSED_MARGIN
            moveButtonHeightConstraint.constant = COLLAPSED_HEIGHT
            archiveTopMarginConstraint.constant = COLLAPSED_MARGIN
            archiveButtonHeightConstraint.constant = COLLAPSED_HEIGHT
            restoreTopMarginConstraint.constant = COLLAPSED_MARGIN
            restoreButtonHeightConstraint.constant = COLLAPSED_HEIGHT
            optionsHeightConstraint.constant = OPTION_VERTICAL_SPACE
            neededHeight = -OPTION_VERTICAL_SPACE
        case SystemLabel.spam.id:
            moveTopMarginConstraint.constant = COLLAPSED_MARGIN
            moveButtonHeightConstraint.constant = COLLAPSED_HEIGHT
            archiveTopMarginConstraint.constant = COLLAPSED_MARGIN
            archiveButtonHeightConstraint.constant = COLLAPSED_HEIGHT
            optionsHeightConstraint.constant = OPTION_VERTICAL_SPACE * 2
            restoreButton.setTitle("Not Spam", for: .normal)
            neededHeight = -(OPTION_VERTICAL_SPACE * 2)
        case SystemLabel.trash.id:
            archiveTopMarginConstraint.constant = COLLAPSED_MARGIN
            archiveButtonHeightConstraint.constant = COLLAPSED_HEIGHT
            optionsHeightConstraint.constant = OPTION_VERTICAL_SPACE * 3
            restoreButton.setTitle("Recover from Trash", for: .normal)
            neededHeight = -(OPTION_VERTICAL_SPACE * 3)
        case SystemLabel.all.id:
            archiveTopMarginConstraint.constant = COLLAPSED_MARGIN
            archiveButtonHeightConstraint.constant = COLLAPSED_HEIGHT
            restoreTopMarginConstraint.constant = COLLAPSED_MARGIN
            restoreButtonHeightConstraint.constant = COLLAPSED_HEIGHT
            optionsHeightConstraint.constant = OPTION_VERTICAL_SPACE * 2
            neededHeight = -(OPTION_VERTICAL_SPACE * 2)
        default:
            restoreTopMarginConstraint.constant = COLLAPSED_MARGIN
            restoreButtonHeightConstraint.constant = COLLAPSED_HEIGHT
            optionsHeightConstraint.constant = OPTION_VERTICAL_SPACE * 3
            neededHeight = -(OPTION_VERTICAL_SPACE * 3)
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

