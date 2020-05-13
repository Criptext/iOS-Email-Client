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
    var myAccount: Account!
    var newDomain: CustomDomain!
    var scheduleWorker = ScheduleWorker(interval: 15.0, maxRetries: 12)
    var isValidating = false
    var hasFailed = false
    var currentProgress = 0
    var lastValidationError = 0
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("CUSTOM_DOMAIN").capitalized
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(goBack))
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        self.applyTheme()
        progressBar.layer.cornerRadius = 5
        progressBar.layer.sublayers![1].cornerRadius = 5
        progressBar.subviews[1].clipsToBounds = true
        scheduleWorker.delegate = self
        scheduleWorker.start()
        nextButton.isHidden = true
        percentageContainerView.isHidden = false
        messageLabel.isHidden = false
        errorLabel.isHidden = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.currentProgress += 5
            self.animateProgress(Double(self.currentProgress), 3.0, completion: {})
        }
    }
    
    func applyLocalization() {
        nextButton.setTitle(String.localize("BACK"), for: .normal)
        titleLabel.text = String.localize("VERIFY_DOMAIN")
        errorLabel.text = String.localize("VERIFY_DOMAIN_ERROR", arguments: "@\(newDomain.name)")
        messageLabel.text = String.localize("VERIFY_DOMAIN_MESSAGE")
    }
    
    func applyTheme() {
        let attributedTitle = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("CUSTOM_DOMAIN").capitalized, attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        self.view.backgroundColor = theme.overallBackground
        
        titleLabel.textColor = theme.markedText
        errorLabel.textColor = theme.mainText
        messageLabel.textColor = theme.mainText
        percentageLabel.textColor = theme.overallBackground
        percentageLabel.backgroundColor = theme.mainText
        percentageContainerView.backgroundColor = .clear
        percentageContainerView.tipColor = theme.mainText
        percentageContainerView.layoutIfNeeded()
    }
    
    @objc func goBack(){
        if(!isValidating) {
            scheduleWorker.cancel()
            navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        if(hasFailed){
            goBack()
        } else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let customDomainVC = storyboard.instantiateViewController(withIdentifier: "customDomainViewController") as! CustomDomainViewController
            customDomainVC.myAccount = myAccount
            customDomainVC.domains = [newDomain]
            guard let navController = self.navigationController else {
                return;
            }
            navController.popToRootViewController(animated: false)
            navController.pushViewController(customDomainVC, animated: true)
        }
    }
    
    func validationSuccess(){
        nextButton.isHidden = false
        nextButton.setTitle(String.localize("DONE"), for: .normal)
        isValidating = false
        animateProgress(Double(100), 3.0, completion: {
            self.progressBar.progressTintColor = .success
            self.titleLabel.text = String.localize("CUSTOM_DOMAIN_VERIFICATION_SUCCESS")
            self.messageLabel.text = ""
            self.errorLabel.text = ""
        })
    }
    
    func validationError(errorCode: Int){
        isValidating = false
        hasFailed = true
        progressBar.progressTintColor = theme.alert
        animateProgress(Double(10), 3.0, completion: {})
        nextButton.isHidden = false
        percentageContainerView.isHidden = true
        messageLabel.isHidden = true
        errorLabel.isHidden = false
        switch(errorCode){
        case 400:
            titleLabel.text = String.localize("MX_DONT_MATCH_TITLE")
            errorLabel.text = String.localize("MX_DONT_MATCH_MESSAGE")
            break
        case 513:
            titleLabel.text = String.localize("DNS_NOT_FOUND_TITLE")
            errorLabel.text = String.localize("DNS_NOT_FOUND_MESSAGE", arguments: "@\(newDomain.name)")
            break
        default:
            titleLabel.text = String.localize("CUSTOM_DOMAIN_SOMETHING_WRONG_TITLE")
            errorLabel.text = String.localize("CUSTOM_DOMAIN_SOMETHING_WRONG_MESSAGE")
            break
        }
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
            self.currentProgress += 5
            if case .BadRequest = responseData {
                completion(false)
                self.animateProgress(Double(self.currentProgress), 3.0, completion: {})
                self.lastValidationError = 400
                return
            }
            if case .ServerError = responseData {
                completion(false)
                self.animateProgress(Double(self.currentProgress), 3.0, completion: {})
                self.lastValidationError = 513
                return
            }
            guard case .Success = responseData else {
                self.animateProgress(Double(self.currentProgress), 3.0, completion: {})
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

extension RegisterDomainStepThreeViewController {
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
