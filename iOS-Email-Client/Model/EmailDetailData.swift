//
//  EmailDetailData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class EmailDetailData{
    var emails : [EmailDetail] = [EmailDetail]()
    
    func mockEmails(){
        let email1 = EmailDetail()
        email1.subject = "Hola Mundo"
        email1.preview = "pffffffff"
        email1.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">pfffffffffff</div>" + Constants.htmlBottomWrapper
        emails.append(email1)
        let email2 = EmailDetail()
        email2.subject = "Este es un texto super largo pues para probar y es unsend"
        email2.preview = "pues aqui para que le hagas unsend"
        email2.content = Constants.unsendEmail
        emails.append(email2)
        let email3 = EmailDetail()
        email3.subject = "Ya sabe baron"
        email3.preview = "y que te puedo decir"
        email3.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">y que te puedo decirsh</div>" + Constants.htmlBottomWrapper
        emails.append(email3)
        let email4 = EmailDetail()
        email4.subject = "Hola Mundo ABC"
        email4.preview = "pffffffff ABC"
        email4.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">pfffffffffff ABC</div>" + Constants.htmlBottomWrapper
        emails.append(email4)
        let email5 = EmailDetail()
        email5.subject = "este es un texto diferente xq yolo"
        email5.preview = "Red Velvet"
        email5.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">Red Velvet</div>" + Constants.htmlBottomWrapper
        emails.append(email5)
        let email6 = EmailDetail()
        email6.subject = "este es un red flavor xq ya tu sabe"
        email6.preview = "red flavor bye bye bye red flavor bye bye bye red flavor bye bye bye red flavor bye bye bye red flavor"
        email6.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">habla caretabla este es un texto con red flavor xq ya esta en el preview que le vamos a hacer baronsh pilas ahi con esa merca</div>" + Constants.htmlBottomWrapper
        //emails.append(email6)
        let email7 = EmailDetail()
        email7.subject = "Candy candy candy"
        email7.preview = "chocolate chocolate"
        email7.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">chocolate chocolate chocoleto</div>" + Constants.htmlBottomWrapper
        //emails.append(email7)
        let email8 = EmailDetail()
        email8.subject = "Unsending Peek a boo"
        email8.preview = "Peek a boo unsend"
        email8.content = Constants.unsendEmail
        //emails.append(email8)
    }
}
