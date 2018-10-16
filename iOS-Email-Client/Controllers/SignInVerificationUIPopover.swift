//
//  SignInVerificationUIPopover.swift
//  iOS-Email-Client
//
//  Created by Allisson on 10/11/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SignInVerificationUIPopover: BaseUIPopover {
    
    @IBOutlet weak var deviceLabel: UILabel!
    var deviceName: String = ""
    var deviceType: Device.Kind = .pc
    var deviceImage: UIImage {
        switch(deviceType){
        case .pc:
            return UIImage(named: "device-desktop")!.resize(toHeight: 26.0)!.tint(with: UIColor(red: 186/255, green: 189/255, blue: 196/255, alpha: 1.0))!.resizableImage(withCapInsets: UIEdgeInsetsMake(13, 0, 0, 5))
        default:
            return UIImage(named: "device-mobile")!.resize(toHeight: 26.0)!.tint(with: UIColor(red: 186/255, green: 189/255, blue: 196/255, alpha: 1.0))!.resizableImage(withCapInsets: UIEdgeInsetsMake(13, 0, 0, 5))
        }
    }
    var onResponse: ((Bool) -> Void)?
    
    init(){
        super.init("SignInVerificationUIPopover")
        self.shouldDismiss = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let attachment = NSTextAttachment();
        attachment.image = deviceImage
        attachment.bounds = CGRect(x: 0.0, y: deviceLabel.font.descender - 2.0, width: attachment.image!.size.width, height: attachment.image!.size.height)
        
        let attachmentString = NSMutableAttributedString(attachment: attachment)
        let myString = NSAttributedString(string: "   \(deviceName)")
        attachmentString.append(myString)
        deviceLabel.attributedText = attachmentString;
    }
    
    @IBAction func onOkPress(_ sender: Any) {
        self.dismiss(animated: true) {
            self.onResponse?(true)
        }
    }
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true) {
            self.onResponse?(false)
        }
    }
    
}
