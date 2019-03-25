//
//  ProfileEditorViewController.swift
//  iOS-Email-Client
//
//  Created by Saul Mestanza on 1/29/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import SDWebImage
import CICropPicker

class ProfileEditorViewController: UIViewController {
    
    internal enum Option {
        case name
        case signature
        case password
        case recovery
        case reply
        case logout
        case deleteAccount
        
        var name: String {
            switch(self){
            case .name:
                return String.localize("PROFILE_NAME")
            case .signature:
                return String.localize("SIGNATURE")
            case .password:
                return String.localize("PASSWORD")
            case .recovery:
                return String.localize("RECOVERY_EMAIL")
            case .reply:
                return String.localize("REPLY_TO_TITLE")
            case .logout:
                return String.localize("SIGNOUT")
            case .deleteAccount:
                return String.localize("DELETE_ACCOUNT")
            }
        }
    }
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var indicatorView: UIActivityIndicatorView!
    @IBOutlet weak var blackBackground: UIView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var attachmentController: AttachmentOptionsContainerView!
    @IBOutlet weak var attachmentContainerBottomConstraint: NSLayoutConstraint!
    var imagePicker = UIImagePickerController()
    var attachmentOptionsHeight: CGFloat = 0
    var generalData: GeneralSettingsData!
    var devicesData: DeviceSettingsData!
    var myAccount: Account!
    var options = [.name, .signature, .password, .recovery, .reply, .logout, .deleteAccount] as [Option]
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        navigationItem.title = String.localize("PROFILE")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes(
            [NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        if UIDevice().userInterfaceIdiom == .phone {
            switch UIScreen.main.nativeBounds.height {
            case 2436, 2688, 1792:
                attachmentOptionsHeight = -20
            default:
                attachmentOptionsHeight = 0
            }
        }
        tableView.delegate = self
        tableView.dataSource = self
        imagePicker.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideBlackBackground(_:)))
        self.blackBackground.addGestureRecognizer(tap)
        self.attachmentContainerBottomConstraint.constant = -100
        nameLabel.text = myAccount.name
        emailLabel.text = "\(myAccount.username)\(Constants.domain)"
        UIUtils.deleteSDWebImageCache()
        setProfileImage()
        applyTheme()
    }
    
    @objc func hideBlackBackground(_ flag:Bool = false){
        self.showAttachmentDrawer(false)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.blackBackground.alpha = 0
        }
    }
    
    func resetProfileImage(){
        imageView.setImageWith(myAccount.name, color: colorByName(name: myAccount.name), circular: true, fontName: "NunitoSans-Regular")
    }
    
    func setProfileImage(){
        imageView.sd_setImage(with: URL(string: "\(Env.apiURL)/user/avatar/\(myAccount.username)"), placeholderImage: nil, options: [SDWebImageOptions.continueInBackground, SDWebImageOptions.lowPriority]) { (image, error, cacheType, url) in
            if error != nil {
                self.resetProfileImage()
            }else{
                self.makeCircleImage()
            }
            self.indicatorView.isHidden = true
        }
    }
    
    func makeCircleImage(){
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.clipsToBounds = true
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        self.view.backgroundColor = theme.background
        self.tableView.backgroundColor = theme.secondBackground
        nameLabel.textColor = theme.mainText
        emailLabel.textColor = theme.mainText
        attachmentController.docsButton.setTitle(String.localize("remove_picture"), for: .normal)
        initFloatingButton(color: theme.criptextBlue)
    }
    
    func initFloatingButton(color: UIColor){
        let shadowPath = UIBezierPath(rect: CGRect(x: 15, y: 15, width: 30, height: 30))
        editButton.backgroundColor = color
        editButton.layer.masksToBounds =  false
        editButton.layer.shadowPath = shadowPath.cgPath
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
        return
    }
    
    func showAttachmentDrawer(_ flag:Bool = false){
        self.attachmentContainerBottomConstraint.constant = CGFloat(flag ? -attachmentOptionsHeight : -100)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.blackBackground.alpha = flag ? 0.5 : 0
        }
    }
    
    @IBAction func editImage(_ sender: Any) {
        showAttachmentDrawer(true)
    }
    
    @IBAction func didPressedGallery(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
            imagePicker.allowsEditing = false
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func disPressedRemove(_ sender: Any) {
        self.showAttachmentDrawer(false)
        APIManager.deleteProfilePicture(account: myAccount) { [weak self] (responseData) in
            guard case .Success = responseData else {
                self!.showAlert(String.localize("SOMETHING_WRONG"), message: String.localize("profile_picture_delete_failed"), style: .alert)
                return
            }
            self!.showAlert(String.localize("PROFILE"), message: String.localize("profile_picture_deleted"), style: .alert)
            UIUtils.deleteSDWebImageCache()
            self!.resetProfileImage()
        }
    }
    
    @IBAction func didPressedCamera(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func changeProfilePicture(image: UIImage, imageName: String){
        let image = UIUtils.resizeImage(image: image, targetSize: CGSize(width: 250, height: 250))
        let data = UIImagePNGRepresentation(image)
        let inputStream = InputStream.init(data: data!)
        let params = [
            "mimeType": File.mimeTypeForPath(path: imageName),
            "size": data!.count
            ] as [String: Any]
        APIManager.uploadProfilePicture(inputStream: inputStream, params: params, account: myAccount, progressCallback: { (progress) in
        }) { (responseData) in
            guard case .Success = responseData else {
                self.showAlert(String.localize("PROFILE"), message: String.localize("profile_picture_update_failed"), style: .alert)
                self.resetProfileImage()
                return
            }
            self.showAlert(String.localize("PROFILE"), message: String.localize("profile_picture_updated"), style: .alert)
            UIUtils.deleteSDWebImageCache()
        }
    }
    
    func changeProfileName(name: String){
        let params = EventData.Peer.NameChanged(name: name)
        APIManager.updateName(name: name, account: myAccount) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout(account: self.myAccount)
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("SOMETHING_WRONG"), message: String.localize("UNABLE_UPDATE_PROFILE"), style: .alert)
                return
            }
            self.nameLabel.text = name
            self.showAlert(String.localize("PROFILE"), message: String.localize("PROFILE_SUCCESS"), style: .alert)
            DBManager.update(account: self.myAccount, name: name)
            DBManager.createQueueItem(params: ["cmd": Event.Peer.changeName.rawValue, "params": params.asDictionary()], account: self.myAccount)
        }
    }
}


