//
//  SignInVerificationUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Iñiguez on 10/11/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class SignInVerificationUIPopover: BaseUIPopover {
    
    @IBOutlet weak var deviceLabel: UILabel!
    @IBOutlet weak var accounLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var approveButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var deviceImageView: UIImageView!
    
    var deviceType: Device.Kind = .pc
    var linkData: LinkData!
    var emailText: String = ""
    var deviceImage: UIImage {
        switch(deviceType){
        case .pc:
            return UIImage(named: "device-desktop")!.resize(toHeight: 26.0)!.tint(with: UIColor(red: 186/255, green: 189/255, blue: 196/255, alpha: 1.0))!.resizableImage(withCapInsets: UIEdgeInsets(top: 13, left: 0, bottom: 0, right: 5))
        default:
            return UIImage(named: "device-mobile")!.resize(toHeight: 26.0)!.tint(with: UIColor(red: 186/255, green: 189/255, blue: 196/255, alpha: 1.0))!.resizableImage(withCapInsets: UIEdgeInsets(top: 13, left: 0, bottom: 0, right: 5))
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
        
        deviceLabel.text = linkData.deviceName;
        accounLabel.text = emailText
        titleLabel.text = linkData.kind == .link ? String.localize("SYNC_LINK") : String.localize("SYNC_MAIL")
        deviceImageView.image = deviceImage
        applyTheme()
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        titleLabel.textColor = theme.mainText
        subTitleLabel.textColor = theme.mainText
        deviceLabel.textColor = theme.secondText
        accounLabel.textColor = theme.secondText
        approveButton.backgroundColor = theme.popoverButton
        rejectButton.backgroundColor = theme.popoverButton
        rejectButton.setTitleColor(theme.mainText, for: .normal)
        approveButton.setTitleColor(theme.mainText, for: .normal)
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
