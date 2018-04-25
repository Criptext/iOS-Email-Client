//
//  FeedViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/21/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import SignalProtocolFramework

class FeedViewController: UIViewController{
    var feedsData: FeedsData = FeedsData()
    @IBOutlet weak var noFeedsView: UIView!
    @IBOutlet weak var feedsTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        feedsTableView.separatorStyle = .none
        if(feedsData.newFeeds.isEmpty && feedsData.oldFeeds.isEmpty){
            noFeedsView.isHidden = false
            feedsTableView.isHidden = true
        }else{
            noFeedsView.isHidden = true
            feedsTableView.isHidden = false
        }
        feedsTableView.register(UINib(nibName: "TableEndViewCell", bundle: nil), forCellReuseIdentifier: "EndCell")
    }
}

extension FeedViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if(indexPath.section > 0 && indexPath.row == feedsData.oldFeeds.count){
            return buildLastRow()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "feedTableCellView", for: indexPath) as! FeedTableViewCell
        let feed = (indexPath.section == 0 ? feedsData.newFeeds[indexPath.row] : feedsData.oldFeeds[indexPath.row])
        cell.setLabels(feed.message, feed.subject, feed.getFormattedDate())
        cell.setIcons(isOpen: feed.isOpen, isMuted: feed.isMuted)
        cell.handleViewed(isNew: feed.isNew)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(section == 0){
            return feedsData.newFeeds.count
        }
        return feedsData.oldFeeds.count + 1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 63.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if(section == 0){
            return "NEW"
        }
        return "OLDER"
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat(42)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard !isLoaderRow(indexPath) else {
            return nil
        }
        let delete = deleteAction(tableView, indexPath: indexPath)
        let mute = muteAction(tableView, indexPath: indexPath)
        return UISwipeActionsConfiguration(actions: [delete, mute])
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !isLoaderRow(indexPath)
    }
    
    func muteAction(_ tableView: UITableView, indexPath: IndexPath) -> UIContextualAction{
        let feed = (indexPath.section == 0 ? feedsData.newFeeds[indexPath.row] : feedsData.oldFeeds[indexPath.row])
        let action = UIContextualAction(style: .normal, title: feed.isMuted ? "Unmute" : "Mute" ){
            (action, view, completion) in
            feed.isMuted = !feed.isMuted
            tableView.reloadRows(at: [indexPath], with: .fade)
            completion(true)
        }
        action.image = feed.isMuted ? #imageLiteral(resourceName: "unmuted") : #imageLiteral(resourceName: "muted")
        action.backgroundColor = UIColor(red: 155/255, green: 155/255, blue: 155/255, alpha: 1)
        return action
    }
    
    func buildLastRow() -> UITableViewCell{
        let footerView = feedsTableView.dequeueReusableCell(withIdentifier: "EndCell") as! TableEndViewCell
        if(feedsData.reachedEnd){
            footerView.displayMessage("No more activities")
        }else{
            footerView.displayLoader()
        }
        return footerView
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isLoaderRow(indexPath) else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        let feed = (indexPath.section == 0 ? feedsData.newFeeds[indexPath.row] : feedsData.oldFeeds[indexPath.row])
        feed.isNew = false
        tableView.reloadRows(at: [indexPath], with: .fade)
    }
    
    func deleteAction(_ tableView: UITableView, indexPath: IndexPath) -> UIContextualAction{
        let action = UIContextualAction(style: .destructive, title: "Delete"){
            (action, view, completion) in
            if(indexPath.section == 0){
                self.feedsData.newFeeds.remove(at: indexPath.row)
            }else{
                self.feedsData.oldFeeds.remove(at: indexPath.row)
            }
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }
        action.image = #imageLiteral(resourceName: "delete-icon")
        action.backgroundColor = UIColor(red: 220/255, green: 77/255, blue: 72/255, alpha: 1)
        return action
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        guard !feedsData.loadingFeeds && !feedsData.reachedEnd else {
            return
        }

        if(isLoaderRow(indexPath)){
            feedsData.loadingFeeds = true
            tableView.reloadRows(at: [indexPath], with: .automatic)
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)){
                self.feedsData.reachedEnd = true
                self.feedsData.loadingFeeds = false
                tableView.reloadData()
            }
        }
    }
    
    func isLoaderRow(_ indexPath: IndexPath) -> Bool {
        return indexPath.section == 1 && indexPath.row == feedsData.oldFeeds.count
    }
}
