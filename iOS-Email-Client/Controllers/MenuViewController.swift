//
//  MenuViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class MenuViewController: UIViewController{
    let LABEL_CELL_HEIGHT : CGFloat = 44.0
    let MENU_CONTENT_HEIGHT : CGFloat = 860.0
    let MAX_LABELS_HEIGHT : CGFloat = 110.0
    let MAX_LABELS_DISPLAY = 2
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountContainerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var inboxMenuItem: MenuItemUIView!
    @IBOutlet weak var sentMenuItem: MenuItemUIView!
    @IBOutlet weak var draftMenuItem: MenuItemUIView!
    @IBOutlet weak var starredMenuItem: MenuItemUIView!
    @IBOutlet weak var spamMenuItem: MenuItemUIView!
    @IBOutlet weak var trashMenuItem: MenuItemUIView!
    @IBOutlet weak var allmailMenuItem: MenuItemUIView!
    @IBOutlet weak var labelsTableView: UITableView!
    @IBOutlet weak var labelsTapIconView: UIImageView!
    @IBOutlet weak var labelsTableHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var scrollInnerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var settingsMenuItem: MenuItemUIView!
    @IBOutlet var menuItemsViews: [MenuItemUIView]?
    var selectedMenuItem : MenuItemUIView?
    var mailboxVC : InboxViewController! {
        get {
            return self.navigationDrawerController?.rootViewController.childViewControllers.first as? InboxViewController
        }
    }
    var menuData : MenuData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAccountInfo(mailboxVC.myAccount)
        inboxMenuItem.showAsSelected(true)
        selectedMenuItem = inboxMenuItem
        labelsTableHeightContraint.constant = 0.0
        applyTheme()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadView()
    }
    
    func setupAccountInfo(_ myAccount: Account){
        nameLabel.text = myAccount.name
        usernameLabel.text = myAccount.username + Constants.domain
        avatarImage.setImageWith(myAccount.name, color: colorByName(name: myAccount.name), circular: true, fontName: "NunitoSans-Regular")
    }
    
    func reloadView() {
        setupAccountInfo(mailboxVC.myAccount)
        menuData.reloadLabels()
        hideCustomLabels()
        labelsTableView.reloadData()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        scrollView.backgroundColor = theme.background
        self.view.backgroundColor = theme.background
        nameLabel.textColor = theme.mainText
        usernameLabel.textColor = theme.secondText
        accountContainerView.backgroundColor = theme.cellOpaque
        labelsTableView.reloadData()
        if let menuViews = menuItemsViews {
            for menuView in menuViews {
                menuView.showAsSelected(menuView == selectedMenuItem)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: MENU_CONTENT_HEIGHT)
        scrollInnerViewHeightConstraint.constant = MENU_CONTENT_HEIGHT
        guard nameLabel.text != mailboxVC.myAccount.name else {
            return
        }
        setupAccountInfo(mailboxVC.myAccount)
    }
    
    @IBAction func onMenuItemLabelPress(_ sender: MenuItemUIView) {
        selectedMenuItem?.showAsSelected(false)
        selectedMenuItem = sender
        sender.showAsSelected(true)
        mailboxVC.swapMailbox(labelId: sender.labelId, sender: sender)
    }
    
    @IBAction func onLabelsMenuItemPress(_ sender: Any) {
        guard menuData.expandedLabels else {
            let labelsHeight = menuData.labels.count > MAX_LABELS_DISPLAY ? MAX_LABELS_HEIGHT : CGFloat(menuData.labels.count) * LABEL_CELL_HEIGHT
            menuData.expandedLabels = true
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.25) {
                self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width, height: self.MENU_CONTENT_HEIGHT + labelsHeight)
                self.scrollInnerViewHeightConstraint.constant = self.MENU_CONTENT_HEIGHT + labelsHeight
                self.labelsTableHeightContraint.constant = labelsHeight
                self.labelsTapIconView.image = #imageLiteral(resourceName: "new-arrow-down")
                self.view.layoutIfNeeded()
            }
            return
        }
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.25) {
            self.hideCustomLabels()
            self.view.layoutIfNeeded()
        }
    }
    
    func hideCustomLabels(){
        menuData.expandedLabels = false
        self.labelsTableHeightContraint.constant = 0.0
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width, height: self.MENU_CONTENT_HEIGHT)
        self.scrollInnerViewHeightConstraint.constant = self.MENU_CONTENT_HEIGHT
        self.labelsTapIconView.image = #imageLiteral(resourceName: "new-arrow-up")
    }
    
    func refreshBadges(){
        let inboxCounter = DBManager.getUnreadMailsCounter(from: SystemLabel.inbox.id)
        let draftCounter = DBManager.getThreads(from: SystemLabel.draft.id, since: Date(), limit: 100).count
        let spamCounter = DBManager.getUnreadMailsCounter(from: SystemLabel.spam.id)
        
        inboxMenuItem.showBadge(inboxCounter)
        draftMenuItem.showBadge(draftCounter)
        spamMenuItem.showBadge(spamCounter)
    }
    
    @IBAction func onSettingsMenuItemPress(_ sender: Any) {
        mailboxVC.goToSettings()
    }
    
    @IBAction func onSupportMenuItemPress(_ sender: Any) {
        mailboxVC.openSupport()
    }
    
    @IBAction func onInviteMenuItemPress(_ sender: Any) {
        mailboxVC.inviteFriend()
    }
}

extension MenuViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuData.labels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "labeltablecell", for: indexPath) as! CustomLabelTableViewCell
        let label = menuData.labels[indexPath.row]
        cell.setLabel(label.text, color: UIColor(hex: label.color))
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return LABEL_CELL_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let label = menuData.labels[indexPath.row]
        selectedMenuItem?.showAsSelected(false)
        mailboxVC.swapMailbox(labelId: label.id, sender: nil)
    }
}
