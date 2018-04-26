//
//  NavigationToolbarView.swift
//  iOS-Email-Client
//
//  Created by Gianni Carlo on 2/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol NavigationToolbarDelegate {
    func onBackPress()
    func onArchiveThreads()
    func onTrashThreads()
    func onMarkThreads()
    func onMoreOptions()
}

typealias actionFunction = ()  -> Void

class NavigationToolbarView: UIView {
    
    let nibName = "NavigationToolbarView"
    var contentView: UIView?
    var toolbarDelegate : NavigationToolbarDelegate?
    var cancelBarButton: UIBarButtonItem!
    var fixedSpace1 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
    var counterButton = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
    var centerLeftBarButton: UIBarButtonItem!
    var fixedSpace2 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
    var centerBarButton: UIBarButtonItem!
    var fixedSpace3 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
    var centerRightBarButton: UIBarButtonItem!
    var moreBarButton: UIBarButtonItem!
    var flexibleSpace1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    var flexibleSpace2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
    @IBOutlet weak var toolbarView: UIToolbar!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        guard let view = self.loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        contentView = view
        
        self.fixedSpace1.width = 22.0
        self.fixedSpace2.width = 15
        self.fixedSpace3.width = 12
        
        
        setupBarButtonItems()
        setItemsMenu()
        
    }
    
    func setItemsMenu(){
        self.toolbarView.setItems([self.cancelBarButton,
                                   self.fixedSpace1,
                                   self.counterButton,
                                   self.flexibleSpace1,
                                   self.centerLeftBarButton,
                                   self.fixedSpace2,
                                   self.centerBarButton,
                                   self.fixedSpace3,
                                   self.centerRightBarButton,
                                   self.flexibleSpace2,
                                   self.moreBarButton], animated: false)
    }
    
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: self.nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    
    func setupBarButtonItems(){
        let archiveImage = #imageLiteral(resourceName: "archive-icon").resize(toHeight: 20.0)!.withRenderingMode(.alwaysTemplate)
        let trashImage = #imageLiteral(resourceName: "delete-icon").resize(toHeight: 21.0)!.withRenderingMode(.alwaysTemplate)
        
        cancelBarButton = createButton(image: #imageLiteral(resourceName: "menu-back"), wrapped: true, action: #selector(onBackPress))
        centerLeftBarButton = createButton(image: archiveImage, wrapped: false, action: #selector(onArchiveThreads))
        centerBarButton = createButton(image: trashImage, wrapped: false, action: #selector(onTrashThreads))
        setupMarkAsRead()
        moreBarButton = createButton(image: #imageLiteral(resourceName: "dots"), wrapped: true, action: #selector(onMoreOptions))
    }
    
    func setupMarkAsRead(){
        let markImage = #imageLiteral(resourceName: "mark_read").resize(toHeight: 23.0)!.withRenderingMode(.alwaysTemplate)
        centerRightBarButton = createButton(image: markImage, wrapped: false, action: #selector(onMarkThreads))
    }
    
    func setupMarkAsUnread(){
        let markImage = #imageLiteral(resourceName: "mark_unread").resize(toHeight: 18.0)!.withRenderingMode(.alwaysTemplate)
        centerRightBarButton = createButton(image: markImage, wrapped: false, action: #selector(onMarkThreads))
    }

    func createButton(image: UIImage, wrapped: Bool, action: Selector) -> UIBarButtonItem {
        let newButton = UIButton(type: .custom)
        newButton.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        newButton.setImage(image, for: .normal)
        newButton.tintColor = UIColor(red:0.56, green:0.56, blue:0.58, alpha:1.0)
        newButton.addTarget(self, action: action, for: .touchUpInside)
        if(wrapped){
            newButton.layer.backgroundColor = UIColor(red:0.31, green:0.32, blue:0.36, alpha:1.0).cgColor
            newButton.layer.cornerRadius = 15.5
        }
        return UIBarButtonItem(customView: newButton)
    }
    
    @objc func onArchiveThreads(){
        toolbarDelegate?.onArchiveThreads()
    }
    
    @objc func onTrashThreads(){
        toolbarDelegate?.onTrashThreads()
    }
    
    @objc func onBackPress(){
        toolbarDelegate?.onBackPress()
    }
    
    @objc func onMarkThreads(){
        toolbarDelegate?.onMarkThreads()
    }
    
    @objc func onMoreOptions(){
        toolbarDelegate?.onMoreOptions()
    }
}
