//
//  TheRichTextEditor.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 12/17/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import UIKit
import WebKit

public protocol TheRichTextEditorDelegate: class {
    func textDidChange(content: String)
    func heightDidChange()
    func editorDidLoad()
    func scrollOffset(verticalOffset: CGFloat)
}

fileprivate class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
}

public class TheRichTextEditor: UIView, WKScriptMessageHandler, WKNavigationDelegate, UIScrollViewDelegate {
    private static let textDidChange = "textDidChange"
    private static let heightDidChange = "heightDidChange"
    private static let previewDidChange = "previewDidChange"
    private static let documentHasLoaded = "documentHasLoaded"
    
    private static let defaultHeight: CGFloat = 60

    public weak var delegate: TheRichTextEditorDelegate?
    public var height: CGFloat = TheRichTextEditor.defaultHeight

    public var placeholder: String? {
        didSet {
            webView.evaluateJavaScript("richeditor.setPlaceholderText('\(placeholder ?? "")')")
        }
    }

    private var textToLoad: String?
    
    public var html: String = "" {
        didSet {
            if webView.isLoading {
                textToLoad = html
            } else {
                webView.evaluateJavaScript("richeditor.insertText(\"\(html.htmlEscapeQuotes)\");")
                body = html
            }
        }
    }
    
    public var preview: String = ""
    public var body: String = ""

    var webView: WKWebView!

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    var enableAccessoryView: Bool {
        set {
            (webView as? CustomWebview)?.enableAccessoryView = newValue
        }
        
        get {
            return (webView as? CustomWebview)?.enableAccessoryView ?? false
        }
    }
    
    func setup() {
        guard let scriptPath = Bundle.main.path(forResource: "main", ofType: "js"),
            let scriptContent = try? String(contentsOfFile: scriptPath, encoding: String.Encoding.utf8),
            let htmlPath = Bundle.main.path(forResource: "main", ofType: "html"),
            let html = try? String(contentsOfFile: htmlPath, encoding: String.Encoding.utf8)
            else {
            fatalError("Unable to find javscript/html for text editor")
        }

        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(
            WKUserScript(source: scriptContent,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: true
            )
        )

        webView = CustomWebview(frame: .zero, configuration: configuration)
        (webView as? CustomWebview)?.toolbarDelegate = self

        [TheRichTextEditor.textDidChange, TheRichTextEditor.heightDidChange, TheRichTextEditor.previewDidChange, TheRichTextEditor.documentHasLoaded].forEach {
            configuration.userContentController.add(WeakScriptMessageHandler(delegate: self), name: $0)
        }

        webView.keyboardDisplayRequiresUserAction = false
        webView.navigationDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.maximumZoomScale = 1
        webView.scrollView.minimumZoomScale = 1
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.bounces = false
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.delegate = self

        addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: leadingAnchor),
            webView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            webView.trailingAnchor.constraint(equalTo: trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        webView.loadHTMLString(html, baseURL: Bundle.main.bundleURL)
    }

    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case TheRichTextEditor.textDidChange:
            guard let body = message.body as? String else { return }
            self.body = body
            delegate?.textDidChange(content: body)
        case TheRichTextEditor.heightDidChange:
            guard let height = message.body as? CGFloat else { return }
            if (height + 20 != self.height) {
                print(self.height)
                self.height = height + 20
                delegate?.heightDidChange()
            }
        case TheRichTextEditor.previewDidChange:
            guard let preview = message.body as? String else { return }
            self.preview = preview
        case TheRichTextEditor.documentHasLoaded:
            delegate?.editorDidLoad()
        default:
            break
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let textToLoad = textToLoad {
            self.textToLoad = nil
            html = textToLoad
        }
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        scrollView.pinchGestureRecognizer?.isEnabled = false
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y != 0) {
            delegate?.scrollOffset(verticalOffset: scrollView.contentOffset.y)
        }
        scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
    }
    
    public func viewForZooming(in: UIScrollView) -> UIView? {
        return nil
    }
    
    public override func endEditing(_ force: Bool) -> Bool {
        webView.endEditing(force)
        return super.endEditing(force)
    }
    
    public func setEditorFontColor(_ color: UIColor) {
        webView.evaluateJavaScript("richeditor.setBaseTextColor('#\(color.toHexString())');", completionHandler: nil)
    }
    
    public func setEditorBackgroundColor(_ color: UIColor) {
        webView.evaluateJavaScript("richeditor.setBackgroundColor('#\(color.toHexString())');", completionHandler: nil)
    }

    public func focus() {
        webView.evaluateJavaScript("richeditor.focus();", completionHandler: nil)
    }

    public func focus(at: CGPoint) {
        webView.evaluateJavaScript("richeditor.focusAtPoint(\(at.x), \(at.y));", completionHandler: nil)
    }
    
    public func runCommand(_ command: String) {
        webView.evaluateJavaScript("document.execCommand('\(command)', false, null);", completionHandler: nil)
    }
}

