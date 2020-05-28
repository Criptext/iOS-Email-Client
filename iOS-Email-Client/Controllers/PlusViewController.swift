//
//  PlusViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 5/22/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class PlusViewController: UIViewController {
    @IBOutlet weak var upgradePlusView: UpgradePlusUIView!
    @IBOutlet weak var alreadyPlusView: AlreadyPlusUIView!
    
    weak var myAccount: Account!
    
    var isPlus: Bool {
        return Constants.isPlus(customerType: myAccount.customerType)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        myAccount = DBManager.getActiveAccount()!
        
        navigationItem.title = isPlus ? String.localize("BILLING") : String.localize("JOIN_PLUS")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        
        if isPlus {
            upgradePlusView.isHidden = true
            alreadyPlusView.applyTheme()
            alreadyPlusView.applyLocalization()
        } else {
            alreadyPlusView.isHidden = true
            upgradePlusView.applyTheme()
            upgradePlusView.applyLocalization()
            UIUtils.setProfilePictureImage(imageView: upgradePlusView.avatarImage, contact: (myAccount.email, myAccount.name))
        }
        
        let theme = ThemeManager.shared.theme
        self.view.backgroundColor = theme.background
    }
}

extension PlusViewController: UIGestureRecognizerDelegate {
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let nav = self.navigationController else {
            return false
        }
        if(nav.viewControllers.count > 1){
            return true
        }
        return false
    }
}
