//
//  EmailSourceViewController.swift
//  iOS-Email-Client
//
//  Created by Daniel Tigse on 1/24/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import SwiftSoup

class EmailSourceViewController: UIViewController{
    
    @IBOutlet weak var source: UITextView!
    
    var email: Email?
    weak var myAccount: Account!
    
    override func viewDidLoad() {
        if(email != nil){
            let body = FileUtils.getBodyFromFile(account: myAccount, metadataKey: "\(email!.key)")
            let header = FileUtils.getHeaderFromFile(account: myAccount, metadataKey: "\(email!.key)")
            source.text = "\(header)\n--\(email!.boundary)\nContent-Type: text/plain; charset=UTF-8\nContent-Transfer-Encoding: quoted-printable\n\(getContentPlain(content: body))\n--\(email!.boundary)\nContent-Type: text/html; charset=UTF-8\nContent-Transfer-Encoding: 7bit\n\(body.isEmpty ? email!.content : body)\n--\(email!.boundary)\n"
        }
    }
    
    @IBAction func didPressOK(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func getContentPlain(content: String) -> String {
        do {
            let doc: Document = try SwiftSoup.parse(content)
            return try doc.text()
        } catch {
            return content
        }
    }
}
