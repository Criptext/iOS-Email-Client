//
//  YayUIPopover.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/24/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material
import SDWebImage

class YayUIPopover: BaseUIPopover {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var yayButton: UIButton!
    var onYayPressed: (() -> Void)?
    
    var myAccount: Account!
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    init(){
        super.init("YayUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupFields()
        UIUtils.deleteSDWebImageCache()
        setProfileImage()
        applyTheme()
    }
    
    func setProfileImage(){
        profilePicture.sd_setImage(with: URL(string: "\(Env.apiURL)/user/avatar/\(myAccount.domain ?? Env.plainDomain)/\(myAccount.username)"), placeholderImage: nil, options: [SDWebImageOptions.continueInBackground, SDWebImageOptions.lowPriority]) { (image, error, cacheType, url) in
            if error == nil {
                self.makeCircleImage()
            }
        }
    }
    
    func makeCircleImage(){
        profilePicture.contentMode = .scaleAspectFill
        profilePicture.layer.masksToBounds = false
        profilePicture.layer.cornerRadius = profilePicture.frame.size.width / 2
        profilePicture.clipsToBounds = true
    }
    
    func setupFields() {
        messageLabel.text = self.myAccount.email
        titleLabel.text = String.localize("YAY_POPOVER_TITLE")
    }
    
    func applyTheme() {
        titleLabel.textColor = theme.markedText
        messageLabel.textColor = theme.mainText
        view.backgroundColor = theme.background
        let attrSkip = NSAttributedString(string: String.localize("YAY_POPOVER_BTN"), attributes: [.font: Font.bold.size(16)!, .foregroundColor: theme.criptextBlue])
        yayButton.setAttributedTitle(attrSkip, for: .normal)
        yayButton.backgroundColor = theme.popoverButton
    }
    
    @IBAction func didPressYay(_ sender: Any) {
        self.onYayPressed?()
        self.dismiss(animated: true, completion: nil)
    }
}
