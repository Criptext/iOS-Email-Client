//
//  AttachmentUIPopover.swift
//  Criptext Secure Email
//
//  Created by Daniel Tigse on 4/10/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftyJSON

class AttachmentUIPopover: KMAccordionTableViewController,UIPopoverPresentationControllerDelegate,KMAccordionTableViewControllerDataSource,KMAccordionTableViewControllerDelegate{
    
    var sections = [KMSection]()
    var myMailToken: String!
    var overlay: UIView?
    
    init() {
        super.init(nibName: "AttachmentUIPopover", bundle: nil)
        self.modalPresentationStyle = UIModalPresentationStyle.popover;
        self.popoverPresentationController?.delegate = self;
        sections = []
        self.setupAppearence()
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
        super.viewDidLoad()
        
        self.dataSource = self;
        self.delegate = self;
        
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
    
    func onWebSocketMessage(_ notification : Notification) {
        
        guard let userInfo = notification.userInfo else{
            print("No userInfo found in notification")
            return
        }
        
        if(notification.name == Notification.Name.Activity.onFileNotificationChange){
        
            guard let mailToken = userInfo["mailToken"] as? String else {
                return
            }
            
            if(myMailToken == mailToken){
                let attachments = DBManager.getAttachmentsBy(mailToken)
                if(attachments != nil){
                    for section in sections{
                        section.opensList.removeAll()
                        section.isOpen = false
                        (section.view as! UICollectionView).reloadData()
                    }
                    openedSectionIndex = NSNotFound
                    sections.removeAll()
                    setSectionArray(attachments!)
                    self.tableView.reloadData()
                }
            }
            
        }
        
    }
    
    func setupAppearence(){
        
        self.sectionAppearence = KMAppearence()
        self.openedSectionIndex = NSNotFound;
        self.setHeaderArrowImageClosed(Icon.arrow.up.image)
        self.setHeaderArrowImageOpened(Icon.arrow.down.image)
        self.setHeaderHeight(89)
        self.setHeaderColor(UIColor.red)
    }
    
    func setSectionArray(_ attachments: [AttachmentCriptext]){
    
        for attachment in attachments{
            
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .horizontal
            let collectionView = UICollectionView(frame: CGRect.init(x: 12, y: 0, width: self.view.frame.size.width-18, height: 82), collectionViewLayout: flowLayout)
            collectionView.register(UINib(nibName: "OpenViewCell", bundle: nil), forCellWithReuseIdentifier: "opensCell")
            collectionView.backgroundColor = UIColor.clear
            let container = UIView(frame: CGRect.init(x: 5, y: 0, width: self.view.frame.size.width-5, height: 80))
            let divider = UIView(frame: CGRect.init(x: 0, y: 79, width: self.view.frame.size.width-27, height: 0.5))
            divider.backgroundColor = UIColor.lightGray
            container.addSubview(collectionView)
            container.addSubview(divider)
            
            let section1 = KMSection()
            section1.view = container
            section1.title = attachment.fileName
            if(attachment.size > 0){
                section1.size = Double(attachment.size)/1000000
            }
            else{
                section1.size = 0
            }
            
            section1.filesize = attachment.filesize
            
            let openArray = JSON(parseJSON: attachment.openArraySerialized).arrayValue.map({$0.stringValue})
            let downloadArray = JSON(parseJSON: attachment.downloadArraySerialized).arrayValue.map({$0.stringValue})
            
            section1.totalOpens = openArray.count
            section1.totalDownloads = downloadArray.count
            
            switch attachment.fileType {
            case "excel":
                section1.imageFile = Icon.attachment.excel.image
            case "word":
                section1.imageFile = Icon.attachment.word.image
            case "pdf":
                section1.imageFile = Icon.attachment.pdf.image
            case "ppt":
                section1.imageFile = Icon.attachment.ppt.image
            case "zip":
                section1.imageFile = Icon.attachment.zip.image
            case "image":
                section1.imageFile = Icon.attachment.image.image
            case "audio":
                section1.imageFile = Icon.attachment.audio.image
            case "video":
                section1.imageFile = Icon.attachment.video.image
            default:
                section1.imageFile = Icon.attachment.generic.image
            }
            
            collectionView.delegate = section1
            collectionView.dataSource = section1
            var opensList = [Open]()
            for open in openArray{
                let location = open.components(separatedBy: ":")[0]
                let time = open.components(separatedBy: ":")[1]
                opensList.append(Open(fromTimestamp: Double(time)!, fromLocation: location, fromType: 1))
            }
            for open in downloadArray{
                let location = open.components(separatedBy: ":")[0]
                let time = open.components(separatedBy: ":")[1]
                opensList.append(Open(fromTimestamp: Double(time)!, fromLocation: location, fromType: 2))
            }
            opensList = opensList.sorted(by: { (open1, open2) -> Bool in
                return Int(open1.timestamp) > Int(open2.timestamp)
            })
            section1.opensList = opensList
            
            sections.append(section1)
        }
    
    }
    
    //MARK - KMAccordionDelegate
    
    func numberOfSections(in accordionTableView: KMAccordionTableViewController!) -> Int {
        return sections.count
    }
    
    func accordionTableView(_ accordionTableView: KMAccordionTableViewController!, sectionForRowAt index: Int) -> KMSection! {
        return sections[index]
    }
    
    func accordionTableView(_ accordionTableView: KMAccordionTableViewController!, heightForSectionAt index: Int) -> CGFloat {
        
        let section = self.sections[index];
        return section.view.frame.size.height;
    }

    func accordionTableViewOpenAnimation(_ accordionTableView: KMAccordionTableViewController!) -> UITableViewRowAnimation {
        return UITableViewRowAnimation.fade
    }
    
    func accordionTableViewCloseAnimation(_ accordionTableView: KMAccordionTableViewController!) -> UITableViewRowAnimation {
        return UITableViewRowAnimation.fade
    }
    
}
