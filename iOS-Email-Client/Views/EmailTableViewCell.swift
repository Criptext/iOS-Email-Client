//
//  EmailTableViewCell.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/27/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import WebKit
import RealmSwift

protocol EmailTableViewCellDelegate {
    func tableViewCellDidLoadContent(_ cell:EmailTableViewCell, email: Email)
    func tableViewCellDidTap(_ cell: EmailTableViewCell)
    func tableViewCellDidTapIcon(_ cell: EmailTableViewCell, _ sender: UIView, _ iconType: EmailTableViewCell.IconType)
    func tableViewCellDidTapAttachment(file: File)
}

class EmailTableViewCell: UITableViewCell{
    @IBOutlet weak var webView: WKWebView!
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
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var editIconView: UIImageView!
    @IBOutlet weak var replyView: UIView!
    @IBOutlet weak var replyIconView: UIImageView!
    @IBOutlet weak var webViewWrapperView: UIView!
    @IBOutlet weak var borderBGView: UIView!
    @IBOutlet weak var contactsCollapseLabel: UILabel!
    @IBOutlet weak var contactsExpandLabel: UILabel!
    @IBOutlet weak var miniAttachmentIconView: UIImageView!
    @IBOutlet weak var miniReadIconView: UIImageView!
    @IBOutlet weak var attachmentsTableView: UITableView!
    @IBOutlet weak var attachmentsTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collapsedDateLabel: UILabel!
    @IBOutlet weak var expandedDateLabel: UILabel!
    @IBOutlet weak var initialsImageView: UIImageView!
    @IBOutlet weak var bottomMarginHeightConstraint: NSLayoutConstraint!
    var loadedContent = false
    var myHeight : CGFloat = 0.0
    var email: Email!
    var attachments : List<File> {
        return email.files
    }
    var delegate: EmailTableViewCellDelegate?
    let MARGIN_HEIGHT : CGFloat = 15.0
    let ATTATCHMENT_CELL_HEIGHT : CGFloat = 68.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
        attachmentsTableView.delegate = self
        attachmentsTableView.dataSource = self
        let nib = UINib(nibName: "AttachmentTableViewCell", bundle: nil)
        attachmentsTableView.register(nib, forCellReuseIdentifier: "attachmentTableCell")
        webView.scrollView.addObserver(self, forKeyPath: "contentSize", options: .new, context: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == "contentSize" else {
            return
        }
        if( webView.scrollView.contentSize.height != self.myHeight) {
            webView.scrollView.contentSize = CGSize(width: webView.scrollView.contentSize.width, height: self.myHeight)
        }
    }
    
    func setupView(){
        backgroundColor = .clear
        heightConstraint.constant = myHeight
        unsendView.layer.borderWidth = 1
        readView.layer.borderWidth = 1
        attachmentView.layer.borderWidth = 1
        borderBGView.layer.borderWidth = 1
        borderBGView.layer.borderColor = UIColor(red:212/255, green:204/255, blue:204/255, alpha: 1).cgColor
        
        webView.scrollView.bouncesZoom = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.configuration.userContentController.add(self, name: "iosListener")
    }
    
    func setContent(_ email: Email){
        self.email = email
        let isExpanded = email.isExpanded
        attachmentsTableView.reloadData()
        attachmentsTableHeightConstraint.constant = ATTATCHMENT_CELL_HEIGHT * CGFloat(attachments.count)
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
        contactsCollapseLabel.text = email.fromContact.displayName
        setCollapsedIcons(email)
        collapsedDateLabel.text = email.getFormattedDate()
        let fromContactName = email.fromContact.displayName
        initialsImageView.setImageForName(string: fromContactName, circular: true, textAttributes: nil)
        bottomMarginHeightConstraint.constant = 0
        if(email.isUnsent){
            previewLabel.textColor = .alertText
            borderBGView.layer.borderColor = UIColor.alertLight.cgColor
        }
    }
    
