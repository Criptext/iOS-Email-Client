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

class NavigationToolbarView: UIView {
    
    let nibName = "NavigationToolbarView"
    var contentView: UIView?
    var toolbarDelegate : NavigationToolbarDelegate?
    var cancelBarButton: UIBarButtonItem!
    var fixedSpace1 = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: self, action: nil)
    var counterButton = UIBarButtonItem(title: "1", style: .plain, target: self, action: nil)
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
        
        
        setupCancelButton()
        setupCenterButtons()
        setupMoreButton()
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
    
    func setupCancelButton(){
        let cancelButton = UIButton(type: .custom)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        cancelButton.setImage(#imageLiteral(resourceName: "menu-back"), for: .normal)
        cancelButton.layer.backgroundColor = UIColor(red:0.31, green:0.32, blue:0.36, alpha:1.0).cgColor
        cancelButton.tintColor = UIColor(red:0.56, green:0.56, blue:0.58, alpha:1.0)
        cancelButton.layer.cornerRadius = 15.5
        cancelButton.addTarget(self, action: #selector(onBackPress), for: .touchUpInside)
        self.cancelBarButton = UIBarButtonItem(customView: cancelButton)
    }
    
    func setupCenterButtons(){
        let centerLeftButton = UIButton(type: .custom)
        centerLeftButton.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        centerLeftButton.setImage(#imageLiteral(resourceName: "archive-icon"), for: .normal)
        centerLeftButton.tintColor = UIColor(red:0.56, green:0.56, blue:0.58, alpha:1.0)
        centerLeftButton.addTarget(self, action: #selector(onArchiveThreads), for: .touchUpInside)
        self.centerLeftBarButton = UIBarButtonItem(customView: centerLeftButton)
        
        let centerButton = UIButton(type: .custom)
        centerButton.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        centerButton.setImage(#imageLiteral(resourceName: "delete-icon"), for: .normal)
        centerButton.tintColor = UIColor(red:0.56, green:0.56, blue:0.58, alpha:1.0)
        centerButton.addTarget(self, action: #selector(onTrashThreads), for: .touchUpInside)
        self.centerBarButton = UIBarButtonItem(customView: centerButton)
        
        setupMarkAsRead()
    }
    
    func setupMarkAsRead(){
        let centerRightButton = UIButton(type: .custom)
        centerRightButton.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        centerRightButton.setImage(#imageLiteral(resourceName: "mark_read"), for: .normal)
        centerRightButton.tintColor = UIColor(red:0.56, green:0.56, blue:0.58, alpha:1.0)
        centerRightButton.addTarget(self, action: #selector(onMarkThreads), for: .touchUpInside)
        self.centerRightBarButton = UIBarButtonItem(customView: centerRightButton)
    }
    
    func setupMarkAsUnread(){
        let centerRightButton = UIButton(type: .custom)
        centerRightButton.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        centerRightButton.setImage(#imageLiteral(resourceName: "mark_unread"), for: .normal)
        centerRightButton.tintColor = UIColor(red:0.56, green:0.56, blue:0.58, alpha:1.0)
        centerRightButton.addTarget(self, action: #selector(onMarkThreads), for: .touchUpInside)
        self.centerRightBarButton = UIBarButtonItem(customView: centerRightButton)
    }
    
    func setupMoreButton(){
        let moreButton = UIButton(type: .custom)
        moreButton.frame = CGRect(x: 0, y: 0, width: 31, height: 31)
        moreButton.setImage(#imageLiteral(resourceName: "dots"), for: .normal)
        moreButton.tintColor = UIColor(red:0.56, green:0.56, blue:0.58, alpha:1.0)
        moreButton.layer.backgroundColor = UIColor(red:0.31, green:0.32, blue:0.36, alpha:1.0).cgColor
        moreButton.layer.cornerRadius = 15.5
        moreButton.addTarget(self, action: #selector(onMoreOptions), for: .touchUpInside)
        self.moreBarButton = UIBarButtonItem(customView: moreButton)
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
