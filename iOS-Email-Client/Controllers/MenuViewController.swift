//
//  MenuViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/5/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SDWebImage
import RealmSwift

class MenuViewController: UIViewController{
    let COLLECTION_CELL_WIDTH = 57
    let LABEL_CELL_HEIGHT : CGFloat = 44.0
    let MENU_CONTENT_HEIGHT : CGFloat = 860.0
    let MENU_ITEM_HEIGHT: CGFloat = 63.0
    let MAX_LABELS_HEIGHT : CGFloat = 110.0
    let MAX_LABELS_DISPLAY = 2
    let MAX_ACCOUNTS = 3
    @IBOutlet weak var accountsCollectionWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var accountsCollectionView: UICollectionView!
    @IBOutlet weak var accountsTableView: UITableView!
    @IBOutlet weak var accountsSectionButton: UIButton!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var accountContainerView: UIView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var avatarImageWrapperView: UIImageView!
    @IBOutlet weak var avatarPlusBadgeView: UILabel!
    @IBOutlet weak var avatarPlusBadgeWrapperView: UIView!
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
    @IBOutlet weak var joinPlusMenuItem: MenuItemUIView!
    @IBOutlet weak var joinPlusItemHeightContraint: NSLayoutConstraint!
    @IBOutlet var menuItemsViews: [MenuItemUIView]?
    var selectedMenuItem : MenuItemUIView?
    var mailboxVC : InboxViewController! {
        get {
            return self.navigationDrawerController?.rootViewController.children.first as? InboxViewController
        }
    }
    var scrollViewHeight: CGFloat {
        let needsUpgrade = Constants.isUpgrade(customerType: mailboxVC.myAccount.customerType)
        joinPlusMenuItem.isHidden = !needsUpgrade
        joinPlusItemHeightContraint.constant = !needsUpgrade ? 0.0 : MENU_ITEM_HEIGHT
        return !needsUpgrade ? MENU_CONTENT_HEIGHT : (MENU_CONTENT_HEIGHT + MENU_ITEM_HEIGHT)
    }
    var menuData : MenuData!
    var accountsToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAccountInfo(mailboxVC.myAccount)
        inboxMenuItem.showAsSelected(true)
        selectedMenuItem = inboxMenuItem
        labelsTableHeightContraint.constant = 0.0
        loadTableView()
        loadAccounts()
        loadCollectionView()
        applyTheme()
        let gesture = UITapGestureRecognizer(target: self, action: #selector(openProfile))
        avatarImage.isUserInteractionEnabled = true
        avatarImage.addGestureRecognizer(gesture)
        
        avatarPlusBadgeView.layer.cornerRadius = 4
        avatarPlusBadgeView.textColor = .white
        let hexColor = Account.CustomerType(rawValue: mailboxVC.myAccount.customerType)?.hexColor ?? "FFFFFF"
        avatarPlusBadgeView.backgroundColor = UIColor.init().toColorString(hex: hexColor)
        avatarPlusBadgeView.layer.masksToBounds = true
        
        avatarImageWrapperView.isHidden = !Constants.isPlus(customerType: mailboxVC.myAccount.customerType)
        avatarPlusBadgeWrapperView.isHidden = !Constants.isPlus(customerType: mailboxVC.myAccount.customerType)
        
        joinPlusMenuItem.itemLabel.text = String.localize("JOIN_PLUS")
        self.accountsSectionButton.imageView?.tintColor = .mainUI
    }
    
    @objc func openProfile(){
        mailboxVC.goToProfile()
    }
    
    func loadCollectionView() {
        self.accountsCollectionView.delegate = self
        self.accountsCollectionView.dataSource = self
        
        let accountNib = UINib(nibName: "AccountCollectionCell", bundle: nil)
        self.accountsCollectionView.register(accountNib, forCellWithReuseIdentifier: "accountCell")
        
        self.accountsCollectionView.isHidden = false
    }
    
    func loadTableView() {
        self.accountsTableView.delegate = self
        self.accountsTableView.dataSource = self
        
        let footerNib = UINib(nibName: "AccountsFooterCell", bundle: nil)
        self.accountsTableView.register(footerNib, forHeaderFooterViewReuseIdentifier: "footerCell")
        
        self.accountsTableView.isHidden = true
    }
    
