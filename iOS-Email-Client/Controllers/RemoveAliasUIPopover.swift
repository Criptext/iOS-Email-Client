//
//  RemoveAliasUIPopover.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/9/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class RemoveAliasUIPopover: BaseUIPopover {
    
    var alias: Alias!
    var myAccount: Account!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var continueTitleLabel: UILabel!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    var onSuccess: ((String, Int) -> Void)?
    
    init(){
        super.init("RemoveAliasUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showLoader(false)
        applyTheme()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func applyTheme() {
        let theme: Theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barTintColor = theme.toolbar
        view.backgroundColor = theme.background
        titleLabel.textColor = theme.mainText
        subTitleLabel.textColor = theme.mainText
        continueTitleLabel.textColor = theme.mainText
        confirmButton.backgroundColor = theme.popoverButton
        cancelButton.backgroundColor = theme.popoverButton
        confirmButton.setTitleColor(theme.mainText, for: .normal)
        cancelButton.setTitleColor(theme.mainText, for: .normal)
        loader.color = theme.loader
    }
    
    @IBAction func onCancelPress(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func onConfirmPress(_ sender: Any) {
        let aliasId = alias.rowId
        let domainName = alias.domainName!
        showLoader(true)
        APIManager.deleteAlias(rowId: aliasId, token: myAccount.jwt) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout(account: self.myAccount)
                return
            }
            guard case .Success = responseData else {
                self.showLoader(false)
                return
            }
            self.onSuccess?(domainName, aliasId)
            self.dismiss(animated: true)
        }
    }
    
    func showLoader(_ show: Bool){
        self.shouldDismiss = !show
        confirmButton.isEnabled = !show
        cancelButton.isEnabled = !show
        cancelButton.setTitle(show ? "" : String.localize("CANCEL"), for: .normal)
        confirmButton.setTitle(show ? "" : String.localize("CONFIRM"), for: .normal)
        loader.isHidden = !show
        guard show else {
            loader.stopAnimating()
            return
        }
        loader.startAnimating()
    }
    
}
