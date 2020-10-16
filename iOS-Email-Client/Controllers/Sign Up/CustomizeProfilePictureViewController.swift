//
//  CustomizeProfilePictureViewController.swift
//  iOS-Email-Client
//
//  Created by Jorge Blacio on 8/23/20.
//  Copyright © 2020 Criptext Inc. All rights reserved.
//

import Foundation
import Material
import SDWebImage
import Photos

class CustomizeProfilePictureViewController: UIViewController {
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var fullnameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var stepLabel: UILabel!
    
    @IBOutlet weak var attachmentController: AttachmentOptionsContainerView!
    @IBOutlet weak var attachmentContainerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var blackBackground: UIView!
    var imagePicker = UIImagePickerController()
    
    var myAccount: Account!
    var recoveryEmail: String!
    var ATTACHMENT_OPTIONS_BOTTOM_PADDING: CGFloat = -120
    var hasPicture = false
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        applyTheme()
        setupFields()
    }
    
    func applyTheme() {
        titleLabel.textColor = theme.mainText
        messageLabel.textColor = theme.secondText
        fullnameLabel.textColor = theme.mainText
        stepLabel.textColor = theme.secondText
        view.backgroundColor = theme.background
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.view.setNeedsDisplay()
    }
    
    func setupFields(){
        titleLabel.text = String.localize("CUSTOMIZE_PROFILE_TITLE")
        messageLabel.text = String.localize("CUSTOMIZE_PROFILE_TITLE")
        fullnameLabel.text = self.myAccount.name
        nextButton.setTitle(String.localize("ADD"), for: .normal)
        skipButton.setTitle(String.localize("SKIP"), for: .normal)
        stepLabel.text = String.localize("CUSTOMIZE_STEP_1")
        attachmentController.docsButton.setTitle(String.localize("CANCEL"), for: .normal)
    }
    
    func showAttachmentDrawer(_ flag:Bool = false){
        self.attachmentContainerBottomConstraint.constant = CGFloat(flag ? 0 : ATTACHMENT_OPTIONS_BOTTOM_PADDING)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.blackBackground.alpha = flag ? 0.5 : 0
        }
    }
    
    @objc func onDonePress(_ sender: Any){
        guard let button = sender as? UIButton else {
            return
        }
        if(button.isEnabled){
            self.onNextPress(button)
        }
    }
    
    func toggleLoadingView(_ show: Bool){
        if(show){
            nextButton.setTitle("", for: .normal)
            loadingView.isHidden = false
            loadingView.startAnimating()
        }else{
            nextButton.setTitle(String.localize("NEXT"), for: .normal)
            loadingView.isHidden = true
            loadingView.stopAnimating()
        }
    }
    
    @IBAction func didPressedGallery(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.photoLibrary) else {
            return
        }
        PHPhotoLibrary.requestAuthorization({ (status) in
            DispatchQueue.main.async { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                switch status {
                case .authorized:
                    weakSelf.imagePicker.allowsEditing = false
                    weakSelf.imagePicker.sourceType = UIImagePickerController.SourceType.photoLibrary
                    weakSelf.present(weakSelf.imagePicker, animated: true, completion: nil)
                    break
                default:
                    break
                }
            }
        })
    }
    
    @IBAction func disPressedRemove(_ sender: Any) {
        self.showAttachmentDrawer(false)
        toggleLoadingView(false)
    }
    
    @IBAction func didPressedCamera(_ sender: Any) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
            DispatchQueue.main.async {
                if !granted {
                    self.showAlert(String.localize("ACCESS_DENIED"), message:String.localize("NEED_ENABLE_ACCESS"), style: .alert)
                    return
                }
                if UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
                    self.imagePicker.sourceType = UIImagePickerController.SourceType.camera
                    self.imagePicker.allowsEditing = false
                    self.present(self.imagePicker, animated: true, completion: nil)
                }
            }
        })
    }
    
    @IBAction func onNextPress(_ sender: UIButton) {
        toggleLoadingView(true)
        switch sender {
        case nextButton:
            if(self.hasPicture){
                goToThemeView()
            } else {
                self.showAttachmentDrawer(true)
            }
        default:
            goToThemeView()
        }
    }
    
    func goToThemeView(){
        let storyboard = UIStoryboard(name: "SignUp", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "customizeThemeView")  as! CustomizeThemeViewController
        controller.myAccount = self.myAccount
        controller.recoveryEmail = self.recoveryEmail
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func changeProfilePicture(image: UIImage, imageName: String){
        let image = UIUtils.resizeImage(image: image, targetSize: CGSize(width: 250, height: 250))
        let data = image.pngData()
        let inputStream = InputStream.init(data: data!)
        let params = [
            "mimeType": File.mimeTypeForPath(path: imageName),
            "size": data!.count
            ] as [String: Any]
        APIManager.uploadProfilePicture(inputStream: inputStream, params: params, token: myAccount.jwt, progressCallback: { (progress) in
        }) { (responseData) in
            guard case .Success = responseData else {
                self.showAlert(String.localize("PROFILE"), message: String.localize("profile_picture_update_failed"), style: .alert)
                return
            }
            self.showAlert(String.localize("PROFILE"), message: String.localize("profile_picture_updated"), style: .alert)
            UIUtils.deleteSDWebImageCache()
        }
    }
    
    func makeCircleImage(){
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = false
        imageView.layer.cornerRadius = imageView.frame.size.width / 2
        imageView.clipsToBounds = true
    }
}

extension CustomizeProfilePictureViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}

extension CustomizeProfilePictureViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return string.rangeOfCharacter(from: .whitespacesAndNewlines) == nil
    }
}

extension CustomizeProfilePictureViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        self.showAttachmentDrawer(false)
        if let imgUrl = info[.imageURL] as? URL{
            let imageName = imgUrl.lastPathComponent
            let image = info[.originalImage] as! UIImage
            imageView.image = image
            self.makeCircleImage()
            changeProfilePicture(image: image, imageName: imageName)
            toggleLoadingView(false)
            return
        }

        if let pickedImage = info[.originalImage] as? UIImage {
            let imageName = "\(String.random()).png"
            imageView.image = pickedImage
            self.makeCircleImage()
            let fileManager = FileManager.default
            let path = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString).appendingPathComponent(imageName)
            let data = pickedImage.pngData()
            fileManager.createFile(atPath: path as String, contents: data, attributes: nil)
            changeProfilePicture(image: pickedImage, imageName: imageName)
            toggleLoadingView(false)
            return
        }
    }
}
