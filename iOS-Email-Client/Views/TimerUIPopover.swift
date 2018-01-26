//
//  TimerUIPopover.swift
//  Criptext Secure Email
//
//  Created by Daniel Tigse on 4/12/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

class TimerUIPopover: UIViewController, UIPopoverPresentationControllerDelegate{
    
    @IBOutlet weak var labelDays: UILabel!
    @IBOutlet weak var labelHours: UILabel!
    @IBOutlet weak var labelMinutes: UILabel!
    
    var dateEnd: NSDate!
    var timer: Timer!
    var overlay: UIView?
    
    init() {
        super.init(nibName: "TimerUIPopover", bundle: nil)
        self.modalPresentationStyle = UIModalPresentationStyle.popover;
        self.popoverPresentationController?.delegate = self;
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle{
        return .none
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
    
    deinit {
        
        guard let overlay = overlay else {
            return
        }
        DispatchQueue.main.async() {
            UIView.animate(withDuration: 0.2, animations: {
                overlay.alpha = 0.0
            }, completion: { _ in
                overlay.removeFromSuperview()
            })
        }
    }
    
    override func viewDidLoad() {
        
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        timer.invalidate()
    }
    
    func updateTime(){
        
        //Get the time left until the specified date
        let ti = Int(dateEnd.timeIntervalSinceNow)
        let seconds = ti % 60;
        let minutes = (ti / 60) % 60;
        let hours = (ti / 3600) % 24;
        let days = (ti / 86400);
        
        if(seconds < 0){
            timer.invalidate()
            //TODO MOSTRAR QUE ESTA EXPIRADO
        }else{
            if(days>0){
                labelDays.text = String(format:"%02li",days)
            }
            else{
                labelDays.text = "0"
            }
            if(hours>0){
                labelHours.text = String(format:"%02li",hours)
            }
            else{
                labelHours.text = "0"
            }
            if(minutes>0){
                labelMinutes.text = String(format:"%02li",minutes)
            }
            else{
                labelMinutes.text = "0"
            }
        }
    }
}
