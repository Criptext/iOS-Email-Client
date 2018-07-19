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
    func tableViewCellDidChangeHeight(_ height: CGFloat, email: Email)
    func tableViewCellDidLoadContent(_ cell:EmailTableViewCell, email: Email)
    func tableViewCellDidTap(_ cell: EmailTableViewCell)
    func tableViewCellDidTapIcon(_ cell: EmailTableViewCell, _ sender: UIView, _ iconType: EmailTableViewCell.IconType)
    func tableViewCellDidTapAttachment(file: File)
    func tableViewCellDidTapLink(url: String)
}

class EmailTableViewCell: UITableViewCell{
    @IBOutlet weak var infoViewContainer: UIView!
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var previewLabel: UILabel!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var webViewWrapperView: UIView!
    @IBOutlet weak var borderBGView: UIView!
    @IBOutlet weak var contactsCollapseLabel: UILabel!
    @IBOutlet weak var miniAttachmentIconView: UIImageView!
    @IBOutlet weak var miniReadIconView: UIImageView!
    @IBOutlet weak var attachmentsTableView: UITableView!
    @IBOutlet weak var attachmentsTableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var initialsImageView: UIImageView!
    @IBOutlet weak var moreOptionsContainerView: UIView!
    @IBOutlet weak var moreInfoContainerView: UIButton!
    @IBOutlet weak var contactsLabel: UILabel!
    @IBOutlet weak var readIconWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var contactsWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomMarginView: UIView!
    @IBOutlet weak var attachmentsTopMarginView: UIView!
    @IBOutlet weak var dateWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var readStatusMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var readStatusContentMarginConstraint: NSLayoutConstraint!
    
    
    var loadedContent = false
    var myHeight : CGFloat = 0.0
    var email: Email!
    var attachments : List<File> {
        return email.files
    }
    var delegate: EmailTableViewCellDelegate?
    let ATTATCHMENT_CELL_HEIGHT : CGFloat = 68.0
    let RECIPIENTS_MAX_WIDTH: CGFloat = 130.0
    let READ_STATUS_MARGIN: CGFloat = 5.0
    
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
        
        setReadStatus(status: email.status)
        dateLabel.text = email.getFormattedDate()
        contactsCollapseLabel.text = email.fromContact.displayName
        let fromContactName = email.fromContact.displayName
        initialsImageView.setImageForName(string: fromContactName, circular: true, textAttributes: nil)
        let size = dateLabel.sizeThatFits(CGSize(width: 100.0, height: 19))
        dateWidthConstraint.constant = size.width
        
        miniAttachmentIconView.isHidden = email.files.count == 0
        webViewWrapperView.isHidden = !isExpanded
        attachmentsTableView.isHidden = !isExpanded
        previewLabel.isHidden = isExpanded
        moreOptionsContainerView.isHidden = !isExpanded
        moreInfoContainerView.isHidden = !isExpanded
        contactsLabel.isHidden = !isExpanded
        bottomMarginView.isHidden = !isExpanded
        
        if(isExpanded){
            setExpandedContent(email)
        }else{
            setCollapsedContent(email)
        }
        
        if(email.isUnsent){
            previewLabel.textColor = .alertText
            borderBGView.layer.borderColor = UIColor.alertLight.cgColor
        }
    }
    
    func setCollapsedContent(_ email: Email){
        previewLabel.text = email.isUnsent ? "Unsent" : email.preview
    }
    
    func setExpandedContent(_ email: Email){
        let allContacts = email.getContacts(type: .to) + email.getContacts(type: .cc) + email.getContacts(type: .bcc)
        contactsLabel.text = allContacts.reduce("", { (result, contact) -> String in
            if(result.isEmpty){
                return "To \(contact.displayName)"
            }
            return "\(result), \(contact.displayName)"
        })
        let size = contactsLabel.sizeThatFits(CGSize(width: 130.0, height: 22.0))
        contactsWidthConstraint.constant = size.width > RECIPIENTS_MAX_WIDTH ? RECIPIENTS_MAX_WIDTH : size.width
        if(!loadedContent){
            let bundleUrl = URL(fileURLWithPath: Bundle.main.bundlePath)
            webView.loadHTMLString("\(Constants.htmlTopWrapper)\(email.content)\(Constants.htmlBottomWrapper)", baseURL: bundleUrl)
        }
    }
    
    func setReadStatus(status: Email.Status){
        readIconWidthConstraint.constant = status == .none ? 0.0 : 16.0
        readStatusMarginConstraint.constant = status == .none ? 0.0 : READ_STATUS_MARGIN
        readStatusContentMarginConstraint.constant = status == .none ? 0.0 : READ_STATUS_MARGIN
        miniReadIconView.isHidden = status == .none
        switch(status){
        case .none:
            break
        case .sent:
            miniReadIconView.image = #imageLiteral(resourceName: "double-check")
            miniReadIconView.tintColor = UIColor(red: 182/255, green: 182/255, blue: 182/255, alpha: 1)
        case .delivered:
            miniReadIconView.image = #imageLiteral(resourceName: "double-check")
            miniReadIconView.tintColor = UIColor(red: 182/255, green: 182/255, blue: 182/255, alpha: 1)
        case .opened:
            miniReadIconView.image = #imageLiteral(resourceName: "double-check")
            miniReadIconView.tintColor = .mainUI
        case .unsent:
            readIconWidthConstraint.constant = 0.0
            miniReadIconView.isHidden = true
        case .sending, .fail:
            miniReadIconView.image = #imageLiteral(resourceName: "expiration-email-icon")
            miniReadIconView.tintColor = UIColor(red: 182/255, green: 182/255, blue: 182/255, alpha: 1)
        }
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
        
        if tappedView == self.moreOptionsContainerView {
            delegate.tableViewCellDidTapIcon(self, self.moreOptionsContainerView, .options)
        } else if tappedView == self.moreInfoContainerView || tappedView == self.contactsLabel {
            delegate.tableViewCellDidTapIcon(self, self.moreInfoContainerView, .contacts)
        } else {
            delegate.tableViewCellDidTap(self)
        }
    }
    
    @IBAction func onMorePress(_ sender: Any) {
        delegate?.tableViewCellDidTapIcon(self, self.moreInfoContainerView, .contacts)
    }
    
}

extension EmailTableViewCell{
    enum IconType {
        case options
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
        self.delegate?.tableViewCellDidLoadContent(self, email: self.email)
        webViewEvaluateHeight(webView)
    }
    
    func webViewEvaluateHeight(_ webview: WKWebView, didZoom: Bool = false){
        let jsString = "document.body.clientHeight + (document.body.childNodes[0].offsetTop || 0)"
        webView.evaluateJavaScript(jsString) { (result, error) in
            guard let height = result as? CGFloat else {
                return
            }
            let newHeight = height + height * (self.webView.scrollView.zoomScale - 1)
            guard newHeight != self.myHeight else {
                return
            }
            self.myHeight = newHeight
            self.heightConstraint.constant = newHeight
            self.loadedContent = true
            self.delegate?.tableViewCellDidChangeHeight(newHeight, email: self.email)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard navigationAction.navigationType == .linkActivated,
            let link = navigationAction.request.url?.absoluteString else {
                decisionHandler(.allow)
                return
        }
        decisionHandler(.cancel)
        delegate?.tableViewCellDidTapLink(url: link)
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
