//
//  OpenUIPopover.swift
//  Criptext Secure Email
//
//  Created by Daniel Tigse on 4/7/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftyJSON

class OpenUIPopover: UIViewController, UIPopoverPresentationControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    @IBOutlet weak var labelDate: UILabel!
    @IBOutlet weak var labelLocation: UILabel!
    @IBOutlet weak var labelSentDate: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var opensList = [Open]()
    var lastDate: String!
    var sentDate: String!
    var lastLocation: String!
    var totalViews: String!
    var myMailToken: String!
    var overlay: UIView?

    init() {
        super.init(nibName: "OpenUIPopover", bundle: nil)
        self.modalPresentationStyle = UIModalPresentationStyle.popover;
        self.popoverPresentationController?.delegate = self;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle{
        return .none
    }
    
    dynamic func presentationController(_ presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {

        let parentView = presentationController.presentingViewController.view
        
        let overlay = UIView(frame: (parentView?.bounds)!)
        overlay.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
        parentView?.addSubview(overlay)
        
        let views: [String: UIView] = ["parentView": parentView!, "overlay": overlay]
        
        parentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[overlay]|", options: [], metrics: nil, views: views))
        parentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[overlay]|", options: [], metrics: nil, views: views))
        
        overlay.alpha = 0.0
        
        transitionCoordinator?.animate(alongsideTransition: { _ in
            overlay.alpha = 1.0
        }, completion: nil)
        
        self.overlay = overlay
    }
    
    deinit {
        
        guard let overlay = overlay else {
            return
        }
        DispatchQueue.main.async() {
            UIView.animate(withDuration: 0.2, animations: {
                overlay.alpha = 0.0
            }, completion: { _ in
                overlay.removeFromSuperview()
            })
        }
    }
    
    override func viewDidLoad() {
        
        collectionView?.register(UINib(nibName: "OpenViewCell", bundle: nil), forCellWithReuseIdentifier: "opensCell")
        labelDate.text = lastDate
        labelLocation.text = lastLocation
        labelSentDate.text = sentDate
        
        NotificationCenter.default.addObserver(self, selector: #selector(onWebSocketMessage(_:)), name: NSNotification.Name.Activity.onNewMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWebSocketMessage(_:)), name: NSNotification.Name.Activity.onNewAttachment, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWebSocketMessage(_:)), name: NSNotification.Name.Activity.onMsgNotificationChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onWebSocketMessage(_:)), name: NSNotification.Name.Activity.onFileNotificationChange, object: nil)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {

        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.Activity.onNewMessage, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.Activity.onNewAttachment, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.Activity.onMsgNotificationChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.Activity.onFileNotificationChange, object: nil)
    }
    
    @objc func onWebSocketMessage(_ notification : Notification) {
        
        guard let userInfo = notification.userInfo else{
            print("No userInfo found in notification")
            return
        }
        
        if(notification.name == Notification.Name.Activity.onMsgNotificationChange){
            
            let token = userInfo["token"] as! String
            if(myMailToken == token){
                let newActivity = DBManager.getActivityBy(token)
                if(newActivity != nil){
                    
                    //UPDATE THE OPEN ARRAY
                    let openArray = JSON(parseJSON: newActivity!.openArraySerialized).arrayValue.map({$0.stringValue})
                    opensList.removeAll()
                    for open in openArray{
                        let location = open.components(separatedBy: ":")[0]
                        let time = open.components(separatedBy: ":")[1]
                        opensList.append(Open(fromTimestamp: Double(time)!, fromLocation: location, fromType: 1))
                    }
                    collectionView.reloadData()
                    
                    //UPDATE THE LABELS
                    let open:String = openArray.first!
                    let location = open.components(separatedBy: ":")[0]
                    let time = open.components(separatedBy: ":")[1]
                    let date = Date(timeIntervalSince1970: Double(time)!)
                    labelDate.text = DateUtils.beatyDate(date)
                    labelLocation.text = location
                }
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return opensList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "opensCell",
                                                      for: indexPath) as! OpensViewCell
        
        let open = self.opensList[indexPath.row]
        cell.localtionLabel.text = open.location
        
        let date = Date(timeIntervalSince1970: open.timestamp)
        cell.dateLabel.text = DateUtils.beatyDate(date)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: 160, height: 82)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}

class OpensViewCell: UICollectionViewCell {
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var localtionLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    
}
