//
//  MembershipWebViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 4/20/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import WebKit

protocol MembershipWebViewControllerDelegate: class {
    func close()
}

class MembershipWebViewController: UIViewController {
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var loaderView: UIActivityIndicatorView!
    var delegate: MembershipWebViewControllerDelegate? = nil
    var accountJWT: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loaderView.isHidden = false
        loaderView.startAnimating()
        webview.isHidden = true
        
        navigationItem.title = String.localize("PLUS_MEMBERSHIP")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        webview.navigationDelegate = self
        
        let url = URL(string: "https://admin.criptext.com/?#/account/billing?token=\(accountJWT)")!
        webview.load(URLRequest(url: url))
        
        webview.allowsBackForwardNavigationGestures = true
        webview.configuration.userContentController.add(self, name: "iosListener")
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
}

extension MembershipWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaderView.isHidden = true
        loaderView.stopAnimating()
        webview.isHidden = false
    }
}

extension MembershipWebViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension MembershipWebViewController: WKScriptMessageHandler{

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("DICTIONARY : \(message.body)")
        guard let dict = message.body as? [String: Any],
            let messageType = dict["type"] as? String else {
            return
        }
        if (messageType == "close") {
            delegate?.close()
        }
    }

}
