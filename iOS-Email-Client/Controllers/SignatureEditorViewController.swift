//
//  SignatureEditorViewController.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 5/24/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RichEditorView

class SignatureEditorViewController: UIViewController {
    
    @IBOutlet weak var richEditor: RichEditorView!
    
    override func viewDidLoad() {
        navigationItem.title = "Signature"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "arrow-back").tint(with: .white), style: .plain, target: self, action: #selector(goBack))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        richEditor.focus(at: CGPoint(x: 0.0, y: 0.0))
    }
    
    @objc func goBack(){
        navigationController?.popViewController(animated: true)
    }
}
