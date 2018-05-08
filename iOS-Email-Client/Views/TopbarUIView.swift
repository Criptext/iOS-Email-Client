//
//  TopbarUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/8/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class TopbarUIView: UIView {
    @IBOutlet var view: UIView!
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var archiveButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    @IBOutlet weak var markButton: UIButton!
    var delegate: NavigationToolbarDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "TopbarUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        archiveButton.imageView?.contentMode = .scaleAspectFit
        archiveButton.setImage(#imageLiteral(resourceName: "archive-icon").resize(toHeight: 20.0)!.withRenderingMode(.alwaysTemplate), for: .normal)
        trashButton.setImage(#imageLiteral(resourceName: "delete-icon").resize(toHeight: 22.0)!.withRenderingMode(.alwaysTemplate), for: .normal)
        markButton.setImage(#imageLiteral(resourceName: "mark_read").resize(toHeight: 23.0)!.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
    @IBAction func onBackPress(_ sender: Any) {
        delegate?.onBackPress()
    }
    
    @IBAction func onArchivePress(_ sender: Any) {
        delegate?.onArchiveThreads()
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
    
    func swapMarkTo(unread: Bool){
        guard unread else {
            markButton.setImage(#imageLiteral(resourceName: "mark_read").resize(toHeight: 23.0)!.withRenderingMode(.alwaysTemplate), for: .normal)
            return
        }
        markButton.setImage(#imageLiteral(resourceName: "mark_unread").resize(toHeight: 18.0)!.withRenderingMode(.alwaysTemplate), for: .normal)
    }
    
}
