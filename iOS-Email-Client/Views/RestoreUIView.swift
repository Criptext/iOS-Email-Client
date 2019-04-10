//
//  RestoreUIView.swift
//  iOS-Email-Client
//
//  Created by Allisson on 4/9/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation

protocol RestoreDelegate: class {
    func cancelRestore()
    func retryRestore()
    func restore()
}

class RestoreUIView: UIView {
    enum State {
        case found
        case searching
        case restoring
        case error
        case missing
    }
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var cloudImageView: UIImageView!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var percentageContainerView: TipUIView!
    @IBOutlet weak var percentageLabel: CounterLabelUIView!
    weak var delegate: RestoreDelegate?
    var state = State.searching
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    func applyTheme() {
        progressBar.layer.cornerRadius = 5
        progressBar.layer.sublayers![1].cornerRadius = 5
        progressBar.subviews[1].clipsToBounds = true

        cloudImageView.tintColor = theme.criptextBlue
    }
    
    func setSearching() {
        state = .searching
        
        let attrText = NSMutableAttributedString(string: "We are searching in your iCloud (if iCloud Drive is enable) for a backup file.", attributes: [.font: Font.bold.size(16)!, .foregroundColor: theme.markedText])
        let attrText2 = NSAttributedString(string: "\nThis may take a while", attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        
        attrText.append(attrText2)
        
        messageLabel.isHidden = false
        messageLabel.attributedText = attrText
        titleLabel.text = "Looking for you backup..."
        titleLabel.textColor = theme.markedText
        
        restoreButton.isHidden = true
        progressBar.isHidden = true
        cancelButton.isHidden = false
        percentageContainerView.isHidden = true
    }
    
    func setFound(email: String, lastDate: Date, size: Int) {
        state = .found
        
        let attrText = NSMutableAttributedString(string: email, attributes: [.font: Font.bold.size(16)!, .foregroundColor: theme.markedText])
        let attrDate = NSAttributedString(string: "\nLast Backup: \(DateUtils.conversationTime(lastDate) ?? "")", attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        let attrSize = NSAttributedString(string: "\nSize: \(File.prettyPrintSize(size: size))", attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        
        attrText.append(attrDate)
        attrText.append(attrSize)
        
        messageLabel.isHidden = false
        messageLabel.attributedText = attrText
        titleLabel.text = "Backup Found"
        titleLabel.textColor = theme.markedText
        
        restoreButton.isHidden = false
        restoreButton.setTitle("Restore", for: .normal)
        cancelButton.isHidden = false
        progressBar.isHidden = true
        percentageContainerView.isHidden = true
    }
    
    func setMissing() {
        state = .missing
        let attrText = NSMutableAttributedString(string: "Backup nowhere to be found! Try checking again if you did have one.", attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        
        messageLabel.isHidden = false
        messageLabel.attributedText = attrText
        titleLabel.text = "Backup Not Found"
        titleLabel.textColor = theme.markedText
        
        restoreButton.isHidden = false
        restoreButton.setTitle("Retry", for: .normal)
        cancelButton.isHidden = false
        progressBar.isHidden = true
        percentageContainerView.isHidden = true
    }
    
    func setError() {
        state = .error
        
        let attrText = NSMutableAttributedString(string: "Something has happened that is delaying this process.", attributes: [.font: Font.regular.size(16)!, .foregroundColor: theme.mainText])
        let attrQ = NSAttributedString(string: "\n\nDo you want to keep trying? ", attributes: [.font: Font.bold.size(16)!, .foregroundColor: theme.markedText])
        
        attrText.append(attrQ)
        
        messageLabel.isHidden = false
        messageLabel.attributedText = attrText
        titleLabel.text = "Well that's odd..."
        titleLabel.textColor = theme.markedText
        
        restoreButton.isHidden = false
        restoreButton.setTitle("Retry", for: .normal)
        cancelButton.isHidden = false
        progressBar.isHidden = true
        percentageContainerView.isHidden = true
    }
    
    func setRestoring() {
        state = .restoring
        
        titleLabel.text = "Restoring..."
        
        messageLabel.isHidden = true
        restoreButton.isHidden = true
        cancelButton.isHidden = true
        
        progressBar.isHidden = false
        percentageContainerView.isHidden = false
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
    
    @IBAction func didPressRetry(_ sender: Any) {
        if state == .found {
            delegate?.restore()
            return
        }
        delegate?.retryRestore()
    }
    
    @IBAction func didPressCancel(_ sender: Any) {
        delegate?.cancelRestore()
    }
}
