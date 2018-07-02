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
    let MENU_CONTENT_HEIGHT : CGFloat = 800.0
    let MAX_LABELS_HEIGHT : CGFloat = 110.0
    let MAX_LABELS_DISPLAY = 2
    @IBOutlet weak var scrollView: UIScrollView!
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
    }
    
    func setupAccountInfo(_ myAccount: Account){
        nameLabel.text = myAccount.name
        usernameLabel.text = myAccount.username + Constants.domain
        avatarImage.setImageWith(myAccount.name, color: colorByName(name: myAccount.name), circular: true, fontName: "NunitoSans-Regular")
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
            labelsTapIconView.image = #imageLiteral(resourceName: "new-arrow-down")
            scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: MENU_CONTENT_HEIGHT + labelsHeight)
            scrollInnerViewHeightConstraint.constant = MENU_CONTENT_HEIGHT + labelsHeight
            labelsTableHeightContraint.constant = labelsHeight
            return
        }
        menuData.expandedLabels = false
        labelsTableHeightContraint.constant = 0.0
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: MENU_CONTENT_HEIGHT)
        scrollInnerViewHeightConstraint.constant = MENU_CONTENT_HEIGHT
        labelsTapIconView.image = #imageLiteral(resourceName: "new-arrow-up")
    }
    
    func refreshBadges(){
        let inboxCounter = DBManager.getUnreadMails(from: SystemLabel.inbox.id).count
        let draftCounter = DBManager.getThreads(from: SystemLabel.draft.id, since: Date(), limit: 100).count
        let spamCounter = DBManager.getUnreadMails(from: SystemLabel.spam.id).count
        
        inboxMenuItem.showBadge(inboxCounter)
        draftMenuItem.showBadge(draftCounter)
        spamMenuItem.showBadge(spamCounter)
    }
    
    @IBAction func onSettingsMenuItemPress(_ sender: Any) {
        mailboxVC.goToSettings()
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
}
