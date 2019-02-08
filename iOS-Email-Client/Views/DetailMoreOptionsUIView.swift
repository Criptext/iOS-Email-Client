//
//  EmailDetailMoreOptionsView.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 4/20/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

protocol DetailMoreOptionsViewDelegate: class{
    func onReplyPress()
    func onReplyAllPress()
    func onForwardPress()
    func onDeletePress()
    func onMarkPress()
    func onSpamPress()
    func onUnsendPress()
    func onOverlayPress()
    func onPrintPress()
    func onRetryPress()
    func onShowSourcePress()
}

class DetailMoreOptionsUIView: UIView {
    
    let OPTIONS_HEIGHT_DEFAULT : CGFloat = 333.0
    let TOP_DEFAULT : CGFloat = 15
    
    @IBOutlet weak var backgroundOverlayView: UIView!
    @IBOutlet weak var optionsContainerView: UIView!
    @IBOutlet weak var optionsContainerOffsetConstraint: NSLayoutConstraint!
    var tapGestureRecognizer:UITapGestureRecognizer!
    @IBOutlet var view: UIView!
    weak var delegate: DetailMoreOptionsViewDelegate?
    @IBOutlet weak var spamButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var unsendButton: UIButton!
    @IBOutlet var optionButtons: [UIButton]?
    @IBOutlet var printButton: UIButton!
    @IBOutlet weak var retryButton: UIButton!
    @IBOutlet var showSourceButton: UIButton!
    @IBOutlet weak var optionsHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var sourceTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var unsendTopMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var retryTopMarginConstraint: NSLayoutConstraint!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "DetailMoreOptionsUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        view.backgroundColor = .clear
        
        isHidden = true
        optionsContainerView.isHidden = false
        backgroundOverlayView.isHidden = true
        backgroundOverlayView.alpha = 0.0
        optionsContainerOffsetConstraint.constant = -300.0
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onDismiss))
        backgroundOverlayView.addGestureRecognizer(self.tapGestureRecognizer)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        applyTheme()
    }
    
    func showRetry(_ show: Bool){
        optionsHeightConstraint.constant = OPTIONS_HEIGHT_DEFAULT
        retryTopMarginConstraint.constant = TOP_DEFAULT
        self.view.layoutIfNeeded()
        self.retryButton.isHidden = !show
    }
    
    func showUnsend(_ show: Bool){
        optionsHeightConstraint.constant = OPTIONS_HEIGHT_DEFAULT
        unsendTopMarginConstraint.constant = TOP_DEFAULT
        self.unsendButton.isHidden = !show
    }
    
    func showSourceButton(_ show: Bool){
        optionsHeightConstraint.constant = OPTIONS_HEIGHT_DEFAULT
        sourceTopMarginConstraint.constant = TOP_DEFAULT
        self.showSourceButton.isHidden = !show
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        optionsContainerView.backgroundColor = theme.background
        if let optionButtons = optionButtons {
            for optionButton in optionButtons {
                optionButton.setTitleColor(theme.mainText, for: .normal)
            }
        }
    }
    
    func showMoreOptions(){
        guard isHidden else {
            return
        }
        self.isHidden = false
        self.optionsContainerView.isHidden = false
        self.backgroundOverlayView.isHidden = false
        if(unsendButton.isHidden && showSourceButton.isHidden && retryButton.isHidden){
            optionsHeightConstraint.constant = 290
        }
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseIn, animations: {
            self.optionsContainerOffsetConstraint.constant = 0.0
            self.backgroundOverlayView.alpha = 1.0
            self.view.layoutIfNeeded()
        })
    }
    
    func closeMoreOptions(){
        guard !isHidden else {
            return
        }
        UIView.animate(withDuration: 0.25, delay: 0.0, options: .curveEaseOut, animations: {
            self.optionsContainerOffsetConstraint.constant = -300.0
            self.backgroundOverlayView.alpha = 0.0
            self.view.layoutIfNeeded()
        }, completion: {
            finished in
            self.optionsContainerView.isHidden = true
            self.backgroundOverlayView.isHidden = true
            self.isHidden = true
        })
    }
    
    @objc func onDismiss(){
        delegate?.onOverlayPress()
    }
    
    @IBAction func onReplyPress(_ sender: Any) {
        delegate?.onReplyPress()
    }
    
    @IBAction func onReplyAllPress(_ sender: Any) {
        delegate?.onReplyAllPress()
    }
    
    @IBAction func onForwardPress(_ sender: Any) {
        delegate?.onForwardPress()
    }
    
    @IBAction func onDeletePress(_ sender: Any) {
        delegate?.onDeletePress()
    }
    
    @IBAction func onMarkPress(_ sender: Any) {
        delegate?.onMarkPress()
    }
    
    @IBAction func onSpamPress(_ sender: Any) {
        delegate?.onSpamPress()
    }
    
    @IBAction func onUnsendPress(_ sender: Any) {
        delegate?.onUnsendPress()
    }
    
    @IBAction func onPrintPress(_ sender: Any) {
        delegate?.onPrintPress()
    }
    
    @IBAction func onRetrySendPress(_ sender: Any) {
        delegate?.onRetryPress()
    }
    
    @IBAction func onShourSorucePress(_ sender: Any) {
        delegate?.onShowSourcePress()
    }
}
