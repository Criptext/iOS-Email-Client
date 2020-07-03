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
    
    enum Kind {
        case plus
        case addresses
        
        func getUrl(jwt: String) -> URL {
            switch(self) {
            case .plus:
                return URL(string: "\(Env.adminURL)/?#/account/billing?lang=\(Env.language)&token=\(jwt)")!
            case .addresses:
                return URL(string: "\(Env.adminURL)/?#/addresses?lang=\(Env.language)&token=\(jwt)")!
            }
        }
    }
    
    @IBOutlet weak var webview: WKWebView!
    @IBOutlet weak var loaderView: UIActivityIndicatorView!
    @IBOutlet weak var failureWrapperView: UIView!
    @IBOutlet weak var failureTitleView: UILabel!
    @IBOutlet weak var failureDescView: UILabel!
    
    var delegate: MembershipWebViewControllerDelegate? = nil
    var initialTitle = String.localize("JOIN_PLUS")
    var accountJWT: String = ""
    var kind: Kind = .plus
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyTheme()
        
        failureWrapperView.isHidden = true
        loaderView.isHidden = false
        loaderView.startAnimating()
        webview.isHidden = true
        
        navigationItem.title = initialTitle
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        webview.navigationDelegate = self
        
        let url = kind.getUrl(jwt: self.accountJWT)
        webview.load(URLRequest(url: url))
        
        webview.allowsBackForwardNavigationGestures = true
        webview.allowsLinkPreview = true
        webview.configuration.userContentController.add(self, name: "iosListener")
        
        webview.scrollView.maximumZoomScale = 1
        
        webview.uiDelegate = self
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        failureTitleView.textColor = theme.markedText
        failureDescView.textColor = theme.mainText
        view.backgroundColor = theme.overallBackground
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    func showFailureView() {
        loaderView.isHidden = true
        loaderView.stopAnimating()
        failureTitleView.text = String.localize("SOMETHING_WRONG")
        failureDescView.text = String.localize("CONNECTION_LOST")
        failureWrapperView.isHidden = false
        webview.isHidden = true
    }
}

extension MembershipWebViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if !(navigationAction.targetFrame?.isMainFrame ?? false) {
            webview.load(navigationAction.request)
        }
        return nil
    }
}

extension MembershipWebViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        loaderView.isHidden = true
        loaderView.stopAnimating()
        webview.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showFailureView()
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showFailureView()
    }
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        showFailureView()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
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
        guard let dict = message.body as? [String: Any],
            let messageType = dict["type"] as? String else {
            return
        }
        if (messageType == "close") {
            delegate?.close()
        }
    }

}
