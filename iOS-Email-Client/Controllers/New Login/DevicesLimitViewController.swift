//
//  DevicesLimitViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Iniguez on 10/28/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation

class DevicesLimitViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var creatingAccountLoadingView: CreatingAccountLoadingUIView!


    var loginData: LoginParams!
    var devices = [Device]()
    var maxAllowedDevices = Env.maxAllowedDevices
    var tempToken: String?

    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        applyLocalization()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.applyTheme()
        self.loadDevices()
        
        creatingAccountLoadingView.display = false
    }
    
    func loadDevices() {
        APIManager.findDevices(username: loginData.username, domain: loginData.domain, password: loginData.password.sha256()!) { (responseData) in
            if case let .TooManyRequests(waitingTime) = responseData {
                if waitingTime < 0 {
                    self.showFeedback(String.localize("TOO_MANY_SIGNIN"))
                } else {
                    self.showFeedback(String.localize("ATTEMPTS_TIME_LEFT", arguments: Time.remaining(seconds: waitingTime)))
                }
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.showFeedback(error.description)
                return
            }
            guard case let .SuccessDictionary(data) = responseData,
                let devices = data["devices"] as? [[String: Any]],
                let token = data["token"] as? String else {
                    self.showFeedback(String.localize("WRONG_PASS_RETRY"))
                    return
            }
            
            self.tempToken = token
            let myDevices = devices.map({Device.fromDictionary(data: $0, isLogin: true)}).sorted(by: {$0.safeDate > $1.safeDate})
            self.devices.append(contentsOf: myDevices)
            self.tableView.reloadData()
            self.checkDevicesToContinue()
        }
    }
    
    func applyLocalization() {
        
    }
    
    func showFeedback(_ message: String? = nil){
        print("FEEDBACK : \(message ?? "none")")
    }
    
    func handleMaxDeviceRequest(responseData: ResponseData) {
        switch (responseData) {
            case .SuccessDictionary(let data):
                guard let maxDevices = data["maxDevices"] as? Int else {
                    return
                }
                maxAllowedDevices = maxDevices
                checkDevicesToContinue()
            default:
                break
        }
    }
    
    func checkDevicesToContinue() {
        guard maxAllowedDevices > devices.count else {
            continueButton.isEnabled = false
            continueButton.alpha = 0.5
            return
        }
        continueButton.isEnabled = true
        continueButton.alpha = 1
    }
    
    func applyTheme() {
        
    }
    
    @IBAction func onBackPress(_ sender: UIButton) {
        goBack()
    }

    @IBAction func onContinuepress(_ sender: UIButton) {
        let loginManager = LoginManager(loginData: loginData)
        loginManager.delegate = self
        creatingAccountLoadingView.display = true
        loginManager.createAccount()
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
    
    func goToImportOptions(account: Account) {
        let storyboard = UIStoryboard(name: "LogIn", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "importoptionsviewcontroller")  as! ImportOptionsViewController
        controller.myAccount = account
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension DevicesLimitViewController: LoginManagerDelegate {
    func handleResult(account: Account) {
        creatingAccountLoadingView.display = false
        goToImportOptions(account: account)
    }
    
    func throwError(message: String) {
        creatingAccountLoadingView.display = false
        showFeedback(message)
    }
}

extension DevicesLimitViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        devices[indexPath.row].checked = true
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        devices[indexPath.row].checked = false
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = devices[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "devicelimittableviewcell") as! DeviceLimitTableViewCell
        cell.delegate = self
        cell.setContent(device: device)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66.0
    }
}

extension DevicesLimitViewController: DeviceLimitTableViewCellDelegate {
    func onRemoveDevice(deviceId: Int){
        APIManager.deleteDevices(username: self.loginData.username, domain: self.loginData.domain, token: tempToken!, deviceIds: [deviceId]) { (responseData) in
            guard case .Success = responseData else {
                let popover = GenericAlertUIPopover()
                popover.myTitle = String.localize("REMOVE_DEVICES_POPOVER_ERROR_TITLE")
                popover.myMessage = String.localize("REMOVE_DEVICES_POPOVER_ERROR_MESSAGE")
                popover.onOkPress = { self.dismiss(animated: true, completion: nil) }
                self.presentPopover(popover: popover, height: 240)
                return
            }
            if let index = self.devices.firstIndex(where: {$0.id == deviceId}) {
                self.devices.remove(at: index)
                self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
            }
            self.checkDevicesToContinue()
        }
    }
}

extension DevicesLimitViewController: UIGestureRecognizerDelegate {
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