    func loadAccounts() {
        self.menuData.accounts = DBManager.getInactiveAccounts()
        accountsToken = menuData.accounts.observe { [weak self] changes in
            guard let myself = self,
                !myself.mailboxVC.myAccount.isInvalidated else {
                    self?.accountsToken?.invalidate()
                    return
            }
            switch(changes){
            case .update:
                myself.accountsTableView.reloadData()
                myself.accountsCollectionView.reloadData()
                myself.resizeCollectionView()
            default:
                break
            }
        }
        accountsTableView.reloadData()
        resizeCollectionView()
    }
    
    func resizeCollectionView() {
        let width = CGFloat(self.menuData.accounts.count * COLLECTION_CELL_WIDTH)
        accountsCollectionWidthConstraint.constant = width
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadView()
    }
    
    func setupAccountInfo(_ myAccount: Account){
        nameLabel.text = myAccount.name
        usernameLabel.text = myAccount.email
        
        UIUtils.setProfilePictureImage(imageView: avatarImage, contact: (myAccount.email, myAccount.name))
        UIUtils.setAvatarBorderImage(imageView: avatarImageWrapperView, contact: (myAccount.email, myAccount.name))
    }
    
    func reloadView() {
        setupAccountInfo(mailboxVC.myAccount)
        menuData.reloadLabels(account: mailboxVC.myAccount)
        hideCustomLabels()
        labelsTableView.reloadData()
        accountsCollectionView.reloadData()
        accountsTableView.reloadData()
        
        let hexColor = Account.CustomerType(rawValue: mailboxVC.myAccount.customerType)?.hexColor ?? "FFFFFF"
        avatarPlusBadgeView.backgroundColor = UIColor.init().toColorString(hex: hexColor)
        
        avatarImageWrapperView.isHidden = !Constants.isPlus(customerType: mailboxVC.myAccount.customerType)
        avatarPlusBadgeWrapperView.isHidden = !Constants.isPlus(customerType: mailboxVC.myAccount.customerType)
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        accountsTableView.backgroundColor = theme.menuBackground
        scrollView.backgroundColor = theme.menuBackground
        self.view.backgroundColor = theme.menuBackground
        nameLabel.textColor = theme.mainText
        usernameLabel.textColor = theme.secondText
        accountContainerView.backgroundColor = theme.menuHeader
        topSeparatorView.backgroundColor = theme.separator
        bottomSeparatorView.backgroundColor = theme.separator
        joinPlusMenuItem.iconView.tintColor = .plusStatus
        joinPlusMenuItem.itemLabel.textColor = .plusStatus
        labelsTableView.reloadData()
        if let menuViews = menuItemsViews {
            for menuView in menuViews {
                menuView.showAsSelected(menuView == selectedMenuItem)
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: scrollViewHeight)
        scrollInnerViewHeightConstraint.constant = scrollViewHeight
        
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
                self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width, height: self.scrollViewHeight + labelsHeight)
                self.scrollInnerViewHeightConstraint.constant = self.scrollViewHeight + labelsHeight
                self.labelsTableHeightContraint.constant = labelsHeight
                self.labelsTapIconView.image = UIImage(named: "icon-up")
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
        self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width, height: self.scrollViewHeight)
        self.scrollInnerViewHeightConstraint.constant = self.scrollViewHeight
        self.labelsTapIconView.image = UIImage(named: "icon-down")
    }
    
    func refreshBadges(){
        let badgesGetterAsyncTask = GetBadgeCountersAsyncTask(accountId: mailboxVC.myAccount.compoundKey)
        badgesGetterAsyncTask.start { [weak self] (counters) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.inboxMenuItem.showBadge(counters.inbox)
            weakSelf.draftMenuItem.showBadge(counters.draft)
            weakSelf.spamMenuItem.showBadge(counters.spam)
            
            var refreshAccounts = false
            
            for accountBadge in counters.accounts {
                if weakSelf.menuData.accountBadge[accountBadge.key] != accountBadge.value {
                    refreshAccounts = true
                }
            }
            weakSelf.menuData.accountBadge = counters.accounts
            
            if refreshAccounts {
                weakSelf.accountsTableView.reloadData()
                weakSelf.accountsCollectionView.reloadData()
            }
            if (weakSelf.mailboxVC != nil) {
                weakSelf.mailboxVC.circleBadgeView.isHidden = !weakSelf.menuData.accountBadge.contains(where: {$0.value > 0})
            }
        }
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
    
    @IBAction func onJoinPlusItemPress(_ sender: Any) {
        mailboxVC.joinPlus()
    }
}

