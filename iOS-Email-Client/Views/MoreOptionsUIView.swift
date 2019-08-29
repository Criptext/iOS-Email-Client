//
//  GeneralMoreOptionsUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol MoreOptionsViewInterface: class {
    var optionsCount: Int { get set }
    func handleOptionCell(cell: AccountFromCell, index: Int)
    func handleOptionSelected(index: Int)
    func changeOptions(label: Int)
    func onClose()
}

class MoreOptionsUIView : UIView {
    let OPTION_HEIGHT : CGFloat = 40.0
    @IBOutlet weak var backgroundOverlayView: UIView!
    @IBOutlet weak var optionsContainerView: UIView!
    @IBOutlet weak var optionsContainerOffsetConstraint: NSLayoutConstraint!
    @IBOutlet var view: UIView!
    @IBOutlet weak var optionsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: MoreOptionsViewInterface?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "MoreOptionsUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        view.backgroundColor = .clear
        
        isHidden = true
        optionsContainerView.isHidden = false
        backgroundOverlayView.isHidden = true
        backgroundOverlayView.alpha = 0.0
        optionsContainerOffsetConstraint.constant = 0.0
        
        tableView.delegate = self
        tableView.dataSource = self
        let nib = UINib(nibName: "AccountFromCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "optionCell")
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDismiss))
        backgroundOverlayView.addGestureRecognizer(tapGestureRecognizer)
        applyTheme()
        
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        tableView.backgroundColor = .clear
        optionsContainerView.backgroundColor = theme.background
    }
    
    func setDelegate(newDelegate: MoreOptionsViewInterface) {
        self.delegate = newDelegate
        refreshView()
    }
    
    func changeLayout(label: Int) {
        delegate?.changeOptions(label: label)
        refreshView()
    }
    
    func refreshView() {
        let bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
        let height = CGFloat(self.delegate?.optionsCount ?? 0) * self.OPTION_HEIGHT + bottomPadding
        optionsContainerOffsetConstraint.constant = -height
        optionsHeightConstraint.constant = height
        tableView.reloadData()
        layoutIfNeeded()
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
            self.optionsContainerOffsetConstraint.constant = CGFloat(self.delegate?.optionsCount ?? 0) * -self.OPTION_HEIGHT
            self.backgroundOverlayView.alpha = 0.0
            self.view.layoutIfNeeded()
        }, completion: {
            finished in
            self.optionsContainerView.isHidden = true
            self.backgroundOverlayView.isHidden = true
            self.isHidden = true
        })
    }
    
    @objc func onDismiss() {
        delegate?.onClose()
    }
}

extension MoreOptionsUIView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate?.optionsCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "optionCell") as! AccountFromCell
        delegate?.handleOptionCell(cell: cell, index: indexPath.row)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.handleOptionSelected(index: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return OPTION_HEIGHT
    }
}

