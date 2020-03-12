//
//  RemoveAliasUIPopover.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/9/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class AddAliasUIPopover: BaseUIPopover {
    
    var domains: [String]!
    var myAccount: Account!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!
    @IBOutlet weak var aliasTextInput: TextField!
    @IBOutlet weak var criptextDomainLabel: UILabel!
    @IBOutlet weak var domainPicker: UIPickerView!
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    var onSuccess: ((Alias) -> Void)?
    
    init(){
        super.init("AddAliasUIPopover")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showLoader(false)
        if(domains.count == 0 || (domains.count == 1 && domains.first == Env.domain)){
            domainPicker.isHidden = true
            criptextDomainLabel.isHidden = false
            criptextDomainLabel.text = Env.domain
        } else {
            domainPicker.isHidden = false
            criptextDomainLabel.isHidden = true
        }
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
        criptextDomainLabel.textColor = theme.mainText
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
        showLoader(true)
        let domainName = domains.count == 0 ? Env.plainDomain : domains.first!
        APIManager.createAlias(alias: aliasTextInput.text!, domain: domainName, token: myAccount.jwt){ (responseData) in
            if case .BadRequest = responseData {
                self.showLoader(false)
                return
            }
            guard case let .SuccessDictionary(data) = responseData,
                let rowId = data["addressId"] as? Int else {
                self.showLoader(false)
                return
            }
            let alias = Alias()
            alias.account = self.myAccount
            alias.active = true
            alias.name = self.aliasTextInput.text!
            alias.rowId = rowId
            alias.domainName = domainName == Env.domain ? nil : domainName
            self.onSuccess?(alias)
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