extension TheRichTextEditor: WebviewToolbarDelegate {
    func onUndoPress() {
        self.runCommand("undo")
    }
    
    func onRedoPress() {
        self.runCommand("redo")
    }
    
    func onTextAlignCenter() {
        self.runCommand("justifyCenter")
    }
    
    func onIndentPress() {
        self.runCommand("indent")
    }
    
    func onOutdentPress() {
        self.runCommand("outdent")
    }
    
    func onClearPress() {
        self.runCommand("removeFormat")
    }
    
    func onItalicPress() {
        self.runCommand("italic")
    }
    
    func onTextAlignLeft() {
        self.runCommand("justifyLeft")
    }
    
    func onTextAlignRight() {
        self.runCommand("justifyRight")
    }
    
    func onBoldPress() {
        self.runCommand("bold")
    }
}

fileprivate extension String {

    var htmlToPlainText: String {
        return [
            ("(<[^>]*>)|(&\\w+;)", " "),
            ("[ ]+", " ")
        ].reduce(self) {
            try! $0.replacing(pattern: $1.0, with: $1.1)
        }.resolvedHTMLEntities
    }

    var resolvedHTMLEntities: String {
        return self
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#x27;", with: "'")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
    }

    func replacing(pattern: String, with template: String) throws -> String {
        let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        return regex.stringByReplacingMatches(in: self, options: [], range: NSRange(0..<self.utf16.count), withTemplate: template)
    }

    var htmlEscapeQuotes: String {
        return [
            ("\"", "\\\""),
            ("“", "&quot;"),
            ("\r", "\\r"),
            ("\n", "\\n")
        ].reduce(self) {
            return $0.replacingOccurrences(of: $1.0, with: $1.1)
        }
    }
}

typealias OldClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Any?) -> Void
typealias NewClosureType =  @convention(c) (Any, Selector, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void

extension WKWebView{
    var keyboardDisplayRequiresUserAction: Bool? {
        get {
            return self.keyboardDisplayRequiresUserAction
        }
        set {
            self.setKeyboardRequiresUserInteraction(newValue ?? true)
        }
    }

    func setKeyboardRequiresUserInteraction( _ value: Bool) {
        guard let WKContentView: AnyClass = NSClassFromString("WKContentView") else {
            print("keyboardDisplayRequiresUserAction extension: Cannot find the WKContentView class")
            return
        }
        // For iOS 10, *
        let sel_10: Selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:")
        // For iOS 11.3, *
        let sel_11_3: Selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
        // For iOS 12.2, *
        let sel_12_2: Selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:")
        // For iOS 13.0, *
        let sel_13_0: Selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:")

        if let method = class_getInstanceMethod(WKContentView, sel_10) {
            let originalImp: IMP = method_getImplementation(method)
            let original: OldClosureType = unsafeBitCast(originalImp, to: OldClosureType.self)
            let block : @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Any?) -> Void = { (me, arg0, arg1, arg2, arg3) in
                original(me, sel_10, arg0, !value, arg2, arg3)
            }
            let imp: IMP = imp_implementationWithBlock(block)
            method_setImplementation(method, imp)
        }

        if let method = class_getInstanceMethod(WKContentView, sel_11_3) {
            let originalImp: IMP = method_getImplementation(method)
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            let block : @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void = { (me, arg0, arg1, arg2, arg3, arg4) in
                original(me, sel_11_3, arg0, !value, arg2, arg3, arg4)
            }
            let imp: IMP = imp_implementationWithBlock(block)
            method_setImplementation(method, imp)
        }

        if let method = class_getInstanceMethod(WKContentView, sel_12_2) {
            let originalImp: IMP = method_getImplementation(method)
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            let block : @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void = { (me, arg0, arg1, arg2, arg3, arg4) in
                original(me, sel_12_2, arg0, !value, arg2, arg3, arg4)
            }
            let imp: IMP = imp_implementationWithBlock(block)
            method_setImplementation(method, imp)
        }

        if let method = class_getInstanceMethod(WKContentView, sel_13_0) {
            let originalImp: IMP = method_getImplementation(method)
            let original: NewClosureType = unsafeBitCast(originalImp, to: NewClosureType.self)
            let block : @convention(block) (Any, UnsafeRawPointer, Bool, Bool, Bool, Any?) -> Void = { (me, arg0, arg1, arg2, arg3, arg4) in
                original(me, sel_13_0, arg0, !value, arg2, arg3, arg4)
            }
            let imp: IMP = imp_implementationWithBlock(block)
            method_setImplementation(method, imp)
        }
    }
}
