//
//  BottomMenuView.swift
//  iOS-Email-Client
//
//  Created by Allisson on 3/21/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol BottomMenuDelegate: class {
    func didPressOption(_ option: String)
    func didPressBackground()
}

class BottomMenuView: UIView {
    let ROW_HEIGHT: CGFloat = 60
    @IBOutlet weak var view: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableBottomConstraint: NSLayoutConstraint!
    var options = [String]()
    var totalHeight: CGFloat = 0
    weak var delegate: BottomMenuDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "BottomMenuView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(didPressBackground))
        backgroundView.addGestureRecognizer(gesture)
        
        tableView.delegate = self
        tableView.dataSource = self
        let nib = UINib(nibName: "AccountFromCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "accountCell")
    }
    
    func initialLoad(options: [String]) {
        self.options = options
        self.totalHeight = ROW_HEIGHT * CGFloat(options.count)
        tableHeightConstraint.constant = self.totalHeight
        tableBottomConstraint.constant = -self.totalHeight - 50.0
        backgroundView.isHidden = true
        
        tableView.reloadData()
        applyTheme()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        tableView.backgroundColor = theme.background
    }
    
    @objc func didPressBackground() {
        delegate?.didPressBackground()
    }
    
    func toggleMenu(_ show: Bool) {
        if show {
            UIView.animate(withDuration: 0.5) {
                self.backgroundView.isHidden = false
                self.tableBottomConstraint.constant = 0
            }
        } else {
            UIView.animate(withDuration: 0.5) {
                self.backgroundView.isHidden = true
                self.tableBottomConstraint.constant = -self.totalHeight - 50.0
            }
        }
    }
}

extension BottomMenuView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell") as! AccountFromCell
        let option = options[indexPath.row]
        cell.emailLabel.text = option
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]
        delegate?.didPressOption(option)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ROW_HEIGHT
    }
}
