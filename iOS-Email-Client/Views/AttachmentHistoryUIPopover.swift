//
//  AttachmentHistoryUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/8/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class HistoryUIPopover: UIViewController, UIPopoverPresentationControllerDelegate{
    @IBOutlet weak var attachmentsTableView: UITableView!
    var overlay: UIView?
    
    init(){
        super.init(nibName: "AttachmentHistoryUIPopover", bundle: nil)
        self.modalPresentationStyle = UIModalPresentationStyle.popover;
        self.popoverPresentationController?.delegate = self;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        guard let overlay = overlay else {
            return
        }
        DispatchQueue.main.async() {
            UIView.animate(withDuration: 0.1, animations: {
                overlay.alpha = 0.0
            }, completion: { _ in
                overlay.removeFromSuperview()
            })
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle{
        return .none
    }
    
    override func viewDidLoad() {
        attachmentsTableView.register(UINib(nibName: "AttachmentHistoryTableCell", bundle: nil), forCellReuseIdentifier: "attachHistoryCell")
    }
    
    dynamic func presentationController(_ presentationController: UIPresentationController, willPresentWithAdaptiveStyle style: UIModalPresentationStyle, transitionCoordinator: UIViewControllerTransitionCoordinator?) {
        
        let parentView = presentationController.presentingViewController.view
        
        let overlay = UIView(frame: (parentView?.bounds)!)
        overlay.backgroundColor = UIColor(white: 0.0, alpha: 0.3)
        parentView?.addSubview(overlay)
        
        let views: [String: UIView] = ["parentView": parentView!, "overlay": overlay]
        
        parentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[overlay]|", options: [], metrics: nil, views: views))
        parentView?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[overlay]|", options: [], metrics: nil, views: views))
        
        overlay.alpha = 0.0
        
        transitionCoordinator?.animate(alongsideTransition: { _ in
            overlay.alpha = 1.0
        }, completion: nil)
        
        self.overlay = overlay
    }
}

extension HistoryUIPopover: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "attachHistoryCell", for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81.0
    }
}
