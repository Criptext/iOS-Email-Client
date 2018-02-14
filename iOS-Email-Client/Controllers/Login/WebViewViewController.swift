//
//  WebViewViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/14/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import WebKit

class WebViewViewController: UIViewController{
    @IBOutlet weak var webview: WKWebView!
    var url : String?
    
    @IBAction func onClosePress(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let url = self.url else {return}
        let myURL = URL(string: url)
        let myRequest = URLRequest(url: myURL!)
        webview.load(myRequest)
    }
}
