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
    func tableViewCellDidLoadContent(_ cell:EmailTableViewCell, _ height: CGFloat)
    func tableViewCellDidTap(_ cell: EmailTableViewCell)
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
    var content = ""
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
        webView.isHidden = !isExpanded
        if(isExpanded){
            webView.loadHTMLString(content, baseURL: nil)
        }else{
            myHeight = 0
        }
        expandedDetailView.isHidden = !isExpanded
        collapsedDetailView.isHidden = isExpanded
    }
    
    func toggleCell(_ isExpanded: Bool){
        webView.isHidden = !isExpanded
        expandedDetailView.isHidden = !isExpanded
        collapsedDetailView.isHidden = isExpanded
        if(isExpanded){
            webView.loadHTMLString(content, baseURL: nil)
        }else{
            myHeight = 0
        }
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
            print("Attachment!")
        } else if tappedView == self.unsendView || tappedView == self.unsendIconView{
            print("Unsend!")
        } else if tappedView == self.readView || tappedView == self.readIconView{
            print("Read!")
        } else if tappedView == self.optionsView || tappedView == self.optionsIconView{
            print("Options!")
        } else if tappedView == self.replyView || tappedView == self.replyIconView{
            print("Reply!")
        } else if tappedView == self.moreRecipientsLabel{
            print("More Contacts!")
        } else {
            delegate.tableViewCellDidTap(self)
        }
    }
}

extension EmailTableViewCell: WKNavigationDelegate{

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard myHeight <= 0.0 else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01){
            let myHeight = webView.scrollView.contentSize.height
            
            self.heightConstraint.constant = CGFloat(myHeight)
            guard let delegate = self.delegate else {
                return
            }
            delegate.tableViewCellDidLoadContent(self, myHeight)
        }
        
    }
}
