//
//  RemoveDevicesViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 7/25/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

class RemoveDevicesViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textMessage: UILabel!
    var loginData: LoginData!
    var multipleAccount = false
    var deviceData: DeviceSettingsData!
    var tempToken: String!
    var devices: [Device] {
        return deviceData.devices
    }
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        navigationItem.title = String.localize("REMOVE_DEVICES_TITLE")
        navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(dismissViewController))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "delete-icon").tint(with: .white), style: .plain, target: self, action: #selector(dismissViewController))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white], for: .normal)
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        textMessage.text = String.localize("REMOVE_DEVICES_MESSAGE", arguments: Env.maxAllowedDevices, (devices.count - (Env.maxAllowedDevices - 1)))
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsMultipleSelectionDuringEditing = true
        self.tableView.setEditing(!tableView.isEditing, animated: true)
        self.applyTheme()
        checkTrashButton()
    }
    
    func applyTheme() {
        let attributedTitle = NSAttributedString(string: String.localize("REMOVE_DEVICES_TITLE"), attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.mainText])
        tabItem.setAttributedTitle(attributedTitle, for: .normal)
        let attributed2Title = NSAttributedString(string: String.localize("REMOVE_DEVICES_TITLE"), attributes: [.font: Font.semibold.size(16.0)!, .foregroundColor: theme.criptextBlue])
        tabItem.setAttributedTitle(attributed2Title, for: .selected)
        tableView.backgroundColor = theme.overallBackground
        self.view.backgroundColor = theme.overallBackground
        tableView.separatorColor = theme.separator
        textMessage.textColor = theme.mainText
    }
    
    private func checkTrashButton(){
        let checkedDevices = devices.filter { $0.checked }.count
        if(checkedDevices > 0){
            navigationItem.title = "\(checkedDevices)"
            navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(uncheckAllDevices), image: #imageLiteral(resourceName: "close-rounded"))
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "delete-icon").tint(with: .white), style: .plain, target: self, action: #selector(removeSelectedDevices))
        } else {
            navigationItem.title = String.localize("REMOVE_DEVICES_TITLE")
            navigationItem.leftBarButtonItem = UIUtils.createLeftBackButton(target: self, action: #selector(dismissViewController))
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "delete-icon").tint(with: .gray), style: .plain, target: self, action: nil)
        }
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
}

extension RemoveDevicesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        devices[indexPath.row].checked = true
        checkTrashButton()
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        devices[indexPath.row].checked = false
        checkTrashButton()
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device = devices[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsDeviceCell") as! SettingsDeviceTableViewCell
        cell.delegate = self
        cell.setContent(device: device)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66.0
    }
}

extension RemoveDevicesViewController: CustomTabsChildController {
    func reloadView() {
        self.applyTheme()
        tableView.reloadData()
    }
}

extension RemoveDevicesViewController: DeviceTableViewCellDelegate {
    @objc func tableViewCellDidLongPress(_ cell: SettingsDeviceTableViewCell) {
       
    }
    
    func removeDevices(_ deviceIds: [Int]){
        deviceIds.forEach { (deviceId) in
            guard let index = deviceData.devices.firstIndex(where: {$0.id == deviceId}) else {
                return
            }
            deviceData.devices.remove(at: index)
            tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
        }
    }
    
