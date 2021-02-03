//
//  SignUpTermsAndConditionsViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/21/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material
import SignalProtocolFramework
import FirebaseMessaging
import WebKit

class SignUpTermsAndConditionsViewController: UIViewController{
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var checkBoxTerms: CheckMarkUIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var conditionOne: UIButton!
    @IBOutlet weak var loadingView: SwingingLoaderUIView!
    @IBOutlet weak var loadingOverlayView: UIView!
    @IBOutlet weak var captchaTextField: StatusTextField!
    @IBOutlet weak var captchaContainerView: UIView!
    @IBOutlet weak var captchaWebView: WKWebView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var creatingLabel: UILabel!

    var signUpData: TempSignUpData!
    var multipleAccount = false
    let signUpValidator = ValidateString.signUp
    var fromSignup = false
    
    var account: Account?
    var bundle: CRBundle?
    var captchaKey: String?
    var state : CreationState = .checkDB
    var signUpFinalData: SignUpData?
    
    enum CreationState{
        case checkDB
        case signupRequest
        case accountCreate
    }
    
    func handleState(){
        switch(state){
        case .checkDB:
            checkDatabase()
        case .signupRequest:
            sendSignUpRequest()
        case .accountCreate:
            updateAccount()
        }
    }
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyTheme()
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        checkBoxTerms.addGestureRecognizer(tap)
    
