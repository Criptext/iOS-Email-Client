//
//  CriptextDrawerController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 3/9/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import Material

class CriptextDrawerController: NavigationDrawerController{
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if(isRightViewOpened && isPointOutsidePanArea(point: touch.location(in: view))){
            return false
        }
        return super.gestureRecognizer(gestureRecognizer, shouldReceive: touch)
    }
    
    func isPointOutsidePanArea(point: CGPoint) -> Bool{
        guard let rightView = self.rightView else {
            return false
        }
        return point.x > (view.bounds.width - rightView.bounds.width/2)
    }
}