    @objc func dismissViewController(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func uncheckAllDevices(){
        self.devices.forEach {
            $0.checked = false
        }
        self.tableView.isEditing = false
        self.tableView.isEditing = true
        checkTrashButton()
    }
    
    @objc func removeSelectedDevices(){
        let deviceIds = devices.filter { $0.checked }.map { $0.id }
        APIManager.deleteDevices(username: self.loginData.username, domain: self.loginData.domain, token: self.tempToken, deviceIds: deviceIds) { (responseData) in
            guard case .Success = responseData else {
                let popover = GenericAlertUIPopover()
                popover.myTitle = String.localize("REMOVE_DEVICES_POPOVER_ERROR_TITLE")
                popover.myMessage = String.localize("REMOVE_DEVICES_POPOVER_ERROR_MESSAGE")
                popover.onOkPress = { self.dismiss(animated: true, completion: nil) }
                self.presentPopover(popover: popover, height: 220)
                return
            }
            self.removeDevices(deviceIds)
            let remainingRemovals = (self.devices.count - (Env.maxAllowedDevices - 1))
            if(remainingRemovals > 0) {
                let popover = GenericAlertUIPopover()
                popover.myTitle = String.localize("REMOVE_DEVICES_POPOVER_TITLE")
                popover.myMessage = String.localize("REMOVE_DEVICES_POPOVER_MESSAGE", arguments: remainingRemovals)
                self.presentPopover(popover: popover, height: 220)
            } else {
                self.linkBegin(username: self.loginData.username, domain: self.loginData.domain)
            }
        }
    }
    
    func linkBegin(username: String, domain: String){
        APIManager.linkBegin(username: username, domain: domain) { (responseData) in
            if case .Missing = responseData {
                self.showPopoverError(error: String.localize("USERNAME_NOT"))
                return
            }
            if case .BadRequest = responseData {
                self.loginToMailbox()
                return
            }
            if case let .Error(error) = responseData,
                error.code != .custom {
                self.showPopoverError(error: error.description)
                return
            }
            guard case let .SuccessDictionary(data) = responseData,
                let isTwoFactor = data["twoFactorAuth"] as? Bool,
                let jwtTemp = data["token"] as? String else {
                self.showPopoverError(error: String.localize("FALLBACK_ERROR"))
                return
            }
            self.loginData.jwt = jwtTemp
            self.loginData.isTwoFactor = isTwoFactor
            self.jumpToLoginDeviceView()
        }
    }
    
    func jumpToLoginDeviceView(){
        let storyboard = UIStoryboard(name: "Login", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "loginDeviceViewController")  as! LoginDeviceViewController
        controller.loginData = self.loginData
        controller.multipleAccount = self.multipleAccount
        controller.showPasswordButton = false
        self.present(controller, animated: true)
    }
    
    func loginToMailbox(){
        APIManager.loginRequest(username: self.loginData.username, domain: self.loginData.domain, password: self.loginData.password!.sha256()!) { (responseData) in
            guard case let .SuccessString(dataString) = responseData,
                let data = Utils.convertToDictionary(text: dataString) else {
                    let storyboard = UIStoryboard(name: "Login", bundle: nil)
                    let initialVC = storyboard.instantiateInitialViewController() as! UINavigationController
                    let loginVC = initialVC.topViewController as! NewLoginViewController
                    loginVC.loggedOutRemotely = String.localize("FALLBACK_ERROR")
                    var options = UIWindow.TransitionOptions()
                    options.direction = .toTop
                    options.duration = 0.4
                    options.style = .easeOut
                    UIApplication.shared.keyWindow?.setRootViewController(initialVC, options: options)
                    return
            }
            let name = data["name"] as! String
            let deviceId = data["deviceId"] as! Int
            let token = data["token"] as! String
            let signupData = SignUpData(username: self.loginData.username, password: self.loginData.password!, domain: self.loginData.domain, fullname: name, optionalEmail: nil)
            signupData.deviceId = deviceId
            signupData.token = token
            signupData.comingFromLogin = true
            let storyboard = UIStoryboard(name: "Login", bundle: nil)
            let controller = storyboard.instantiateViewController(withIdentifier: "loginDeviceViewController")  as! LoginDeviceViewController
            controller.loginData = self.loginData
            controller.multipleAccount = self.multipleAccount
            self.present(controller, animated: true)
        }
    }
    
    func showPopoverError(error: String){
        let alertVC = GenericAlertUIPopover()
        alertVC.myTitle = String.localize("WARNING")
        alertVC.myMessage = error
        self.presentPopover(popover: alertVC, height: 220)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        ThemeManager.shared.removeListener(id: "removeDevicesViewController")
    }
}

extension RemoveDevicesViewController: UIGestureRecognizerDelegate {
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
