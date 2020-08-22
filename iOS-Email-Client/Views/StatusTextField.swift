//
//  StatusTextField.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/14/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

open class StatusTextField: TextField{
    enum Status {
        case none, valid, invalid
    }
    
    var status = Status.none
    var markView: UIImageView?
    var invalidDividerColor: UIColor = UIColor.black
    var validDividerColor: UIColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.6)
    
    func setStatus(_ sts: Status, _ error: String? = nil){
        status = sts
        detail = error
        if(status == .invalid){
            dividerNormalColor = invalidDividerColor
        }else{
            dividerNormalColor = validDividerColor
        }
        updateMark()
    }
    
    func updateMark(){
        guard let markView = self.markView else { return }

        switch(status){
        case .valid:
            markView.image = UIImage(named: "mark-success")
            markView.isHidden = false;
            markView.tintColor = UIColor.white
            break
        case .invalid:
            markView.image = UIImage(named: "mark-error")
            markView.tintColor = UIColor.black
            markView.isHidden = false;
            break
        default:
            markView.isHidden = true
        }
    }
    
    var isValid: Bool{
        get{
            return self.status == .valid
        }
    }
    var isNotInvalid: Bool{
        get{
            return self.status != .invalid
        }
    }
}
