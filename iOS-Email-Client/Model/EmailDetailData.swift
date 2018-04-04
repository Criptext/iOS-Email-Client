//
//  EmailDetailData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/28/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class EmailDetailData{
    var emails = [Email]()
    var labels = [Label]()
    var subject = "This is a large subject to display a 2 lines subject"
    
    func mockLabels(){
        labels.append(Label("inbox"))
        labels.append(Label("Spam"))
        labels.append(Label("Starred"))
        labels.append(Label("Important"))
        labels.append(Label("Hola"))
        labels.append(Label("Principal"))
        labels.append(Label("Trabajo"))
        labels.append(Label("Starred"))
        labels.append(Label("Important"))
        labels.append(Label("Hola"))
        labels.append(Label("Principal"))
        labels.append(Label("Trabajo"))
    }
    
    func mockEmails(){
        let email1 = Email()
        email1.subject = "Hola Mundo"
        email1.preview = "pffffffff"
        email1.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">pfffffffffff</div>" + Constants.htmlBottomWrapper
        emails.append(email1)
        let email2 = Email()
        email2.delivered = DeliveryStatus.UNSENT
        email2.subject = "Este es un texto super largo pues para probar y es unsend"
        email2.preview = "pues aqui para que le hagas unsend"
        email2.content = Constants.unsendEmail
        emails.append(email2)
        let email3 = Email()
        email3.subject = "Ya sabe baron"
        email3.preview = "y que te puedo decir"
        email3.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">y que te puedo decirsh</div>" + Constants.htmlBottomWrapper
        emails.append(email3)
        let email4 = Email()
        email4.subject = "Hola Mundo ABC"
        email4.preview = "pffffffff ABC"
        email4.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">pfffffffffff ABC</div>" + Constants.htmlBottomWrapper
        emails.append(email4)
        let email5 = Email()
        email5.subject = "este es un texto diferente xq yolo"
        email5.preview = "Red Velvet"
        email5.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">Red Velvet</div>" + Constants.htmlBottomWrapper
        emails.append(email5)
        let email6 = Email()
        email6.subject = "este es un red flavor xq ya tu sabe"
        email6.preview = "red flavor bye bye bye red flavor bye bye bye red flavor bye bye bye red flavor bye bye bye red flavor"
        email6.content = longPage
        emails.append(email6)
        let email7 = Email()
        email7.subject = "Candy candy candy"
        email7.preview = "chocolate chocolate"
        email7.content = Constants.htmlTopWrapper + "<div dir=\"ltr\">chocolate chocolate chocoleto</div>" + Constants.htmlBottomWrapper
        //emails.append(email7)
        let email8 = Email()
        email8.subject = "Unsending Peek a boo"
        email8.preview = "Peek a boo unsend"
        email8.content = Constants.unsendEmail
        //emails.append(email8)
    }
    
    let longPage = Constants.htmlTopWrapper + """
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.=
        w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
        <html>
        <head>
        <meta http-equiv=3D"Content-Type" content=3D"text/html; charset=3DUTF-8"/>
        <meta name=3D"format-detection" content=3D"telephone=3Dno"/>
        <meta name=3D"format-detection" content=3D"address=3Dno"/>
        <meta name=3D"robots" content=3D"noindex,nofollow"/>
        <meta name=3D"viewport" content=3D"width=3Ddevice-width, initial-scale=3D1"=
         />
        <style type=3D"text/css">
        /*
        Addresses, phone numbers, and dates can be changed to links. This removes t=
        he applied link styling. Content still remains cickable. This fix does not =
        work in Gmail.
        */
        .linksColorWhite a{color:#ffffff !important;text-decoration:none !important=
        ;}
        .linksColorBlack a{color:#000000 !important;text-decoration:none !important=
        ;}

        @media only screen=20
        and (min-device-width : 414px)
        and (-webkit-min-device-pixel-ratio : 3) {
        .zoomFix {height:60px !important;}
        }
        </style>
        </head>
         =20
        =20
        <body style=3D"margin:0px;padding:0px;-ms-text-size-adjust:100%;-webkit-tex=
        t-size-adjust:100%;">


        <!--Wrapper Table-->


        <table bgcolor=3D"#ebebeb" border=3D"0" cellpadding=3D"0" cellspacing=3D"0"=
         style=3D"border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:=
        0pt;" width=3D"100%">
        <tr>
        <td align=3D"center">


        <!--Begin Inner Table-->

        <table align=3D"center" border=3D"0" cellpadding=3D"0" cellspacing=3D"0" st=
        yle=3D"border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt=
        ;" width=3D"640">
        <tr>
        <td align=3D"center" height=3D"35" width=3D"640" style=3D"font-size:12px;li=
        ne-height:20px;color:#5e5e5e;font-family:Helvetica, Arial, sans-serif">Earn=
         EXTRA cash=E2=80=94details inside.<br /><a href=3D"http://mail.ebates.com/=
        T/v400000161de06f0e49f03a9f4bbe5bf30/4600e02524e44b450000021ef3a0bcc2/4600e=
        025-24e4-4b45-842f-b7f2e2eb7c81">Refer Now</a> | <a href=3D"http://mail.eba=
        tes.com/H/2/v400000161de06f0e49f03a9f4bbe5bf30/4600e025-24e4-4b45-842f-b7f2=
        e2eb7c81/HTML">Web Version</a>
        </td>
        </tr>
        =09<tr><td height=3D"8"></td></tr>


        <!--Top Nav-->

        <tr>
        <td align=3D"center">
        <table width=3D"640" bgcolor=3D"#FFFFFF" border=3D"0" cellpadding=3D"0" cel=
        lspacing=3D"0">

        <tr>
        <td align=3D"center">
        <table bgcolor=3D"#FFFFFF" border=3D"0" cellpadding=3D"0" cellspacing=3D"0"=
         style=3D"border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:=
        0pt;" width=3D"638">
        <tr>

        <td><a href=3D"http://mail.ebates.com/T/v400000161de06f0e49f03a9f4bbe5bf30/=
        4600e02524e44b450000021ef3a0bcc3/4600e025-24e4-4b45-842f-b7f2e2eb7c81"><img=
         border=3D"0"  src=3D"http://dreammail.edgesuite.net/PMB/Ebates/template/Lo=
        go@2x.png" style=3D"display:block;" width=3D"241"/></a></td>

        <td>
        <table border=3D"0" cellspacing=3D"0" cellpadding=3D"0" width=3D"397">
        =09<tr><td height=3D"54"></td></tr>=09
        =09<tr><td height=3D"14" align=3D"right" style=3D"padding-right:20px;font-f=
        amily:Proxima Nova, Helvetica, Arial, sans-serif;font-size:14px;color:#3333=
        33;font-weight:100;line-height:14px;"></td></tr>=09
        =09<tr><td height=3D"25"></td></tr>=09
        =09
        </table>=09
        </td>



        </tr>
        </table>
        </td></tr>

        <tr>
        <td>
        <img border=3D"0"  src=3D"http://dreammail.edgesuite.net/PMB/Ebates/templat=
        e/divider-640@2x.png" width=3D"638"/></td></tr>

        =09</table>
        </td>
        </tr>

        <!--End Nav/Begin Body-->
        <tr>
        <td align=3D"center">
        <table border=3D"0" cellspacing=3D"0" cellpadding=3D"0">
        =09
        <tr>
        <td align=3D"center" style=3D"font-size:0px;line-height:0px;" width=3D"640"=
        ><img src=3D"http://dreammail.edgesuite.net/PMB/Ebates/TAF/Q3-2016/20180214=
        _taf/slice001.gif" alt=3D"" width=3D"640" height=3D"427" border=3D"0" style=
        =3D"display:block;"/>
        </td>
        </tr>
        <tr>
        <td>
        <table border=3D"0" cellspacing=3D"0" cellpadding=3D"0">
        <tr>
        <td align=3D"center" style=3D"font-size:0px;line-height:0px;"><img src=3D"h=
        ttp://dreammail.edgesuite.net/PMB/Ebates/TAF/Q3-2016/20180214_taf/slice02.g=
        if" alt=3D"" width=3D"174" height=3D"37" border=3D"0" style=3D"display:bloc=
        k;"/>
        =09</td>
        =09
        =09
        =09
        =09<td bgcolor=3D"#FFFFFF" height=3D"37" width=3D"292" align=3D"center" sty=
        le=3D"font-size:12px;color:#000000;font-family:Arial,Helvetica,sans-serif;p=
        adding-right:6px;padding-left:6px"><a style=3D"text-decoration:none;text-un=
        derline:none;color:#000000;" href=3D"http://mail.ebates.com/T/v400000161de0=
        6f0e49f03a9f4bbe5bf30/4600e02524e44b450000021ef3a0bcc4/4600e025-24e4-4b45-8=
        42f-b7f2e2eb7c81">https://www.ebates.com/r/PEDROA274?eeid=3D39203</a></td>



        <td align=3D"center" style=3D"font-size:0px;line-height:0px;"><img src=3D"h=
        ttp://dreammail.edgesuite.net/PMB/Ebates/TAF/Q3-2016/20180214_taf/slice03.g=
        if" alt=3D"" width=3D"174" height=3D"37" border=3D"0" style=3D"display:bloc=
        k;"/>
        =09=09</td>
        =09</tr>
        =09</table>
        =09</td>
        =09</tr>
        <tr>
        <td align=3D"center" style=3D"font-size:0px;line-height:0px;" width=3D"640"=
        ><img src=3D"http://dreammail.edgesuite.net/PMB/Ebates/TAF/Q3-2016/20180214=
        _taf/slice04.gif" alt=3D"" width=3D"640" height=3D"468" border=3D"0" style=
        =3D"display:block;"/>
        </td>
        </tr>


        =09</table>
        =09</td>
        =09</tr>





        <tr>
        <td align=3D"center">
        <table border=3D"0" cellspacing=3D"0" cellpadding=3D"0" width=3D"640">

        <tr bgcolor=3D"#ebebeb" align=3D"left">
                 <td align=3D"left">
                   <table class=3D"bodyTable" width=3D"638" border=3D"0" cellspacin=
        g=3D"0" cellpadding=3D"0">
                     <tbody>
                       <tr>
                         <td bgcolor=3D"#ebebeb" width=3D"1" style=3D"font-size:0px=
        ;line-height:0px;"><img src=3D"http://dreammail.edgesuite.net/PMB/solos/x.g=
        if" border=3D"0" style=3D"display:block;" height=3D"1" width=3D"1" />
                           </td>
                         <td bgcolor=3D"#ebebeb">
                           <table class=3D"footerTable" border=3D"0" cellpadding=3D=
        "0" cellspacing=3D"0"  width=3D"638">
                             <tr>
                               <td style=3D"font-size:0px;line-height:0px;"><img sr=
        c=3D"http://dreammail.edgesuite.net/PMB/solos/x.gif" border=3D"0" style=3D"=
        display:block;" height=3D"30" width=3D"1" />
                                 </td>
                             </tr>
                             <tr>
                               <td align=3D"center">
                                 <table class=3D"footerTable" border=3D"0" cellpadd=
        ing=3D"0" cellspacing=3D"0" width=3D"638">
                                   <tr>
                                     <td style=3D"font-size:0px;line-height:0px;" w=
        idth=3D"29"><img src=3D"http://dreammail.edgesuite.net/PMB/solos/x.gif" bor=
        der=3D"0" style=3D"display:block;" height=3D"2" width=3D"29" />
                                       </td>
                                     <td align=3D"center" style=3D"font-family:Helv=
        etica, Arial, sans-serif;font-size:12px;line-height:15px;color:#999999;" wi=
        dth=3D"490"><a STYLE=3D"text-decoration:none;color:#999999;" href=3D"http:/=
        /mail.ebates.com/T/v400000161de06f0e49f03a9f4bbe5bf30/4600e02524e44b4500000=
        21ef3a0bcc5/4600e025-24e4-4b45-842f-b7f2e2eb7c81">MY ACCOUNT</a><span style=
        =3D"color:#cccccc;">&#160;&#160;&#160;|&#160;&#160;&#160;</span><a STYLE=3D=
        "text-decoration:none;color:#999999;" href=3D"http://mail.ebates.com/T/v400=
        000161de06f0e49f03a9f4bbe5bf30/4600e02524e44b450000021ef3a0bcc6/4600e025-24=
        e4-4b45-842f-b7f2e2eb7c81">HELP</a>
                                       </td>
                                     <td style=3D"font-size:0px;line-height:0px;" w=
        idth=3D"29"><img src=3D"http://dreammail.edgesuite.net/PMB/solos/x.gif" bor=
        der=3D"0" style=3D"display:block;" height=3D"2" width=3D"29" />
                                       </td>
                                     </tr>
                                   </table>
                                 </td>
                               </tr>
                             <tr>
                               <td style=3D"font-size:0px;line-height:0px;"><img sr=
        c=3D"http://dreammail.edgesuite.net/PMB/solos/x.gif" border=3D"0" style=3D"=
        display:block;" height=3D"20" width=3D"1" />
                                 </td>
                               </tr>
                             <tr>
                               <td align=3D"center">
                                 <table class=3D"footerTable" border=3D"0" cellpadd=
        ing=3D"0" cellspacing=3D"0" width=3D"638">
                                   <tr>
                                     <td style=3D"font-size:0px;line-height:0px;" w=
        idth=3D"29"><img src=3D"http://dreammail.edgesuite.net/PMB/solos/x.gif" bor=
        der=3D"0" style=3D"display:block;" height=3D"2" width=3D"29" />
                                       </td>
                                     <td align=3D"center" style=3D"font-family:Helv=
        etica, Arial, sans-serif;font-size:14px;line-height:20px;color:#999999;" wi=
        dth=3D"490">Prices, offers and Cash Back are subject to change. Restriction=
        s may apply. Your privacy is important to us. Please read our <a href=3D"ht=
        tp://mail.ebates.com/T/v400000161de06f0e49f03a9f4bbe5bf30/4600e02524e44b450=
        000021ef3a0bcc7/4600e025-24e4-4b45-842f-b7f2e2eb7c81" style=3D"color:#99999=
        9;">Privacy Policy</a>. To get the most relevant deals, <a href=3D"http://m=
        ail.ebates.com/T/v400000161de06f0e49f03a9f4bbe5bf30/4600e02524e44b450000021=
        ef3a0bcc8/4600e025-24e4-4b45-842f-b7f2e2eb7c81" style=3D"color:#999999;">ad=
        d your favorite stores</a>. If you no longer wish to receive promotional em=
        ails, please <a href=3D"http://mail.ebates.com/T/v400000161de06f0e49f03a9f4=
        bbe5bf30/4600e02524e44b450000021ef3a0bcc9/4600e025-24e4-4b45-842f-b7f2e2eb7=
        c81" style=3D"color:#999999;">unsubscribe here</a>.
                                       </td>
                                     <td style=3D"font-size:0px;line-height:0px;" w=
        idth=3D"29"><img src=3D"http://dreammail.edgesuite.net/PMB/solos/x.gif" bor=
        der=3D"0" style=3D"display:block;" height=3D"2" width=3D"29" />
                                       </td>
                                     </tr>
                                   </table>
                                 </td>
                               </tr>
                             <tr>
                               <td style=3D"font-size:0px;line-height:0px;"><img sr=
        c=3D"http://dreammail.edgesuite.net/PMB/solos/x.gif" border=3D"0" style=3D"=
        display:block;" height=3D"20" width=3D"1" />
                                 </td>
                               </tr>
                             <tr>
                               <td align=3D"center">
                                 <table class=3D"footerTable" border=3D"0" cellpadd=
        ing=3D"0" cellspacing=3D"0" width=3D"638">
                                   <tr>
                                     <td style=3D"font-size:0px;line-height:0px;" w=
        idth=3D"29"><img src=3D"http://dreammail.edgesuite.net/PMB/solos/x.gif" bor=
        der=3D"0" style=3D"display:block;" height=3D"2" width=3D"29" />
                                       </td>
                                   <td align=3D"center" style=3D"font-family:Helvet=
        ica, Arial, sans-serif;font-size:14px;line-height:20px;color:#999999;" widt=
        h=3D"660">&copy; 2018 Ebates Inc., 160 Spear St., 19th Fl., San Francisco, =
        CA 94105
        </td>
                                     <td style=3D"font-size:0px;line-height:0px;" w=
        idth=3D"29"><img src=3D"http://dreammail.edgesuite.net/PMB/solos/x.gif" bor=
        der=3D"0" style=3D"display:block;" height=3D"2" width=3D"29" />
                                       </td>
                                     </tr>
                                   </table>
                                 </td>
                               </tr>
                             <tr>
                               <td style=3D"font-size:0px;line-height:0px;"><img sr=
        c=3D"http://dreammail.edgesuite.net/PMB/solos/x.gif" border=3D"0" style=3D"=
        display:block;" height=3D"30" width=3D"1" />
                                 </td>
                               </tr>
                             </table>
                           </td>
                         <td bgcolor=3D"#ebebeb" width=3D"1" style=3D"font-size:0px=
        ;line-height:0px;"><img src=3D"http://dreammail.edgesuite.net/PMB/solos/x.g=
        if" border=3D"0" style=3D"display:block;" height=3D"1" width=3D"1" />
                           </td>
                         </tr>
                       <tr>
                         <td colspan=3D"3" bgcolor=3D"#ebebeb" width=3D"1" style=3D=
        "font-size:0px;line-height:0px;"><img src=3D"http://dreammail.edgesuite.net=
        /PMB/solos/x.gif" border=3D"0" style=3D"display:block;" height=3D"1" width=
        =3D"1" />
                           </td>
                         </tr>
                       </tbody></table>
                   </td>
                 </tr>






        </table>
        </td></tr>

         =20

        <!--End Body/Begin Footer-->
        <tr>
          <td class=3D"zoomFix" height=3D"1" style=3D"font-size:0px;line-height:0px=
        "><img class=3D"zoomFix" src=3D"http://dreammail.edgesuite.net/PMB/solos/x.=
        gif" width=3D"1" height=3D"1" border=3D"0" style=3D"display:block"/>
          </td>
        </tr>
        <!--End Footer-->

        </table>

        <!--End Inner Table-->


        </td>
        </tr>
        </table>

        <!--End Wrapper Table-->

        <div style=3D"display:none; white-space:nowrap; font-size:15px; color:#ffff=
        ff;line-height:0px">
        - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -=
         -
        </div>

        <img src=3D'http://mail.ebates.com/O/v400000161de06f0e49f03a9f4bbe5bf30/460=
        0e02524e44b4500004c5a42963aa1' style=3D"display:none; max-height: 0px; font=
        -size: 0px; overflow: hidden; mso-hide: all"/></body>
        </html>
        """ + Constants.htmlBottomWrapper
}
