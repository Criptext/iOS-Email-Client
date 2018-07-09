//
//  TopbarUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/8/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol NavigationToolbarDelegate {
    func onBackPress()
    func onMoveThreads()
    func onTrashThreads()
    func onMarkThreads()
    func onMoreOptions()
}

class TopbarUIView: UIView {
    let HORIZONTAL_CENTER : CGFloat = 0.0
    let MARK_LEFT_MARGIN : CGFloat = 17.0
    let ADJUST_MARGIN_FOR_LESS_ICONS : CGFloat = 31.0
    @IBOutlet var view: UIView!
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var archiveButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var markButton: UIButton!
    @IBOutlet weak var trashButtonXConstraint: NSLayoutConstraint!
    @IBOutlet weak var markButtonLeadingConstraint: NSLayoutConstraint!
    var delegate: NavigationToolbarDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "TopbarUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        archiveButton.imageView?.contentMode = .scaleAspectFit
        trashButton.imageView?.contentMode = .scaleAspectFit
        markButton.setImage(#imageLiteral(resourceName: "mark_read").resize(toHeight: 23.0)!.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    @IBAction func onBackPress(_ sender: Any) {
        delegate?.onBackPress()
    }
    
    @IBAction func onArchivePress(_ sender: Any) {
        delegate?.onMoveThreads()
    }
    
    @IBAction func onDeletePress(_ sender: Any) {
        delegate?.onTrashThreads()
    }
    
    @IBAction func onMarkAsReadPress(_ sender: Any) {
        delegate?.onMarkThreads()
    }
    
    @IBAction func onMoreOptionsPress(_ sender: Any) {
        delegate?.onMoreOptions()
    }
    
    func swapTrashIcon(labelId: Int){
        archiveButton.isHidden = false
        markButtonLeadingConstraint.constant = MARK_LEFT_MARGIN
        trashButtonXConstraint.constant = HORIZONTAL_CENTER
        
        switch(labelId){
        case SystemLabel.trash.id:
            trashButton.setImage(#imageLiteral(resourceName: "toolbar_trash_permanent"), for: .normal)
        case SystemLabel.spam.id, SystemLabel.draft.id:
            trashButton.setImage(#imageLiteral(resourceName: "toolbar_trash_permanent"), for: .normal)
            archiveButton.isHidden = true
            markButtonLeadingConstraint.constant = ADJUST_MARGIN_FOR_LESS_ICONS
            trashButtonXConstraint.constant = -ADJUST_MARGIN_FOR_LESS_ICONS
        default:
            trashButton.setImage(#imageLiteral(resourceName: "toolbar-trash"), for: .normal)
        }
    }
        
    func swapMarkTo(unread: Bool){
        guard unread else {
            markButton.setImage(#imageLiteral(resourceName: "mark_read").resize(toHeight: 24.0)!.withRenderingMode(.alwaysTemplate), for: .normal)
            return
        }
        markButton.setImage(#imageLiteral(resourceName: "mark_unread").resize(toHeight: 24.0)!.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
}