    func setExpandedContent(_ email: Email){
        let toContacts = email.getContacts(type: .to)
        let content = email.content
        if(!loadedContent){
            webView.loadHTMLString(Constants.htmlTopWrapper + content + Constants.htmlBottomWrapper, baseURL: URL(fileURLWithPath: Constants.imagePath))
        }
        let isDraft = email.labels.contains(where: {$0.id == SystemLabel.draft.id})
        optionsView.isHidden = isDraft
        replyView.isHidden = isDraft
        editView.isHidden = !isDraft
        
        bottomMarginHeightConstraint.constant = MARGIN_HEIGHT
        let fromContactName = email.fromContact.displayName
        let allContacts = toContacts + email.getContacts(type: .cc) + email.getContacts(type: .bcc)
        contactsExpandLabel.text = fromContactName
        moreRecipientsLabel.text = allContacts.count > 1 ? "To \(allContacts.first!.displayName) & \(allContacts.count - 1) more" : "To \(allContacts.first!.displayName)"
        expandedDateLabel.text = email.getFormattedDate()
        setExpandedIcons(email)
    }
    
    func setCollapsedIcons(_ email: Email){
        miniAttachmentIconView.isHidden = email.files.isEmpty
        guard email.status != .none else {
            miniReadIconView.isHidden = true
            return
        }
        miniAttachmentIconView.tintColor = .neutral
        miniReadIconView.tintColor = (email.status == .opened) ?  .mainUI : .neutral
    }
    
    func setExpandedIcons(_ email: Email){
        let isUnsent = email.isUnsent
        let isRead = email.status == .opened
        guard email.status != .none else {
            readView.isHidden = true
            unsendView.isHidden = true
            attachmentView.isHidden = true
            return
        }
        
        attachmentView.isHidden = email.files.isEmpty
        attachmentView.tintColor = .neutral
        attachmentView.layer.borderColor = UIColor.neutral.cgColor
        
        readIconView.tintColor = isRead ?  .mainUI : .neutral
        readView.layer.borderColor = isRead ?  UIColor.mainUILight.cgColor : UIColor.neutral.cgColor
        
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
        
        if tappedView == self.attachmentView || tappedView == self.attachmentIconView {
            delegate.tableViewCellDidTapIcon(self, self.attachmentView, .attachment)
        } else if tappedView == self.unsendView || tappedView == self.unsendIconView {
            delegate.tableViewCellDidTapIcon(self, self.unsendView, .unsend)
        } else if tappedView == self.readView || tappedView == self.readIconView {
            delegate.tableViewCellDidTapIcon(self, self.readView, .read)
        } else if tappedView == self.optionsView || tappedView == self.optionsIconView {
            delegate.tableViewCellDidTapIcon(self, self.optionsView, .options)
        } else if tappedView == self.replyView || tappedView == self.replyIconView {
            delegate.tableViewCellDidTapIcon(self, self.replyView, .reply)
        } else if tappedView == self.editView || tappedView == self.editIconView {
            delegate.tableViewCellDidTapIcon(self, self.editView, .edit)
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
        case edit
    }
}

extension EmailTableViewCell: WKNavigationDelegate, WKScriptMessageHandler, UIScrollViewDelegate{
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: 0), animated: false)
        webViewEvaluateHeight(self.webView)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        webViewEvaluateHeight(webView)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewEvaluateHeight(webView)
    }
    
    func webViewEvaluateHeight(_ webview: WKWebView){
        let jsString = "document.body.clientHeight + (document.body.childNodes[0].offsetTop || 0)"
        webView.evaluateJavaScript(jsString) { (result, error) in
            guard let height = result as? CGFloat else {
                return
            }
            self.myHeight = height + height * (self.webView.scrollView.zoomScale - 1)
            self.heightConstraint.constant = height + height * (self.webView.scrollView.zoomScale - 1)
            self.delegate?.tableViewCellDidLoadContent(self, email: self.email)
            self.loadedContent = true
        }
    }
}

extension EmailTableViewCell: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attachment = attachments[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "attachmentTableCell") as! AttachmentTableCell
        cell.setFields(attachment)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attachments.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return ATTATCHMENT_CELL_HEIGHT
    }
}

extension EmailTableViewCell: AttachmentTableCellDelegate {
    func tableCellDidTap(_ cell: AttachmentTableCell) {
        guard let indexPath = attachmentsTableView.indexPath(for: cell) else {
            return
        }
        
        let file = attachments[indexPath.row]
        delegate?.tableViewCellDidTapAttachment(file: file)
    }
}
