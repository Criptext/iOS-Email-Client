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
    var content = ""
    var loadedContent = false
    var myHeight : CGFloat = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupView()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tap)
    }
    
    func setupView(){
        webView.navigationDelegate = self
        heightConstraint.constant = myHeight
        unsendView.layer.borderWidth = 1
        unsendView.layer.borderColor = UIColor(red: 221/255, green: 64/255, blue: 64/255, alpha: 1).cgColor
        readView.layer.borderWidth = 1
        readView.layer.borderColor = UIColor(red: 0, green: 145/255, blue: 1, alpha: 0.63).cgColor
        attachmentView.layer.borderWidth = 1
        attachmentView.layer.borderColor = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1).cgColor
    }
    
    func setContent(_ preview: String, _ content : String, isExpanded: Bool){
        self.content = content
        previewLabel.text = preview
        webViewWrapperView.isHidden = !isExpanded
        if(isExpanded){
            if(!loadedContent){
                webView.loadHTMLString(content, baseURL: nil)
            }
        }
        expandedDetailView.isHidden = !isExpanded
        collapsedDetailView.isHidden = isExpanded
    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        guard let delegate = self.delegate else {
            return
        }
        let touchPt = gestureRecognizer.location(in: self.contentView)
        guard let tappedView = self.hitTest(touchPt, with: nil) else {
            return
        }
        
        if tappedView == self.attachmentView || tappedView == self.attachmentIconView{
            delegate.tableViewCellDidTapIcon(self, self.attachmentView, .attachment)
        } else if tappedView == self.unsendView || tappedView == self.unsendIconView{
            // TODO: call delegate to handle unsend icon click
        } else if tappedView == self.readView || tappedView == self.readIconView{
            // TODO: call delegate to handle read icon click
        } else if tappedView == self.optionsView || tappedView == self.optionsIconView{
            // TODO: call delegate to handle options icon click
        } else if tappedView == self.replyView || tappedView == self.replyIconView{
            // TODO: call delegate to handle reply icon click
        } else if tappedView == self.moreRecipientsLabel{
            // TODO: call delegate to handle contacts label click
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
        print(self.myHeight)
        heightConstraint.constant = self.myHeight
        loadedContent = true
        guard let delegate = self.delegate else {
            return
        }
        delegate.tableViewCellDidLoadContent(self)
        stopObservingHeight()
    }
}
