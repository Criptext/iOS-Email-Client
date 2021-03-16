//
//  HeaderBarUIView.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 1/27/21.
//  Copyright © 2021 Criptext Inc. All rights reserved.
//

import Foundation

protocol HeaderBarToolbarDelegate: class {
    func onActivityPress()
    func onSearchPress()
    func onMenuPress()
    func onFilterPress()
}

protocol SearchBarToolbarDelegate: class {
    func onSearchChanged(text: String)
    func onSearchDismiss()
}

class HeaderBarUIView: UIView {
    let HORIZONTAL_CENTER : CGFloat = 0.0
    let MARK_LEFT_MARGIN : CGFloat = 17.0
    let ADJUST_MARGIN_FOR_LESS_ICONS : CGFloat = 31.0
    @IBOutlet var view: UIView!
    
    @IBOutlet weak var mailboxContainerView: UIView!
    @IBOutlet weak var mailboxLabel: UILabel!
    @IBOutlet weak var mailboxCountLabel: UILabel!
    @IBOutlet weak var avatarContainerView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var borderImageView: UIImageView!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var activityButton: UIButton!
    @IBOutlet weak var activityCountLabel: UILabel!
    @IBOutlet weak var activityCountView: UIView!
    @IBOutlet weak var avatarCheckView: UIView!
    weak var delegate: HeaderBarToolbarDelegate?
    
    @IBOutlet weak var searchContainerView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    weak var searchDelegate: SearchBarToolbarDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        UINib(nibName: "HeaderBarUIView", bundle: nil).instantiate(withOwner: self, options: nil)
        addSubview(view)
        view.frame = self.bounds
        
        avatarCheckView.layer.cornerRadius = 6
        avatarCheckView.layer.borderWidth = 2
        avatarCheckView.layer.borderColor = UIColor.charcoal.cgColor
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onMenuPress(_:)))
        avatarContainerView.addGestureRecognizer(tapGesture)
        
        searchTextField.text = ""
        searchTextField.textColor = .white
        searchTextField.attributedPlaceholder = NSAttributedString(string: String.localize("SEARCH"), attributes: [.foregroundColor: UIColor.gray, .font: Font.regular.size(16)!])
        
        searchTextField.addTarget(self, action: #selector(self.textFieldDidChange(sender:)), for: .editingChanged)
        
        searchContainerView.isHidden = true
        mailboxContainerView.isHidden = false
    }
    
    @objc func textFieldDidChange(sender: UITextField){
        searchDelegate?.onSearchChanged(text: sender.text ?? "")
    }
    
    @IBAction func onSearchPress(_ sender: Any) {
        mailboxContainerView.isHidden = true
        searchContainerView.isHidden = false
        
        searchTextField.becomeFirstResponder()
        delegate?.onSearchPress()
    }
    
    @IBAction func onActivityPress(_ sender: Any) {
        delegate?.onActivityPress()
    }
    
    @IBAction func onFilterPress(_ sender: Any) {
        delegate?.onFilterPress()
    }
    
    @objc func onMenuPress(_ sender: Any) {
        delegate?.onMenuPress()
    }
    
    func setAvatar(email: String, name: String) {
        UIUtils.setProfilePictureImage(imageView: avatarImageView, contact: (email, name))
        UIUtils.setAvatarBorderImage(imageView: borderImageView, contact: (email, name))
    }
    
    func setActivityCounter(count: Int) {
        guard count > 0 else {
            activityCountView.isHidden = true
            return
        }
        activityCountView.isHidden = false
        activityCountLabel.text = count.description
    }
    
    func setMailbox(label: String) {
        mailboxLabel.text = label + " "
    }
    
    func setCounter(count: String) {
        mailboxCountLabel.text = count
    }
    
    func showAccountAlert(_ show: Bool) {
        avatarCheckView.isHidden = !show
    }
    
    @IBAction func onBackPress(sender: Any) {
        mailboxContainerView.isHidden = false
        searchContainerView.isHidden = true
        
        searchDelegate?.onSearchDismiss()
        resignKeyboard()
    }
    
    func resignKeyboard() {
        searchTextField.resignFirstResponder()
    }
}
