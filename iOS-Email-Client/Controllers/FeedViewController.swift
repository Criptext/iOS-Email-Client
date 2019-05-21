//
//  FeedViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework
import RealmSwift

class FeedViewController: UIViewController{
    let HEADER_HEIGHT : CGFloat = 42.0
    var feedsData = FeedsData()
    @IBOutlet weak var feedTitle: UILabel!
    @IBOutlet weak var feedSubtitle: UILabel!
    @IBOutlet weak var noFeedsView: UIView!
    @IBOutlet weak var headerView: FeedHeaderTitleUIView!
    @IBOutlet weak var feedsTableView: UITableView!
    @IBOutlet weak var bellImage: UIImageView!
    var newFeedsToken: NotificationToken?
    var oldFeedsToken: NotificationToken?
    
    var mailboxVC : InboxViewController! {
        get {
            return self.navigationDrawerController?.rootViewController.children.first as? InboxViewController
        }
    }
    var lastSeen : Date {
        return mailboxVC.myAccount.lastTimeFeedOpened
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        feedsTableView.separatorStyle = .none
        feedsTableView.register(UINib(nibName: "TableEndViewCell", bundle: nil), forCellReuseIdentifier: "EndCell")
        feedsTableView.register(UINib(nibName: "SettingsGeneralHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "HeaderCell")
        loadFeeds()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        invalidateObservers()
        super.dismiss(animated: flag, completion: completion)
    }
    
    func invalidateObservers() {
        oldFeedsToken?.invalidate()
        newFeedsToken?.invalidate()
        oldFeedsToken = nil
        newFeedsToken = nil
    }
    
    func checkIfFeedsEmpty(){
        if(feedsData.newFeeds.isEmpty && feedsData.oldFeeds.isEmpty){
            noFeedsView.isHidden = false
            feedsTableView.isHidden = true
        }else{
            noFeedsView.isHidden = true
            feedsTableView.isHidden = false
        }
    }
    
    func loadFeeds(){
        let feeds = DBManager.getFeeds(since: Date() , limit: 20, lastSeen: lastSeen, account: mailboxVC.myAccount)
        feedsData.newFeeds = feeds.0
        feedsData.oldFeeds = feeds.1
        newFeedsToken = feedsData.newFeeds.observe { [weak self] changes in
            guard let myself = self,
                !myself.mailboxVC.myAccount.isInvalidated else {
                    self?.oldFeedsToken?.invalidate()
                    self?.newFeedsToken?.invalidate()
                return
            }
            switch(changes){
            case .initial:
                myself.feedsTableView.reloadData()
            case .update:
                myself.feedsTableView.reloadData()
            default:
                break
            }
        }
        oldFeedsToken = feedsData.oldFeeds.observe { [weak self] changes in
            guard let myself = self,
                !myself.mailboxVC.myAccount.isInvalidated else {
                return
            }
            switch(changes){
            case .initial:
                myself.feedsTableView.reloadData()
            case .update:
                myself.feedsTableView.reloadData()
            default:
                break
            }
        }
        checkIfFeedsEmpty()
        feedsTableView.reloadData()
    }
    
    func viewClosed() {
        loadFeeds()
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        self.view.backgroundColor = theme.menuBackground
        self.feedsTableView.backgroundColor = theme.menuBackground
        self.bellImage.image = theme.name == "Dark" ? UIImage(named: "belldark") : UIImage(named: "color-bell")
        self.feedTitle.textColor = theme.mainText
        self.feedSubtitle.textColor = theme.placeholder
        feedsTableView.reloadData()
        headerView.applyTheme()
    }
}

extension FeedViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "feedTableCellView", for: indexPath) as! FeedTableViewCell
        let feed = (indexPath.section == 0 ? feedsData.newFeeds[indexPath.row] : feedsData.oldFeeds[indexPath.row])
        cell.fillFields(feed: feed, account: mailboxVC.myAccount, lastSeen: lastSeen)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(section == 0){
            return feedsData.newFeeds.count
        }
        return feedsData.oldFeeds.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 63.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "HeaderCell") as! SettingsGeneralHeaderView
        cell.titleLabel.text = section == 0 ? String.localize("NEW") : String.localize("OLDER")
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return feedsData.newFeeds.count == 0 || feedsData.oldFeeds.count == 0 ? 0.0 : HEADER_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = deleteAction(tableView, indexPath: indexPath)
        return UISwipeActionsConfiguration(actions: [delete])
    }
    
    func muteAction(_ tableView: UITableView, indexPath: IndexPath) -> UIContextualAction{
        let feed = (indexPath.section == 0 ? feedsData.newFeeds[indexPath.row] : feedsData.oldFeeds[indexPath.row])
        let action = UIContextualAction(style: .normal, title: feed.isMuted ? String.localize("UNMUTE") : String.localize("MUTE")){
            (action, view, completion) in
            DBManager.updateEmail(feed.email, muted: !feed.isMuted)
            tableView.reloadRows(at: [indexPath], with: .fade)
            completion(true)
        }
        action.image = feed.isMuted ? #imageLiteral(resourceName: "unmuted") : #imageLiteral(resourceName: "muted")
        action.backgroundColor = UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)
        return action
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let feed = (indexPath.section == 0 ? feedsData.newFeeds[indexPath.row] : feedsData.oldFeeds[indexPath.row])
        let workingLabel = feed.email.isSpam ? SystemLabel.spam.id : (feed.email.isTrash ? SystemLabel.trash.id : SystemLabel.sent.id)
        guard let selectedThread = DBManager.getThread(threadId: feed.email.threadId, label: workingLabel, account: mailboxVC.myAccount) else {
            return
        }
        mailboxVC.goToEmailDetail(selectedThread: selectedThread, selectedLabel: workingLabel)
    }
    
    func deleteAction(_ tableView: UITableView, indexPath: IndexPath) -> UIContextualAction{
        let action = UIContextualAction(style: .destructive, title: String.localize("DELETE")){ [weak self] (action, view, completion) in
            guard let weakSelf = self else {
                return
            }
            let feed: FeedItem
            if(indexPath.section == 0){
                feed = weakSelf.feedsData.newFeeds[indexPath.row]
            }else{
                feed = weakSelf.feedsData.oldFeeds[indexPath.row]
            }
            DBManager.delete(feed: feed)
            completion(true)
        }
        action.image = #imageLiteral(resourceName: "delete-icon")
        action.backgroundColor = UIColor(red: 220/255, green: 77/255, blue: 72/255, alpha: 1)
        return action
    }
}