        setupField()
        
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        toggleLoadingView(false)
        onRefreshPress(self)
        captchaWebView.scrollView.bouncesZoom = false
        captchaWebView.scrollView.isScrollEnabled = false
        captchaContainerView.layer.borderWidth = 1
        captchaContainerView.layer.borderColor = UIColor(red: 212/255, green: 218/255, blue: 227/255, alpha: 1).cgColor
    }
    
    func applyTheme() {
        titleLabel.textColor = theme.mainText
        descriptionLabel.textColor = theme.secondText
        view.backgroundColor = theme.overallBackground
        
        captchaTextField.tintColor = theme.mainText
        captchaTextField.textColor = theme.mainText
        captchaTextField.validDividerColor = theme.criptextBlue
        captchaTextField.invalidDividerColor = UIColor.red
        captchaTextField.dividerColor = theme.criptextBlue
        captchaTextField.detailColor = UIColor.red
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.setNeedsDisplay()
    }
    
    func checkDatabase(){
        self.state = .signupRequest
        let accountId = self.signUpFinalData!.domain == Env.plainDomain ? signUpFinalData!.username : "\(signUpFinalData!.username)@\(signUpFinalData!.domain)"
        if DBManager.getLoggedOutAccount(accountId: accountId) == nil {
            let loggedOutAccounts = DBManager.getLoggedOutAccounts()
            for account in loggedOutAccounts {
                FileUtils.deleteAccountDirectory(account: account)
                DBManager.signout(account: account)
                DBManager.clearMailbox(account: account)
                DBManager.delete(account: account)
            }
        }
        self.handleState()
    }
    
    func removeQuickGuideFlags(){
        let defaults = CriptextDefaults()
        defaults.removeQuickGuideFlags()
    }
    
    func createAccount() -> (Account, [String: Any]) {
        if let myKeys = self.bundle?.publicKeys,
            let myAccount = self.account {
            return(myAccount, myKeys)
        }
        let account = SignUpData.createAccount(from: self.signUpFinalData!)
        DBManager.store(account)
        if let myAddresses = signUpFinalData!.addresses {
            parseAddresses(addresses: myAddresses, account: account)
        }
        let bundle = CRBundle(account: account)
        let keys = bundle.generateKeys()
        self.account = account
        self.bundle = bundle
        return (account, keys)
    }
    
    func parseAddresses(addresses: [[String: Any]], account: Account) {
        let (aliasesPairArray) = addresses.map({aliasesDomainFromDictionary(data: $0, account: account)})
        for pair in aliasesPairArray {
            if pair.0.name != Env.plainDomain {
                DBManager.store(pair.0)
            }
            DBManager.store(aliases: pair.1)
            if let defaultAddressId = pair.2 {
                DBManager.update(account: account, defaultAddressId: defaultAddressId)
            }
        }
    }
    
    func aliasesDomainFromDictionary(data: [String: Any], account: Account) -> (CustomDomain, [Alias], Int?) {
        let aliases = data["aliases"] as! [[String: Any]]
        let domainData = data["domain"] as! [String: Any]
        let domainName = domainData["name"] as! String
        let domainVerified = domainData["confirmed"] as! Int
        
        let domain = CustomDomain()
        domain.name = domainName
        domain.validated = domainVerified == 1 ? true : false
        domain.account = account
        
        var defaultAddressId: Int? = nil
        let aliasesArray: [Alias] = aliases.map { aliasObj in
            let alias = Alias.aliasFromDictionary(aliasData: aliasObj, domainName: domainName, account: account)
            if let isDefault = aliasObj["default"] as? Int,
                isDefault == 1 {
                defaultAddressId = alias.rowId
            }
            return alias
        }
        
        return (domain, aliasesArray, defaultAddressId)
    }
    
    func sendSignUpRequest(){
        self.captchaTextField.resignFirstResponder()
        let accountData = createAccount()
        let signupRequestData = self.signUpFinalData!.buildDataForRequest(publicKeys: accountData.1, captchaKey: self.captchaKey!, captcha: self.captchaTextField.text ?? "")
        APIManager.signUpRequest(signupRequestData) { [weak self] (responseData) in
            self?.handleSignUpResponse(responseData: responseData)
        }
    }
    
    func handleSignUpResponse(responseData: ResponseData) {
        var dismissOverlay = true
        switch(responseData) {
            case .TooManyRequests(let waitingTime):
                if waitingTime < 0 {
                    self.displayErrorMessage(message: String.localize("TOO_MANY_SIGNIN_ATTEMPTS"))
                } else {
                    self.displayErrorMessage(message: String.localize("ATTEMPTS_TIME_LEFT", arguments: Time.remaining(seconds: waitingTime)))
                }
            case .Error(let error):
                if error.code != .custom {
                    self.displayErrorMessage(message: error.description)
                }
            case .SuccessDictionary(let tokens):
                guard let sessionToken = tokens["token"] as? String,
                    let refreshToken = tokens["refreshToken"] as? String else {
                    self.displayErrorMessage()
                    break
                }
                self.signUpFinalData!.token = sessionToken
                self.signUpFinalData!.refreshToken = refreshToken
                self.state = .accountCreate
                self.handleState()
                dismissOverlay = false
            case .Conflict:
                self.displayErrorMessage(message: String.localize("WRONG_CAPTCHA"))
                self.captchaTextField.setStatus(.invalid, String.localize("WRONG_CAPTCHA"))
            case .ConflictsInt(let errorCode):
                self.handleSignUpErrorCode(error: errorCode)
            case .ConflictsData(let errorCode, let data):
                self.handleSignUpErrorCode(error: errorCode, limit: data["max"] as? Int ?? 0)
            default:
                self.displayErrorMessage()
        }
        if dismissOverlay {
            toggleLoadingView(false)
        }
    }
    
    func handleSignUpErrorCode(error: Int, limit: Int = 0) {
        var message = ""
        switch(error) {
        case 1:
            message = String.localize("RECOVERY_EMAIL_UNVERIFIED")
        case 2:
            message = String.localize("RECOVERY_EMAIL_USED", arguments: limit)
        case 3:
            message = String.localize("RECOVERY_EMAIL_BLOCKED")
        case 4:
            message = String.localize("RECOVERY_EMAIL_SAME")
        default:
            self.displayErrorMessage()
            return
        }
        self.LoadingStop()
        self.displayErrorMessage(message: message)
    }
    
    func updateAccount(){
        DBManager.createSystemLabels()
        guard let myAccount = self.account,
            let myBundle = self.bundle,
            !self.signUpFinalData!.token.isEmpty,
            let refreshToken = self.signUpFinalData!.refreshToken,
            let identityB64 = myBundle.store.identityKeyStore.getIdentityKeyPairB64() else {
            return
        }
        let regId = myBundle.store.identityKeyStore.getRegId()
        DBManager.update(account: myAccount, jwt: self.signUpFinalData!.token, refreshToken: refreshToken, regId: regId, identityB64: identityB64)
        let myContact = Contact()
        myContact.displayName = myAccount.name
        myContact.email = "\(myAccount.username)\(Env.domain)"
        DBManager.store([myContact], account: myAccount)
        let defaults = CriptextDefaults()
        if self.signUpFinalData!.deviceId != 1 {
            defaults.welcomeTour = true
        }
        defaults.setShowYay(recipientId: myAccount.username)
        registerFirebaseToken(jwt: myAccount.jwt)
        let hasEmails = self.fromSignup ? true : DBManager.hasEmails(account: myAccount)
        self.goToCustomize(myAccount, showRestore: !hasEmails)
    }
    
    func goToCustomize(_ activeAccount: Account, showRestore: Bool){
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "customizeAccountCreatedView")  as! CustomizeAccountCreatedViewController
        controller.myAccount = activeAccount
        controller.recoveryEmail = self.signUpData!.optionalEmail!
        controller.multipleAccount = self.multipleAccount
        navigationController?.pushViewController(controller, animated: true)
        toggleLoadingView(false)
    }
    
    func displayErrorMessage(message: String = String.localize("SIGNUP_FALLBACK_ERROR")){
        let popup = GenericAlertUIPopover()
        popup.myTitle = String.localize("WARNING")
        popup.myMessage = message
        self.presentPopover(popover: popup, height: 220)
    }
    
    func registerFirebaseToken(jwt: String){
        guard let fcmToken = Messaging.messaging().fcmToken else {
            return
        }
        APIManager.registerToken(fcmToken: fcmToken, token: jwt)
    }
    
    func setConditionState(isCorrect: Bool?, text: String, conditionLabel: UILabel){
        var attributedMark: NSMutableAttributedString
        let theme = ThemeManager.shared.theme
        guard let correct = isCorrect else {
            conditionLabel.textColor = theme.secondText
            conditionLabel.text = text
            return
        }
        if(correct){
            attributedMark = NSMutableAttributedString(string: "✓ ", attributes: [.font: Font.regular.size(14)!])
            conditionLabel.textColor = .green
        } else {
            attributedMark = NSMutableAttributedString(string: "x ", attributes: [.font: Font.regular.size(14)!])
            conditionLabel.textColor = .red
        }
        let attributedText = NSAttributedString(string: text, attributes: [.font: Font.regular.size(14)!])
        attributedMark.append(attributedText)
        conditionLabel.attributedText = attributedMark
    }
    
    func setupField(){
        let boldText  = String.localize("TERMS_CONDITIONS")
        let attrs = [NSAttributedString.Key.font : UIFont.init(name: "NunitoSans-Bold", size: 18), NSAttributedString.Key.foregroundColor : theme.criptextBlue]
        let attributedString = NSMutableAttributedString(string:boldText, attributes:attrs as [NSAttributedString.Key : Any])
        
        let normalText = String.localize("ACCEPT_TERMS")
        let normalAttrs = [NSAttributedString.Key.font : UIFont.init(name: "NunitoSans-Regular", size: 18), NSAttributedString.Key.foregroundColor : theme.secondText]
        let normalString = NSMutableAttributedString(string:normalText, attributes: normalAttrs as [NSAttributedString.Key : Any])
        
        normalString.append(attributedString)
        
        conditionOne.setAttributedTitle(normalString, for: .normal)
        
        checkBoxTerms.setChecked(false)
        
        let placeholderAttrs = [.foregroundColor: theme.secondText] as [NSAttributedString.Key: Any]
        
        captchaTextField.font = Font.regular.size(17.0)
        captchaTextField.rightViewMode = .always
        captchaTextField.placeholderAnimation = .hidden
        captchaTextField.attributedPlaceholder = NSAttributedString(string: String.localize("CAPTCH_PLACEHOLDER"), attributes: placeholderAttrs)
        
        titleLabel.text = String.localize("SIGN_UP_TERMS_TITLE")
        nextButton.setTitle(String.localize("SIGN_UP_CREATE_ACCOUNT_BTN"), for: .normal)
        descriptionLabel.text = String.localize("SIGN_UP_NOT_ROBOT")
        creatingLabel.text = String.localize("SIGN_UP_CREATING_ACCOUNT_BTN")

    }
    
    @objc func handleTap(_ gestureRecognizer:UITapGestureRecognizer){
        guard let data = signUpData else {
            return
        }
        data.termsAccepted = !data.termsAccepted
        checkBoxTerms.setChecked(data.termsAccepted)
        self.checkToEnableDisableNextButton()
    }
    
    @objc func onDonePress(_ sender: Any){
        guard nextButton.isEnabled else {
            return
        }
        self.onNextPress(sender)
    }
    
    func toggleLoadingView(_ show: Bool){
        if(show){
            loadingOverlayView.isHidden = false
            loadingView.startAnimating()
        }else{
            loadingOverlayView.isHidden = true
            loadingView.stopAnimating()
        }
        checkToEnableDisableNextButton()
    }
    
    @IBAction func onNextPress(_ sender: Any) {
        toggleLoadingView(true)
        self.signUpFinalData = SignUpData(username: self.signUpData!.username!, password: self.signUpData!.password!, domain: Env.domain.replacingOccurrences(of: "@", with: ""),  fullname: self.signUpData!.fullname!, optionalEmail: self.signUpData!.optionalEmail)
        sendSignUpRequest()
    }
    
    @IBAction func onRefreshPress(_ sender: Any) {
        APIManager.getCaptcha { (responseData) in
            guard case let .SuccessDictionary(body) = responseData,
                  let image = body["image"] as? String,
                  let captchaKey = body["captchaKey"] as? String else {
                self.captchaTextField.setStatus(.invalid, String.localize("CAPTCH_ERROR"))
                return
            }
            self.captchaTextField.setStatus(.none)
            self.captchaKey = captchaKey
            let html = """
                <html>
                    <head>
                        <meta name=\"viewport\" content="width=device-width, initial-scale=1.0">
                        <style>
                            body {
                                width: 100%;
                                height: 100%;
                                margin: 0px;
                                padding: 0px;
                            }
                            .captcha-svg {
                                flex-grow: 1;
                                display: flex;
                                justify-content: center;
                                align-items: center;
                                background-color: white;
                                width= 100%;
                                height= 100%;
                            }
                            svg {
                                witdh: 100%;
                            }
                        </style>
                    </head>
                    <body>
                        <div class="captcha-svg">
                            \(image)
                        </div>
                    </body>
                </html>
            """
            self.captchaWebView.loadHTMLString(html, baseURL: nil)
            self.checkToEnableDisableNextButton()
        }
    }
    
    @IBAction func didPressTermsAndConditions(sender: Any) {
        goToUrl(url: "https://criptext.com/\(Env.language)/terms")
    }
    
    @IBAction func didPressClose(sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func checkToEnableDisableNextButton(){
        nextButton.isEnabled = signUpData.termsAccepted && captchaKey != nil
        if(nextButton.isEnabled){
            nextButton.alpha = 1.0
        }else{
            nextButton.alpha = 0.5
        }
    }
}

extension SignUpTermsAndConditionsViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
}

extension SignUpTermsAndConditionsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}
