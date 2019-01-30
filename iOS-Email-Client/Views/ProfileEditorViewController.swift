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
    
    @IBOutlet weak var blackBackground: UIView!
    @IBOutlet weak var saveProfile: UIButton!
    @IBOutlet weak var profileName: UITextField!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var attachmentController: AttachmentOptionsContainerView!
    @IBOutlet weak var attachmentContainerBottomConstraint: NSLayoutConstraint!
    var imagePicker = UIImagePickerController()
    var attachmentOptionsHeight: CGFloat = 90
    var generalData: GeneralSettingsData!
    var myAccount: Account!
    
    override func viewDidLoad() {
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self as UIGestureRecognizerDelegate
        navigationItem.title = String.localize("PROFILE")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
        navigationItem.rightBarButtonItem?.setTitleTextAttributes(
            [NSAttributedStringKey.foregroundColor: UIColor.white], for: .normal)
        imagePicker.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideBlackBackground(_:)))
        self.blackBackground.addGestureRecognizer(tap)
        self.attachmentContainerBottomConstraint.constant = 50
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
        print("\(Env.apiURL)/user/avatar/\(myAccount.username)")
        imageView.sd_setImage(with: URL(string: "\(Env.apiURL)/user/avatar/\(myAccount.username)"), placeholderImage: nil, options: [SDWebImageOptions.continueInBackground, SDWebImageOptions.lowPriority, SDWebImageOptions.refreshCached, SDWebImageOptions.handleCookies, SDWebImageOptions.retryFailed]) { (image, error, cacheType, url) in
            if error != nil {
                self.resetProfileImage()
            }
        }
    }
    
    func applyTheme() {
        let theme = ThemeManager.shared.theme
        self.view.backgroundColor = theme.overallBackground
        profileName.backgroundColor = theme.overallBackground
        profileName.textColor = theme.mainText
        profileName.attributedPlaceholder = NSAttributedString(
            string: String.localize("CHANGE_NAME"),
            attributes: [NSAttributedString.Key.foregroundColor: theme.placeholder]
        )
        profileName.text = myAccount.name
        initFloatingButton(color: theme.criptextBlue)
    }
    
    func initFloatingButton(color: UIColor){
        let shadowPath = UIBezierPath(rect: CGRect(x: 15, y: 15, width: 30, height: 30))
        editButton.layer.shadowColor = color.cgColor
        editButton.layer.shadowOffset = CGSize(width: 0.5, height: 0.5)  //Here you control x and y
        editButton.layer.shadowOpacity = 1
        editButton.layer.shadowRadius = 10//Here your control your blur
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
        self.attachmentContainerBottomConstraint.constant = CGFloat(flag ? -attachmentOptionsHeight : 50)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.blackBackground.alpha = flag ? 0.5 : 0
        }
    }
    
    @IBAction func editImage(_ sender: Any) {
        showAttachmentDrawer(true)
    }
    
    func openCamera(){
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
            imagePicker.sourceType = UIImagePickerControllerSourceType.camera
            imagePicker.allowsEditing = false
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func openGallery(){
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary){
            imagePicker.allowsEditing = true
            imagePicker.sourceType = UIImagePickerControllerSourceType.photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    @IBAction func didPressedGallery(_ sender: Any) {
        self.openGallery()
    }
    
    @IBAction func disPressedRemove(_ sender: Any) {
        self.resetProfileImage()
    }
    
    @IBAction func didPressedCamera(_ sender: Any) {
        self.openCamera()
    }
    
    @IBAction func saveProfilePressed(_ sender: Any) {
        changeProfileName(name: profileName.text ?? "")
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
            self.showAlert(String.localize("REPLY_TO_TITLE"), message: String.localize("REPLY_TO_SUCCESS"), style: .alert)
            DBManager.update(account: self.myAccount, name: name)
            DBManager.createQueueItem(params: ["cmd": Event.Peer.changeName.rawValue, "params": params.asDictionary()])
        }
    }
}


extension ProfileEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView.image = pickedImage
            imageView.layer.masksToBounds = false
            imageView.layer.cornerRadius = imageView.frame.size.width / 2
            imageView.clipsToBounds = true
        }
        picker.dismiss(animated: true, completion: nil)
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