extension ProfileEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        self.showAttachmentDrawer(false)
        if let imgUrl = info[UIImagePickerControllerImageURL] as? URL{
            let imageName = imgUrl.lastPathComponent
            let image = info[UIImagePickerControllerOriginalImage] as! UIImage
            imageView.image = image
            self.makeCircleImage()
            changeProfilePicture(image: image, imageName: imageName)
            return
        }

        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            let imageName = "\(String.random()).png"
            imageView.image = pickedImage
            self.makeCircleImage()
            let fileManager = FileManager.default
            let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
            let data = UIImagePNGRepresentation(pickedImage)
            fileManager.createFile(atPath: path as String, contents: data, attributes: nil)
            changeProfilePicture(image: pickedImage, imageName: imageName)
            return
        }
    }
}

extension ProfileEditorViewController: LinkDeviceDelegate {
    func onAcceptLinkDevice(linkData: LinkData) {
        guard linkData.version == Env.linkVersion else {
            let popover = GenericAlertUIPopover()
            popover.myTitle = String.localize("VERSION_TITLE")
            popover.myMessage = String.localize("VERSION_MISMATCH")
            self.presentPopover(popover: popover, height: 220)
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let linkDeviceVC = storyboard.instantiateViewController(withIdentifier: "connectUploadViewController") as! ConnectUploadViewController
        linkDeviceVC.linkData = linkData
        linkDeviceVC.myAccount = myAccount
        self.present(linkDeviceVC, animated: true, completion: nil)
    }
    func onCancelLinkDevice(linkData: LinkData) {
        if case .sync = linkData.kind {
            APIManager.syncDeny(randomId: linkData.randomId, account: myAccount, completion: {_ in })
        } else {
            APIManager.linkDeny(randomId: linkData.randomId, account: myAccount, completion: {_ in })
        }
    }
}

extension ProfileEditorViewController: UIGestureRecognizerDelegate {
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

extension ProfileEditorViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let option = options[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "optionCell") as! GeneralTapTableCellView
        cell.backgroundColor = .clear
        cell.optionLabel.text = option.name
        switch(option) {
        case .logout, .deleteAccount:
            cell.messageLabel.text = ""
            cell.loader.isHidden = true
            cell.goImageView.isHidden = true
            cell.optionLabel.textColor = option == .deleteAccount ? theme.alert : theme.mainText
            cell.loader.stopAnimating()
            return cell
        case .recovery:
            cell.optionLabel.textColor = theme.mainText
            cell.messageLabel.text = generalData.recoveryEmailStatus.description
            cell.messageLabel.textColor = generalData.recoveryEmailStatus.color
            guard generalData.recoveryEmail != nil else {
                cell.loader.startAnimating()
                cell.loader.isHidden = false
                cell.goImageView.isHidden = true
                return cell
            }
            cell.loader.stopAnimating()
            cell.loader.isHidden = true
            cell.goImageView.isHidden = false
            return cell
        default:
            cell.optionLabel.textColor = theme.mainText
            cell.goImageView.isHidden = false
            cell.messageLabel.text = ""
            cell.loader.stopAnimating()
            cell.loader.isHidden = true
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let option = options[indexPath.row]
        switch option {
        case .name:
            showChangeName()
        case .signature:
            goToSignature()
        case .password:
            goToChangePassword()
        case .recovery:
            goToRecoveryEmail()
        case .reply:
            replyTo()
        case .logout:
            guard self.devicesData.devices.count <= 1 && generalData.isTwoFactor else {
                showLogout()
                return
            }
            showWarningLogout()
        case .deleteAccount:
            showDeleteAccount()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func showChangeName() {
        let changeNamePopover = SingleTextInputViewController()
        changeNamePopover.myTitle = String.localize("CHANGE_NAME")
        changeNamePopover.initInputText = self.myAccount.name
        changeNamePopover.onOk = { text in
            self.changeProfileName(name: text)
        }
        self.presentPopover(popover: changeNamePopover, height: Constants.singleTextPopoverHeight)
    }
    
    func goToSignature(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let signatureVC = storyboard.instantiateViewController(withIdentifier: "signatureEditorViewController") as! SignatureEditorViewController
        signatureVC.myAccount = myAccount
        self.navigationController?.pushViewController(signatureVC, animated: true)
    }
    
    func goToChangePassword(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let changePassVC = storyboard.instantiateViewController(withIdentifier: "changePassViewController") as! ChangePassViewController
        changePassVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(changePassVC, animated: true)
    }
    
    func goToRecoveryEmail(){
        guard generalData.recoveryEmail != nil else {
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let recoveryVC = storyboard.instantiateViewController(withIdentifier: "recoveryEmailViewController") as! RecoveryEmailViewController
        recoveryVC.generalData = self.generalData
        recoveryVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(recoveryVC, animated: true)
    }
    
    func replyTo(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let replyToVC = storyboard.instantiateViewController(withIdentifier: "replyToEditorViewController") as! ReplyToEditorViewController
        replyToVC.generalData = self.generalData
        replyToVC.myAccount = self.myAccount
        self.navigationController?.pushViewController(replyToVC, animated: true)
    }
    
    func showLogout(){
        let logoutPopover = GenericDualAnswerUIPopover()
        logoutPopover.initialTitle = String.localize("SIGNOUT")
        logoutPopover.initialMessage = String.localize("Q_SURE_LOGOUT")
        logoutPopover.leftOption = String.localize("CANCEL")
        logoutPopover.rightOption = String.localize("YES")
        logoutPopover.onResponse = { [weak self] accept in
            guard accept,
                let weakSelf = self else {
                    return
            }
            weakSelf.confirmLogout()
        }
        self.presentPopover(popover: logoutPopover, height: 175)
    }
    
    func showDeleteAccount(){
        let passwordPopover = PasswordUIPopover()
        passwordPopover.answerShouldDismiss = false
        passwordPopover.initialTitle = String.localize("DELETE_ACCOUNT")
        let attrRegularText = NSMutableAttributedString(string: String.localize("DELETING_ACCOUNT"), attributes: [NSAttributedString.Key.font: Font.regular.size(14)!, NSAttributedString.Key.foregroundColor: UIColor.black])
        let attrBoldText = NSMutableAttributedString(string: String.localize("DELETE_WILL_ERASE"), attributes: [NSAttributedString.Key.font: Font.bold.size(14)!, NSAttributedString.Key.foregroundColor: UIColor.black])
        let attrRegularText2 = NSMutableAttributedString(string: String.localize("DELETE_NO_LONGER"), attributes: [NSAttributedString.Key.font: Font.regular.size(14)!, NSAttributedString.Key.foregroundColor: UIColor.black])
        attrRegularText.append(attrBoldText)
        attrRegularText.append(attrRegularText2)
        passwordPopover.initialAttrMessage = attrRegularText
        passwordPopover.onOkPress = { [weak self] pass in
            guard let weakSelf = self else {
                return
            }
            weakSelf.deleteAccount(password: pass)
        }
        self.presentPopover(popover: passwordPopover, height: 260)
    }
    
    func deleteAccount(password: String){
        APIManager.deleteAccount(password: password.sha256()!, account: self.myAccount, completion: { [weak self] (responseData) in
            guard let weakSelf = self else {
                return
            }
            if case .BadRequest = responseData {
                if let popover = weakSelf.presentedViewController as? PasswordUIPopover {
                    popover.dismiss(animated: false, completion: nil)
                }
                weakSelf.showAlert(String.localize("DELETE_ACCOUNT_FAILED"), message: String.localize("WRONG_PASS_RETRY"), style: .alert)
                return
            }
            guard case .Success = responseData,
                let delegate = UIApplication.shared.delegate as? AppDelegate else {
                    if let popover = weakSelf.presentedViewController as? PasswordUIPopover {
                        popover.dismiss(animated: false, completion: nil)
                    }
                    weakSelf.showAlert(String.localize("DELETE_ACCOUNT_FAILED"), message: String.localize("UNABLE_DELETE_ACCOUNT"), style: .alert)
                    return
            }
            delegate.logout(account: weakSelf.myAccount, manually: false, message: String.localize("DELETE_ACCOUNT_SUCCESS"))
        })
    }
    
    func showWarningLogout() {
        let logoutPopover = GenericDualAnswerUIPopover()
        logoutPopover.initialTitle = String.localize("WARNING")
        logoutPopover.initialMessage = String.localize("Q_SIGNOUT_2FA")
        logoutPopover.leftOption = String.localize("CANCEL")
        logoutPopover.rightOption = String.localize("YES")
        logoutPopover.onResponse = { accept in
            guard accept else {
                return
            }
            self.confirmLogout()
        }
        self.presentPopover(popover: logoutPopover, height: 223)
    }
    
    func confirmLogout(){
        APIManager.logout(account: myAccount) { (responseData) in
            if case .Unauthorized = responseData {
                self.logout(account: self.myAccount)
                return
            }
            if case .Forbidden = responseData {
                self.presentPasswordPopover(myAccount: self.myAccount)
                return
            }
            guard case .Success = responseData else {
                self.showAlert(String.localize("SIGNOUT_ERROR"), message: String.localize("UNABLE_SIGNOUT"), style: .alert)
                return
            }
            self.logout(account: self.myAccount, manually: true)
        }
    }
}
