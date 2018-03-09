//
//  AttachmentHistoryUIPopover.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/8/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class AttachmentHistoryUIPopover: UIViewController, UIPopoverPresentationControllerDelegate{
    @IBOutlet weak var attachmentsTableView: UITableView!
    
    init(){
        super.init(nibName: "AttachmentHistoryUIPopover", bundle: nil)
        self.modalPresentationStyle = UIModalPresentationStyle.popover;
        self.popoverPresentationController?.delegate = self;
    }
}

extension AttachmentHistoryUIPopover: UITableViewDelegate, UITableViewDataSource{

}