extension MenuViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch(tableView) {
        case accountsTableView:
            return accountsTableView(tableView, numberOfRowsInSection: section)
        default:
            return labelsTableView(tableView, numberOfRowsInSection: section)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch(tableView) {
        case accountsTableView:
            return accountsTableView(tableView, cellForRowAt: indexPath)
        default:
            return labelsTableView(tableView, cellForRowAt: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch(tableView) {
        case accountsTableView:
            return accountsTableView(tableView, heightForRowAt: indexPath)
        default:
            return labelsTableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch(tableView) {
        case accountsTableView:
            return accountsTableView(tableView, didSelectRowAt: indexPath)
        default:
            return labelsTableView(tableView, didSelectRowAt: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch(tableView) {
        case accountsTableView:
            return accountsTableView(tableView, heightForFooterInSection: section)
        default:
            return labelsTableView(tableView, heightForFooterInSection: section)
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch(tableView) {
        case accountsTableView:
            return accountsTableView(tableView, viewForFooterInSection: section)
        default:
            return labelsTableView(tableView, viewForFooterInSection: section)
        }
    }
}

extension MenuViewController{
    func labelsTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuData.labels.count
    }
    
    func labelsTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "labeltablecell", for: indexPath) as! CustomLabelTableViewCell
        let label = menuData.labels[indexPath.row]
        cell.setLabel(label.text, color: UIColor(hex: label.color))
        return cell
    }
    
    func labelsTableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return LABEL_CELL_HEIGHT
    }
    
    func labelsTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let label = menuData.labels[indexPath.row]
        selectedMenuItem?.showAsSelected(false)
        mailboxVC.swapMailbox(labelId: label.id, sender: nil)
    }
    
    func labelsTableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    func labelsTableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
}

extension MenuViewController{
    func accountsTableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuData.accounts.count
    }
    
    func accountsTableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "accountCell", for: indexPath) as! AccountTableCell
        let account = self.menuData.accounts[indexPath.row]
        let counter = self.menuData.accountBadge[account.compoundKey] ?? 0
        cell.setContent(account: account, counter: counter)
        return cell
    }
    
    func accountsTableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func accountsTableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let account = menuData.accounts[indexPath.row]
        navigationDrawerController?.closeLeftView()
        mailboxVC.swapAccount(account)
    }
    
    func accountsTableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard menuData.accounts.count < 2 else {
            return 0
        }
        return 103
    }
    
    func accountsTableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard menuData.accounts.count < 2 else {
            return nil
        }
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "footerCell") as! AccountsFooterCell
        cell.delegate = self
        return cell
    }
    
    @IBAction func toggleAccounts(sender: Any) {
        self.accountsTableView.isHidden = !accountsTableView.isHidden
        self.accountsCollectionView.isHidden = !accountsCollectionView.isHidden
        self.accountsSectionButton.setImage(accountsTableView.isHidden ? UIImage(named: "icon-down") : UIImage(named: "icon-up"), for: .normal)
        self.accountsSectionButton.imageView?.tintColor = .mainUI
    }
    
    func hideAccounts() {
        self.accountsTableView.isHidden = true
        self.accountsCollectionView.isHidden = false
        self.accountsSectionButton.setImage(UIImage(named: "icon-down"), for: .normal)
    }
}

extension MenuViewController: AccountsFooterDelegate {
    func addAccount() {
        navigationDrawerController?.closeLeftView()
        mailboxVC.addAccount()
    }
}

extension MenuViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return menuData.accounts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "accountCell", for: indexPath) as! AccountCollectionCell
        let account = self.menuData.accounts[indexPath.row]
        let counter = self.menuData.accountBadge[account.compoundKey] ?? 0
        cell.setContent(account: account, counter: counter)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let account = self.menuData.accounts[indexPath.row]
        navigationDrawerController?.closeLeftView()
        mailboxVC.swapAccount(account)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: COLLECTION_CELL_WIDTH, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
}
