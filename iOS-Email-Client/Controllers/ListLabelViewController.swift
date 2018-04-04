//
//  ListLabelViewController.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 3/17/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import TPCustomSwitch

class ListLabelViewController: UIViewController {
    
    var detailViewController:InboxViewController!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var inboxContainerView: UIView!
    @IBOutlet weak var settingsContainerView: UIView!
    
    @IBOutlet weak var inboxContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var inboxButton: UIButton!
    @IBOutlet weak var draftButton: UIButton!
    @IBOutlet weak var sentButton: UIButton!
    @IBOutlet weak var junkButton: UIButton!
    @IBOutlet weak var trashButton: UIButton!
    
    @IBOutlet weak var settingsContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dummySwitch: UISwitch!
    @IBOutlet weak var signatureButton: UIButton!
    @IBOutlet weak var modifyButton: UIButton!
    @IBOutlet weak var upgradeButton: UIButton!
    @IBOutlet weak var inviteButton: UIButton!
    @IBOutlet weak var supportButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var mailLabel: UILabel!
    @IBOutlet weak var upgradeToProLabel: UILabel!
    @IBOutlet weak var upgradeImageView: UIImageView!
    
    @IBOutlet weak var profileArrowImage: UIImageView!
    @IBOutlet weak var settingsArrowImage: UIImageView!
    
    @IBOutlet weak var inboxBadgeLabel: UILabel!
    @IBOutlet weak var draftBadgeLabel: UILabel!
    
    @IBOutlet weak var selectionViewTopConstraint: NSLayoutConstraint!
    
    enum Offset {
        case inbox
        case draft
        case sent
        case junk
        case trash
        case all
        
        var value: CGFloat {
            switch self {
            case .inbox:
                return 0.0
            case .draft:
                return 50.0
            case .sent:
                return 100.0
            case .junk:
                return 150.0
            case .trash:
                return 200.0
            case .all:
                return 250.0
            }
        }
    }
    
    let secureSwitch = TPCustomSwitch(frame: CGRect.zero)
    
    let initialInboxHeight:CGFloat = 300
    let initialSettingsHeight:CGFloat = 401
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.settingsContainerView.addSubview(self.secureSwitch)
        self.secureSwitch.center = CGPoint(x: self.dummySwitch.center.x - 100, y: self.dummySwitch.center.y)
        self.secureSwitch.addTarget(self, action: #selector(self.didChangeSwitchValue(_:)), for: UIControlEvents.valueChanged)
        self.secureSwitch.activeColor = UIColor(red:0.00, green:0.43, blue:0.97, alpha:1.0)
        self.secureSwitch.onTintColor = UIColor(red:0.00, green:0.43, blue:0.97, alpha:1.0)
        
        self.secureSwitch.thumbImage = Icon.lock.image
        
        self.settingsContainerView.bringSubview(toFront: self.secureSwitch)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scrollView.contentSize = CGSize(width: self.view.bounds.size.width, height: 885)
    }
    
    @IBAction func didTouch(_ sender: UIButton) {
        sender.backgroundColor = UIColor.lightGray
    }
    
    @IBAction func didCancelTouch(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
    }
    
    
    @IBAction func didPressInbox(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        self.selectionViewTopConstraint.constant = Offset.inbox.value
        self.changeInbox(.inbox)
    }
    
    @IBAction func didPressDraft(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        self.selectionViewTopConstraint.constant = Offset.draft.value
        self.changeInbox(.draft)
    }
    
    @IBAction func didPressSent(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        self.selectionViewTopConstraint.constant = Offset.sent.value
        self.changeInbox(.sent)
    }
    
    @IBAction func didPressJunk(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        self.selectionViewTopConstraint.constant = Offset.junk.value
        self.changeInbox(.junk)
    }
    
    @IBAction func didPressTrash(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        self.selectionViewTopConstraint.constant = Offset.trash.value
        self.changeInbox(.trash)
    }
    
    @IBAction func didPressAllMails(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        self.selectionViewTopConstraint.constant = Offset.all.value
        self.changeInbox(.all)
    }
    
    @IBAction func didChangeSwitchValue(_ sender: TPCustomSwitch) {
        self.detailViewController.changeDefaultValue(sender.isOn())
        
        if sender.isOn() {
            self.secureSwitch.setThumb(Icon.activated.color)
            self.secureSwitch.thumbImage = Icon.lock.image
        }else{
            self.secureSwitch.setThumb(Icon.disabled.color)
            self.secureSwitch.thumbImage = Icon.lock_open.image
        }
    }
    
    
    @IBAction func didPressSignature(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        self.navigationDrawerController?.closeLeftView()
        self.detailViewController.showSignature()
    }
    
    @IBAction func didPressHeader(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        self.navigationDrawerController?.closeLeftView()
        self.detailViewController.showHeader()
    }
    
    @IBAction func didPressUpgrade(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        UIApplication.shared.open(URL(string: "https://criptext.com/mpricing")!)        
    }
    
    @IBAction func didPressInvite(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        self.navigationDrawerController?.closeLeftView()
        self.detailViewController.showShareDialog()
    }
    
    @IBAction func didPressSupport(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        self.navigationDrawerController?.closeLeftView()
        self.detailViewController.showSupport()
    }
    
    @IBAction func didPressLogout(_ sender: UIButton) {
        sender.backgroundColor = UIColor.clear
        
        self.detailViewController.signout()
    }
    
    @IBAction func didPressProfile(_ sender: UIButton) {
        let needsCollapsing = self.inboxContainerHeightConstraint.constant != 0
        self.collapseInbox(needsCollapsing)
    }
    
    @IBAction func didPressSettings(_ sender: UIButton) {
        let needsCollapsing = self.settingsContainerHeightConstraint.constant != 0
        self.collapseSettings(needsCollapsing)
    }
    
    func collapseInbox(_ flag:Bool){
        self.inboxContainerHeightConstraint.constant = flag ? 0 : self.initialInboxHeight
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.profileArrowImage.image = flag ? Icon.arrow.down.image : Icon.arrow.up.image
            self.inboxContainerView.alpha = flag ? 0 : 1
            self.view.layoutIfNeeded()
        })
    }
    
    func collapseSettings(_ flag:Bool){
        self.settingsContainerHeightConstraint.constant = flag ? 0 : self.initialSettingsHeight
        
        UIView.animate(withDuration: 0.5, animations: {
            self.settingsArrowImage.image = flag ? Icon.arrow.down.image : Icon.arrow.up.image
            self.secureSwitch.alpha = flag ? 0 : 1
            self.view.layoutIfNeeded()
        })
    }
    
    func changeInbox(_ labelItem:MyLabel){
        
        if self.detailViewController.selectedLabel != labelItem {
            self.detailViewController.didChange(labelItem)
        }
        
        self.navigationDrawerController?.closeLeftView()
    }
}
