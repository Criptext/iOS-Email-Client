//
//  AttachmentViewController.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 5/2/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import UIKit
import QuickLook

class AttachmentViewController: UIViewController {
    @IBOutlet weak var webView: UIWebView!

    @IBOutlet weak var navItem: UINavigationItem!
    
    var currentAttachment:File!
    lazy var previewController = QLPreviewController()
    lazy var previewItem = PreviewItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.previewController.dataSource = self
        self.navItem.title = self.currentAttachment.name
        self.title = self.currentAttachment.name
        self.showSnackbar("Loading...", attributedText: nil, buttons: "", permanent: true)
        self.webView.loadRequest(URLRequest(url: URL(string: "https://mail.criptext.com/viewer/\(self.currentAttachment.token)")!))
        
    }
    
    @IBAction func didPressCancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension AttachmentViewController: UIWebViewDelegate {
    func webViewDidFinishLoad(_ webView: UIWebView) {
        self.hideSnackbar()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        guard navigationType == .linkClicked, let url = request.url, url.path.contains("/attachment/download") else {
            return true
        }
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = NSString(string:self.currentAttachment.name)
        
        
        let fileURL = documentsURL.appendingPathComponent(url.lastPathComponent).appendingPathExtension(filename.pathExtension)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            //show the file
            self.previewItem.previewItemURL = fileURL
            self.previewItem.previewItemTitle = self.currentAttachment.name
            self.previewController.reloadData()
            self.present(self.previewController, animated: true, completion: nil)
            return false
        }
        
        CriptextSpinner.show(in: self.view, title: "Downloading")
        
        return false
    }
}

extension AttachmentViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return self.previewItem
    }
}
