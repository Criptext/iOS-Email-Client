//
//  DetailThreadTableViewCell.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 9/19/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation

class DetailThreadTableViewCell: UITableViewCell {
    @IBOutlet weak var expandedContainer: UIView!
    @IBOutlet weak var collapsedContainer: UIView!
    @IBOutlet weak var expandedDateLabel: UILabel!
    @IBOutlet weak var collapsedDateLabel: UILabel!
    @IBOutlet weak var expandedSenderLabel: UILabel!
    @IBOutlet weak var collapsedSenderLabel: UILabel!
    
    @IBOutlet weak var expandedRecipientLabel: UILabel!
    @IBOutlet weak var collapsedSnippet: UILabel!
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var webViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var dateBottomSpaceConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var timerLeftSpaceConstraint: NSLayoutConstraint!
    @IBOutlet weak var expandedTimerButton: UIButton!
    @IBOutlet weak var expandedAttachmentButton: UIButton!
    @IBOutlet weak var collapsedTimerButton: UIButton!
    @IBOutlet weak var collapsedAttachmentButton: UIButton!
    
    @IBOutlet weak var expandedMoreButton: UIButton!
    @IBOutlet weak var expandedLockButton: UIButton!
    @IBOutlet weak var collapsedLockButton: UIButton!
    @IBOutlet weak var expandedUnsendButton: UIButton!
}
