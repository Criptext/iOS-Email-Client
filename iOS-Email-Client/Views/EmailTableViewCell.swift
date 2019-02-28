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
import SwiftSoup
import Photos

protocol EmailTableViewCellDelegate: class {
    func tableViewCellDidChangeHeight(_ height: CGFloat, email: Email)
    func tableViewCellDidLoadContent(_ cell:EmailTableViewCell, email: Email)
    func tableViewCellDidTap(_ cell: EmailTableViewCell)
    func tableViewCellDidTapIcon(_ cell: EmailTableViewCell, _ sender: UIView, _ iconType: EmailTableViewCell.IconType)
    func tableViewCellDidTapAttachment(file: File)
    func tableViewCellDidTapLink(url: String)
    func tableViewCellDidTapEmail(email: String)
    func tableViewExpandViews()
}

class EmailTableViewCell: UITableViewCell{
    @IBOutlet weak var counterLabelDown: UILabel!
    @IBOutlet weak var counterLabelUp: UILabel!
    @IBOutlet weak var upView: UIView!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var infoViewContainer: UIView!
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
    @IBOutlet weak var circleLoaderUIView: CircleLoaderUIView!
    @IBOutlet weak var moreOptionsIcon: UIImageView!
    let webView: WKWebView
    
    var email: Email!
    var emailState: Email.State!
    var isLoaded = false
    var attachments : Results<File> {
        return email.files.filter("cid == nil OR cid == ''")
    }
    weak var delegate: EmailTableViewCellDelegate?
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    let ATTATCHMENT_CELL_HEIGHT : CGFloat = 68.0
    let RECIPIENTS_MAX_WIDTH: CGFloat = 190.0
    let READ_STATUS_MARGIN: CGFloat = 5.0
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?){
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(CIDSchemeHandler(), forURLScheme: "cid")
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        let config = WKWebViewConfiguration()
        config.setURLSchemeHandler(CIDSchemeHandler(), forURLScheme: "cid")
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 0, height: 0), configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        applyTheme()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
        attachmentsTableView.delegate = self
        attachmentsTableView.dataSource = self
        let nib = UINib(nibName: "AttachmentTableViewCell", bundle: nil)
        attachmentsTableView.register(nib, forCellReuseIdentifier: "attachmentTableCell")
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.scrollView.contentSize), options: .new, context: nil)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(expandView(sender:)))
        upView.addGestureRecognizer(tapGesture)
        bottomView.addGestureRecognizer(tapGesture)
    }
    
    @objc func expandView(sender: UITapGestureRecognizer) {
        delegate?.tableViewExpandViews()
    }
    
    func setupView(){
        backgroundColor = .clear
        borderBGView.layer.borderWidth = 1
        
        webViewWrapperView.addSubview(webView)
        
        webViewWrapperView.addConstraint(NSLayoutConstraint(item: webView, attribute: .top, relatedBy: .equal, toItem: webViewWrapperView, attribute: .top, multiplier: 1.0, constant: 0.0))
        webViewWrapperView.addConstraint(NSLayoutConstraint(item: webView, attribute: .bottom, relatedBy: .equal, toItem: webViewWrapperView, attribute: .bottom, multiplier: 1.0, constant: 0.0))
        webViewWrapperView.addConstraint(NSLayoutConstraint(item: webView, attribute: .leading, relatedBy: .equal, toItem: webViewWrapperView, attribute: .leading, multiplier: 1.0, constant: 0.0))
        webViewWrapperView.addConstraint(NSLayoutConstraint(item: webView, attribute: .trailing, relatedBy: .equal, toItem: webViewWrapperView, attribute: .trailing, multiplier: 1.0, constant: 0.0))
        
        webView.scrollView.bounces = false
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.configuration.userContentController.add(self, name: "iosListener")
        webView.frame = webViewWrapperView.frame
        webView.layoutIfNeeded()
    }
    
    func applyTheme() {
        upView.layer.borderColor = theme.groupEmailBorder.cgColor
        upView.backgroundColor = theme.secondBackground
        bottomView.layer.borderColor = theme.groupEmailBorder.cgColor
        bottomView.backgroundColor = theme.secondBackground
        counterLabelDown.textColor = theme.groupEmailText
        counterLabelUp.textColor = theme.groupEmailText
        
        upView.layer.cornerRadius = upView.frame.size.width/2
        upView.clipsToBounds = true
        upView.layer.borderWidth = 1
        
        bottomView.layer.cornerRadius = bottomView.frame.size.width/2
        bottomView.clipsToBounds = true
        bottomView.layer.borderWidth = 1
        
        borderBGView.layer.borderColor = theme.emailBorder.cgColor
        borderBGView.backgroundColor = theme.secondBackground
        previewLabel.textColor = theme.secondText
        contactsLabel.textColor = theme.secondText
        dateLabel.textColor = theme.secondText
        contactsCollapseLabel.textColor = theme.mainText
        backgroundColor = .clear
        circleLoaderUIView.backgroundColor = .clear
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            webViewEvaluateHeight(self.webView)
            if (webView.scrollView.zoomScale == 1.0) {
                webView.scrollView.setZoomScale(webView.scrollView.minimumZoomScale, animated: false)
            }
        }
        if (keyPath == "scrollView.contentSize"),
            let contentSize = change?[NSKeyValueChangeKey.newKey] as? CGSize,
            contentSize.height != emailState.cellHeight {
            webView.scrollView.contentSize = CGSize(width: contentSize.width, height: emailState.cellHeight)
        }
    }
    
    func setContent(_ email: Email, emailBody: String, state: Email.State, myEmail: String){
        
        self.emailState = state
        self.email = email
        let isExpanded = state.isExpanded
        
        heightConstraint.constant = state.cellHeight
        attachmentsTableView.reloadData()
        attachmentsTableHeightConstraint.constant = ATTATCHMENT_CELL_HEIGHT * CGFloat(attachments.count)
        
        setReadStatus(status: email.status)
        dateLabel.text = email.getFormattedDate()
        let fromContactName = email.isDraft ? String.localize("Draft") : email.fromContact.displayName
        contactsCollapseLabel.text = fromContactName
        contactsCollapseLabel.textColor = email.isDraft ? theme.alert : theme.mainText
        let emailContact = email.isDraft ? "" : email.fromContact.email
        self.initialsImageView.setImageForName(string: fromContactName, circular: true, textAttributes: nil)
        self.initialsImageView.layer.borderWidth = 0.0
        if(!emailContact.isEmpty){
            UIUtils.setProfilePictureImage(imageView: self.initialsImageView, contact: email.fromContact)
        }
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
            setExpandedContent(email, myEmail: myEmail)
        }else{
            setCollapsedContent(email)
        }
        
        if(state.isExpanded && !isLoaded){
            loadWebview(email: email, emailBody: emailBody)
        }
        
        if(state.isUnsending){
            circleLoaderUIView.loaderColor = theme.alert.cgColor
            circleLoaderUIView.layoutSubviews()
            circleLoaderUIView.animate()
            circleLoaderUIView.isHidden = false
        } else {
            circleLoaderUIView.layer.removeAllAnimations()
            circleLoaderUIView.isHidden = true
        }
        
        if(email.isUnsent){
            previewLabel.textColor = theme.alert
            previewLabel.font = Font.italic.size(15.0)!
            borderBGView.layer.borderColor = theme.alert.cgColor
        }
    }
    
    func setCollapsedContent(_ email: Email){
        previewLabel.text = email.getPreview()
    }
    
    func setExpandedContent(_ email: Email, myEmail: String){
        moreOptionsIcon.image = email.isDraft ? #imageLiteral(resourceName: "icon-edit") : #imageLiteral(resourceName: "dots-options")
        let allContacts = email.getContacts(type: .to) + email.getContacts(type: .cc) + email.getContacts(type: .bcc)
        contactsLabel.text = allContacts.reduce("", { (result, contact) -> String in
            let displayName = parseContact(contact, myEmail: myEmail, contactsLength: allContacts.count)
            if(result.isEmpty){
                return "\(String.localize("TO")) \(displayName)"
            }
            return "\(result), \(displayName)"
        })
        let size = contactsLabel.sizeThatFits(CGSize(width: RECIPIENTS_MAX_WIDTH, height: 22.0))
        contactsWidthConstraint.constant = size.width > RECIPIENTS_MAX_WIDTH ? RECIPIENTS_MAX_WIDTH : size.width
    }
    
    func loadWebview(email: Email, emailBody: String){
        let theme = ThemeManager.shared.theme
        isLoaded = true
        let bundleUrl = URL(fileURLWithPath: Bundle.main.bundlePath)
        let anchorColor = theme.name != "Dark" ? "" : "48a3ff"
        let content = "\(Constants.htmlTopWrapper(bgColor: theme.secondBackground.toHexString(), color: theme.mainText.toHexString(), anchorColor: anchorColor))\(emailBody)\(theme.name != "Dark" ? Constants.htmlBottomWrapper : Constants.darkBottomWrapper)"
        webView.scrollView.maximumZoomScale = 2.0
        webView.loadHTMLString(content, baseURL: bundleUrl)
    }
    
    func parseContact(_ contact: Contact, myEmail: String, contactsLength: Int) -> String {
        guard contact.email != myEmail else {
            return String.localize("ME")
        }
        guard contactsLength > 1 else {
            return contact.displayName
        }
        return String(contact.displayName.split(separator: " ")[0])
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
            miniReadIconView.image = #imageLiteral(resourceName: "single-check-icon")
            miniReadIconView.tintColor = theme.icon
        case .delivered:
            miniReadIconView.image = #imageLiteral(resourceName: "double-check")
            miniReadIconView.tintColor = theme.icon
        case .opened:
            miniReadIconView.image = #imageLiteral(resourceName: "double-check")
            miniReadIconView.tintColor = .mainUI
        case .unsent:
            readIconWidthConstraint.constant = 0.0
            readStatusMarginConstraint.constant = 0.0
            readStatusContentMarginConstraint.constant = 0.0
            miniReadIconView.isHidden = true
        case .sending, .fail:
            miniReadIconView.image = #imageLiteral(resourceName: "waiting-icon")
            miniReadIconView.tintColor = theme.icon
        }
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        let touchPt = gestureRecognizer.location(in: self.contentView)
        guard touchPt.y < 103.0 + self.emailState.cellHeight,
            let tappedView = self.hitTest(touchPt, with: nil) else {
            return
        }
        
        if tappedView == self.moreOptionsContainerView {
            if(email.isDraft){
                delegate.tableViewCellDidTapIcon(self, self.moreOptionsContainerView, .edit)
            }else{
                delegate.tableViewCellDidTapIcon(self, self.moreOptionsContainerView, .options)
            }
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
        if (!webView.isLoading && scrollView.contentSize.width < webView.frame.width) {
            let scale = (webView.frame.width * scrollView.zoomScale/scrollView.contentSize.width)
            webView.scrollView.setZoomScale(scale, animated: false)
        }
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
            let newHeight = height * self.webView.scrollView.zoomScale
            guard newHeight != self.emailState.cellHeight else {
                return
            }
            self.heightConstraint.constant = newHeight
            self.webView.invalidateIntrinsicContentSize()
            self.delegate?.tableViewCellDidChangeHeight(newHeight, email: self.email)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated,
            let link = navigationAction.request.url?.absoluteString {
            if Utils.verifyUrl(urlString: link) {
                decisionHandler(.cancel)
                delegate?.tableViewCellDidTapLink(url: link)
                return
            }
            if let email = link.split(separator: ":").last,
                Utils.validateEmail(String(email)) {
                decisionHandler(.cancel)
                delegate?.tableViewCellDidTapEmail(email: String(email))
                return
            }
        }
        decisionHandler(.allow)
    }
}

extension EmailTableViewCell: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attachment = attachments[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "attachmentTableCell") as! AttachmentTableCell
        if(attachment.status == 0) {
            cell.setAsUnsend()
            cell.delegate = nil
        } else {
            cell.setFields(attachment)
            cell.delegate = self
        }
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
