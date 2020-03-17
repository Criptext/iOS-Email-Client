//
//  AliasViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 3/6/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Material
import Foundation

class RegisterDomainStepThreeViewController: UIViewController {
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var percentageContainerView: TipUIView!
    @IBOutlet weak var percentageLabel: CounterLabelUIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var loader: UIActivityIndicatorView!
    var myAccount: Account!
    var newDomain: CustomDomain!
    var scheduleWorker = ScheduleWorker(interval: 30.0, maxRetries: 6)
    var isValidating = false
    var hasFailed = false
    var lastValidationError = 0
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("CUSTOM_DOMAIN").capitalized
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        self.applyTheme()
        scheduleWorker.delegate = self
        nextButton.isEnabled = false
    }
    
    func applyTheme() {
        let attributedTitle = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        self.view.backgroundColor = theme.overallBackground
    }
    
    @objc func goBack(){
        if(!isValidating) {
            scheduleWorker.cancel()
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        showLoader(true)
        if(hasFailed){
            goBack()
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let customDomainVC = storyboard.instantiateViewController(withIdentifier: "customDomainViewController") as! CustomDomainViewController
            customDomainVC.myAccount = myAccount
            
            self.navigationController?.pushViewController(customDomainVC, animated: true)
        }
    }
    
    func validationSuccess(){
        nextButton.isEnabled = true
        nextButton.setTitle(String.localize("DONE"), for: .normal)
        isValidating = false
        animateProgress(Double(100), 3.0, completion: {})
    }
    
    func validationError(errorCode: Int){
        isValidating = false
        hasFailed = true
        animateProgress(Double(10), 3.0, completion: {})
        percentageLabel.isHidden = true
        nextButton.isEnabled = true
        messageLabel.isHidden = true
        switch(errorCode){
        case 400:
            titleLabel.text = String.localize("MX_DONT_MATCH_TITLE")
            errorLabel.text = String.localize("MX_DONT_MATCH_MESSAGE")
            break
        case 513:
            titleLabel.text = String.localize("DNS_NOT_FOUND_TITLE")
            errorLabel.text = String.localize("DNS_NOT_FOUND_MESSAGE")
            break
        default:
            titleLabel.text = String.localize("CUSTOM_DOMAIN_SOMETHING_WRONG_TITLE")
            errorLabel.text = String.localize("CUSTOM_DOMAIN_SOMETHING_WRONG_MESSAGE")
            break
        }
    }
    
    func showLoader(_ show: Bool){
        guard show else {
            loader.isHidden = true
            loader.stopAnimating()
            nextButton.isEnabled = true
            nextButton.setTitle(String.localize("NEXT"), for: .normal)
            return
        }
        
        loader.isHidden = false
        loader.startAnimating()
        nextButton.isEnabled = false
        nextButton.setTitle("", for: .normal)
    }
    
    func animateProgress(_ value: Double, _ duration: Double, completion: @escaping () -> Void){
        self.percentageLabel.setValue(value, interval: duration)
        UIView.animate(withDuration: duration, delay: 0.0, options: .curveLinear, animations: {
            self.progressBar.setProgress(Float(value/100), animated: true)
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + duration){
            completion()
        }
    }
}

extension RegisterDomainStepThreeViewController: ScheduleWorkerDelegate {
    func work(completion: @escaping (Bool) -> Void) {
        APIManager.validateMXCustomDomain(customDomainName: newDomain.name, token: myAccount.jwt) { (responseData) in
            if case .BadRequest = responseData {
                completion(false)
                self.animateProgress(Double(self.progressBar.progress) + Double(10), 3.0, completion: {})
                self.lastValidationError = 400
                return
            }
            if case .ServerError = responseData {
                completion(false)
                self.animateProgress(Double(self.progressBar.progress) + Double(10), 3.0, completion: {})
                self.lastValidationError = 513
                return
            }
            guard case .Success = responseData else {
                self.animateProgress(Double(self.progressBar.progress) + Double(10), 3.0, completion: {})
                completion(false)
                return
            }
            completion(true)
            DBManager.update(customDomain: self.newDomain, validated: true)
            self.validationSuccess()
        }
    }
    
    func dangled(){
        self.validationError(errorCode: self.lastValidationError)
    }
}

extension RegisterDomainStepThreeViewController: CustomTabsChildController {
    func reloadView() {
        self.applyTheme()
    }
}

extension RegisterDomainStepThreeViewController: UIGestureRecognizerDelegate {
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
