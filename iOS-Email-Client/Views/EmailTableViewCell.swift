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
    func tableViewCellDidLoadContent(_ cell:EmailTableViewCell, _ height: Int)
}

class EmailTableViewCell: UITableViewCell{
    @IBOutlet weak var webView: WKWebView!
    var delegate: EmailTableViewCellDelegate?
    @IBOutlet weak var previewLabel: UILabel!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    var content = ""
    var myHeight = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        webView.navigationDelegate = self
        heightConstraint.constant = CGFloat(myHeight)
    }
    
    func setContent(_ preview: String, _ content : String, isExpanded: Bool){
        self.content = content
        previewLabel.text = preview
        webView.isHidden = !isExpanded
        if(isExpanded){
            webView.loadHTMLString(content, baseURL: nil)
        }
    }
    
    func toggleCell(_ isExpanded: Bool){
        webView.isHidden = !isExpanded
        if(isExpanded){
            webView.loadHTMLString(content, baseURL: nil)
        }else{
            myHeight = 0
        }
    }
}

extension EmailTableViewCell: WKNavigationDelegate{

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("hablash")
        guard myHeight <= 0 else {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01){
            let myHeight = webView.scrollView.contentSize.height
            
            self.heightConstraint.constant = CGFloat(myHeight)
            print(myHeight)
            guard let delegate = self.delegate else {
                return
            }
            delegate.tableViewCellDidLoadContent(self, Int(myHeight))
        }
        
    }
}
