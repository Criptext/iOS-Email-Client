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
    weak var delegate: RestoreDelegate?
    var state = State.searching
    
    var theme: Theme {
        return ThemeManager.shared.theme
    }
    
    func setSearching() {
        state = .searching
        
        let attrText = NSMutableAttributedString(string: "We are searching in your iCloud (if iCloud Drive is enable) for a backup file.", attributes: [.font: Font.bold.size(17)!, .foregroundColor: theme.markedText])
        let attrText2 = NSAttributedString(string: "This may take a while", attributes: [.font: Font.regular.size(17)!, .foregroundColor: theme.mainText])
        
        attrText.append(attrText2)
        
        messageLabel.attributedText = attrText
        titleLabel.text = "Looking for you backup..."
        titleLabel.textColor = theme.markedText
        
        restoreButton.isHidden = false
        
        restoreButton.isHidden = true
    }
    
    func setFound(email: String, lastDate: Date, size: Int) {
        state = .found
        
        let attrText = NSMutableAttributedString(string: email, attributes: [.font: Font.bold.size(17)!, .foregroundColor: theme.markedText])
        let attrDate = NSAttributedString(string: "\nLast Backup: \(DateUtils.beautyDate(lastDate))", attributes: [.font: Font.regular.size(17)!, .foregroundColor: theme.mainText])
        let attrSize = NSAttributedString(string: "\nSize: \(File.prettyPrintSize(size: size))", attributes: [.font: Font.regular.size(17)!, .foregroundColor: theme.mainText])
        
        attrText.append(attrDate)
        attrText.append(attrSize)
        
        messageLabel.attributedText = attrText
        titleLabel.text = "Backup Found"
        titleLabel.textColor = theme.markedText
        
        restoreButton.isHidden = false
        restoreButton.setTitle("Restore", for: .normal)
    }
    
    func setMissing() {
        state = .missing
        let attrText = NSMutableAttributedString(string: "Backup nowhere to be found! Try checking again if you did have one.", attributes: [.font: Font.regular.size(17)!, .foregroundColor: theme.mainText])
        
        messageLabel.attributedText = attrText
        titleLabel.text = "Backup Not Found"
        titleLabel.textColor = theme.markedText
        
        restoreButton.isHidden = false
        restoreButton.setTitle("Retry", for: .normal)
    }
    
    func setError() {
        state = .error
        
        let attrText = NSMutableAttributedString(string: "Something has happened that is delaying this process.", attributes: [.font: Font.regular.size(17)!, .foregroundColor: theme.mainText])
        let attrQ = NSAttributedString(string: "\n\nDo you want to keep trying? ", attributes: [.font: Font.bold.size(17)!, .foregroundColor: theme.markedText])
        
        attrText.append(attrQ)
        
        messageLabel.attributedText = attrText
        titleLabel.text = "Well that's odd..."
        titleLabel.textColor = theme.markedText
        
        restoreButton.isHidden = false
        restoreButton.setTitle("Retry", for: .normal)
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
