//
//  EmailTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/27/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import WebKit

protocol EmailTableViewCellDelegate {
    func tableViewCellDidLoadContent(_ cell:EmailTableViewCell)
    func tableViewCellDidTap(_ cell: EmailTableViewCell)
    func tableViewCellDidTapIcon(_ cell: EmailTableViewCell, _ sender: UIView, _ iconType: EmailTableViewCell.IconType)
}

class EmailTableViewCell: UITableViewCell{
    @IBOutlet weak var webView: WKWebView!
    var delegate: EmailTableViewCellDelegate?
    @IBOutlet weak var previewLabel: UILabel!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collapsedDetailView: UIView!
    @IBOutlet weak var expandedDetailView: UIView!
    @IBOutlet weak var unsendView: UIView!
    @IBOutlet weak var unsendIconView: UIImageView!
    @IBOutlet weak var attachmentView: UIView!
    @IBOutlet weak var attachmentIconView: UIImageView!
    @IBOutlet weak var readView: UIView!
    @IBOutlet weak var readIconView: UIImageView!
    @IBOutlet weak var moreRecipientsLabel: UILabel!
    @IBOutlet weak var optionsView: UIView!
    @IBOutlet weak var optionsIconView: UIImageView!
    @IBOutlet weak var replyView: UIView!
    @IBOutlet weak var replyIconView: UIImageView!
    @IBOutlet weak var webViewWrapperView: UIView!
    @IBOutlet weak var borderBGView: UIView!
    @IBOutlet weak var contactsCollapseLabel: UILabel!
    @IBOutlet weak var contactsExpandLabel: UILabel!
    @IBOutlet weak var miniAttachmentIconView: UIImageView!
    @IBOutlet weak var miniReadIconView: UIImageView!
    @IBOutlet weak var attachmentsTableView: UITableView!
    @IBOutlet weak var collapsedDateLabel: UILabel!
    @IBOutlet weak var expandedDateLabel: UILabel!
    @IBOutlet weak var initialsImageView: UIImageView!
    var loadedContent = false
    var myHeight : CGFloat = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
        attachmentsTableView.delegate = self
        attachmentsTableView.dataSource = self
        let nib = UINib(nibName: "AttachmentTableViewCell", bundle: nil)
        attachmentsTableView.register(nib, forCellReuseIdentifier: "attachmentTableCell")
    }
    
    func setupView(){
        backgroundColor = .clear
        webView.navigationDelegate = self
        heightConstraint.constant = myHeight
        unsendView.layer.borderWidth = 1
        readView.layer.borderWidth = 1
        attachmentView.layer.borderWidth = 1
        borderBGView.layer.borderWidth = 1
        borderBGView.layer.borderColor = UIColor(red:212/255, green:204/255, blue:204/255, alpha: 1).cgColor
    }
    
    func setContent(_ email: Email){
        let isExpanded = email.isExpanded
        webViewWrapperView.isHidden = !isExpanded
        expandedDetailView.isHidden = !isExpanded
        attachmentsTableView.isHidden = !isExpanded
        collapsedDetailView.isHidden = isExpanded
        if(isExpanded){
            setExpandedContent(email)
        }else{
            setCollapsedContent(email)
        }
    }
    
    func setCollapsedContent(_ email: Email){
        let preview = email.isUnsent ? "Unsent" : email.preview
        let numberOfLines = Utils.getNumberOfLines(preview, width: previewLabel.frame.width, fontSize: 17.0)
        previewLabel.text = "\(preview)\(numberOfLines >= 2 ? "" : "\n")"
        contactsCollapseLabel.text = email.fromContact!.displayName
        setCollapsedIcons(email)
        collapsedDateLabel.text = email.getFormattedDate()
        if(email.isUnsent){
            previewLabel.textColor = .alertText
            borderBGView.layer.borderColor = UIColor.alertLight.cgColor
        }
    }
    
    func setExpandedContent(_ email: Email){
        let toContacts = email.getContacts(type: .to)
        let content = email.content
        if(!loadedContent){
            webView.loadHTMLString(Constants.htmlTopWrapper + content + Constants.htmlBottomWrapper, baseURL: nil)
        }
        let fromContactName = email.fromContact!.displayName
        initialsImageView.setImageForName(string: fromContactName, circular: true, textAttributes: nil)
        contactsExpandLabel.text = fromContactName
        moreRecipientsLabel.text = toContacts.count > 1 ? "To \(toContacts.first!.displayName) & \(toContacts.count - 1) more" : "To \(toContacts.first!.displayName)"
        expandedDateLabel.text = email.getFormattedDate()
        setExpandedIcons(email)
    }
    
    func setCollapsedIcons(_ email: Email){
        miniAttachmentIconView.isHidden = true
        guard email.delivered != DeliveryStatus.NONE else {
            miniReadIconView.isHidden = true
            return
        }
        
        miniReadIconView.tintColor = (email.delivered == DeliveryStatus.OPENED) ?  .mainUI : .neutral
    }
    
    func setExpandedIcons(_ email: Email){
        let isUnsent = email.isUnsent
        attachmentView.isHidden = true
        guard email.delivered != DeliveryStatus.NONE else {
            readView.isHidden = true
            unsendView.isHidden = true
            return
        }
        
        readIconView.tintColor = (email.delivered == DeliveryStatus.OPENED) ?  .mainUI : .neutral
        readView.layer.borderColor = (email.delivered == DeliveryStatus.OPENED) ?  UIColor.mainUILight.cgColor : UIColor.neutral.cgColor
        readView.isUserInteractionEnabled = email.delivered == DeliveryStatus.OPENED
        
        unsendIconView.tintColor =  isUnsent ?  .alert : .white
        unsendView.backgroundColor = isUnsent ? .white : .alert
        unsendView.layer.borderColor = isUnsent ?  UIColor.alertLight.cgColor : UIColor.alert.cgColor
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        let touchPt = gestureRecognizer.location(in: self.contentView)
        guard touchPt.y < 103.0 + myHeight,
            let tappedView = self.hitTest(touchPt, with: nil) else {
            return
        }
        
        if tappedView == self.attachmentView || tappedView == self.attachmentIconView{
            delegate.tableViewCellDidTapIcon(self, self.attachmentView, .attachment)
        } else if tappedView == self.unsendView || tappedView == self.unsendIconView{
            delegate.tableViewCellDidTapIcon(self, self.unsendView, .unsend)
        } else if tappedView == self.readView || tappedView == self.readIconView{
            delegate.tableViewCellDidTapIcon(self, self.readView, .read)
        } else if tappedView == self.optionsView || tappedView == self.optionsIconView{
            delegate.tableViewCellDidTapIcon(self, self.optionsView, .options)
        } else if tappedView == self.replyView || tappedView == self.replyIconView{
            delegate.tableViewCellDidTapIcon(self, self.replyView, .reply)
        } else if tappedView == self.moreRecipientsLabel{
            delegate.tableViewCellDidTapIcon(self, self.moreRecipientsLabel, .contacts)
        } else {
            delegate.tableViewCellDidTap(self)
        }
    }
}

extension EmailTableViewCell{
    enum IconType {
        case attachment
        case unsend
        case read
        case options
        case reply
        case contacts
    }
}

extension EmailTableViewCell: WKNavigationDelegate{

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard myHeight <= 0.0 else {
            return
        }
        startObservingHeight()
    }
    
    func startObservingHeight() {
        let options = NSKeyValueObservingOptions([.new])
        webView.scrollView.addObserver(self, forKeyPath: "contentSize", options: options, context: nil)
    }
    
    func stopObservingHeight() {
        webView.scrollView.removeObserver(self, forKeyPath: "contentSize", context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let keypath = keyPath,
            keypath == "contentSize" else {
            super.observeValue(forKeyPath: nil, of: object, change: change, context: context)
            return
        }
        myHeight = webView.scrollView.contentSize.height
        heightConstraint.constant = self.myHeight
        loadedContent = true
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidLoadContent(self)
        stopObservingHeight()
    }
}

extension EmailTableViewCell: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "attachmentTableCell") as! AttachmentTableCell
        cell.setNameAndSize("Red Velvet Members.pdf", "23 MB")
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 0
    }
}
