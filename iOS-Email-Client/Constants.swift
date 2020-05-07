//
//  Constants.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/16/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

struct Constants {
    static let MinCharactersPassword = 8
    static let maxPreviewSize = 100
    
    static let basePopoverHeight = 102
    static let labelPopoverHeight = 48
    
    static let footer = "<br/><br/><br/><span><i>Sent with Criptext secure email</i></span>"
    
    static let unsendEmail = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" +
        "<html xmlns=\"http://www.w3.org/1999/xhtml\">" +
        " <head>" +
        "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">" +
        "  <meta name=\"viewport\" content=\"width=device-width,user-scalable=yes\">" +
        " </head>" +
        " <body>" +
        "  <style>  @media only screen and (max-width: 600px) {    td[class=\"pattern\"] td{ width: 100% !important;}td[class=\"hero\"] img { width: 100%; height: auto !important; } td[class=\"hero\"] { width: 100% !important; height: auto !important;}td[class=\"minilogo\"] img{ width: 180px; height: auto !important; text-align: center; }  } iframe#alive + div#rendered {display:none !important;}</style>" +
        "  <div>" +
        "   <table cellpadding=\"0\" cellspacing=\"0\" border=\"0\"> " +
        "    <tbody>" +
        "     <tr> " +
        "      <td class=\"pattern\" width=\"600\">    " +
        "       <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"> <script src=\"https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js\"></script> <style type=\"text/css\">" +
        "    body{" +
        "      font-family: arial,sans-serif;" +
        "    }" +
        "    .myframenew{" +
        "      width: 100% !important;" +
        "      height: auto !important;" +
        "      word-wrap: break-word;" +
        "    }" +
        "    @media screen and (max-width: 750px) {" +
        "      img{" +
        "        max-width: 680px !important;" +
        "      }" +
        "    }" +
        "    @media screen and (max-width: 500px) {" +
        "      img{" +
        "        max-width: 375px !important;" +
        "      }" +
        "    }" +
        "    img{" +
        "      max-width: 800px;" +
        "      height: auto;" +
        "    }" +
        "  </style> <script type=\"text/javascript\">" +
        "    $(document).ready(function(){" +
        "      for(var i=0;i<$(\"img\").length;i++){" +
        "        //$($(\"img\")[i]).attr(\"width\",\"auto\");" +
        "        //$($(\"img\")[i]).attr(\"height\",\"auto\");" +
        "      }" +
        "    });" +
        "  </script>   " +
        "       <div> " +
        "        <a style=\"color: #ccc; font-style: italic;\">The content is no longer available</a> " +
        "       </div>   </td>" +
        "     </tr>" +
        "    </tbody>" +
        "   </table>" +
        "  </div>" +
        "  <div style=\"font-size:0em\">" +
        "   <pre style=\"color:white;display:none;\">5oe7b8oqjjbxogvij55kbi1bgj8xgc6n2dg6i529</pre>" +
        "  </div>" +
        "  <div style=\"font-size:0em\"></div>" +
        "  <div></div>" +
        "  <div></div>" +
        " </body>" +
        "</html><html><head><script>" +
        "var imageElements = function() {" +
        "var imageNodes = document.getElementsByTagName('img');" +
        "return [].slice.call(imageNodes);" +
        "}" +
        "var findCIDImageURL = function() {" +
        "var images = imageElements();" +
        "" +
        "var imgLinks = [];" +
        "for (var i = 0; i < images.length; i++) {" +
        "var url = images[i].getAttribute('src');" +
        "if (url.indexOf('cid:') == 0 || url.indexOf('x-mailcore-image:') == 0)" +
        "imgLinks.push(url);" +
        "}" +
        "return JSON.stringify(imgLinks);" +
        "}" +
        "var replaceImageSrc = function(info) {" +
        "var images = imageElements();" +
        "" +
        "for (var i = 0; i < images.length; i++) {" +
        "var url = images[i].getAttribute('src');" +
        "if (url.indexOf(info.URLKey) == 0) {" +
        "images[i].setAttribute('src', info.LocalPathKey);" +
        "break;" +
        "}" +
        "}" +
        "}" +
        "var preElements = function() {" +
        "var preNodes = document.getElementsByTagName('pre');" +
        "return [].slice.call(preNodes);" +
        "}" +
        "var getCriptextToken = function() {" +
        "var preTags = preElements();" +
        "    " +
        "    var token = preTags[0].innerHTML;" +
        "    return token;" +
        "}" +
        "var urlify = function() {" +
        "    var urlRegex = /(=\")?(http(s)?:\\/\\/.)?(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{2,256}\\.[a-z]{2,6}\\b([-a-zA-Z0-9@:%_\\+.~#?&\\/\\/=]*)(<\\/a>)?/g;" +
        "    " +
        "    return document.documentElement.outerHTML.replace(urlRegex, function(url) {" +
        "                                                      if(url.indexOf('=\"') > -1 ||" +
        "                                                         url.indexOf('.length') > -1 ||" +
        "                                                         url.indexOf('.push') > -1 ||" +
        "                                                         url.indexOf('.slice.call') > -1){" +
        "                                                        return url" +
        "                                                      }" +
        "                                                      " +
        "                                                      var trueUrl = url" +
        "                                                      if(trueUrl.indexOf('http') == -1){" +
        "                                                        trueUrl = \"https://\"+url" +
        "                                                      }" +
        "                                                      return '<a href=\"' + trueUrl + '\" target=\"_blank\">' + url + '</a>';" +
        "                        });" +
        "}" +
        "                     " +
    "</script><style type='text/css'>body{ font-family: 'Helvetica Neue', Helvetica, Arial; margin:0; padding:30px;} hr {border: 0; height: 1px; background-color: #bdc3c7;}.show { display: block;}.hide:target + .show { display: inline;} .hide:target { display: block;} .content { display:block;} .hide:target ~ .content { display:inline;} </style></head><body></body><iframe src='x-mailcore-msgviewloaded:' style='width: 0px; height: 0px; border: none;'></iframe><script>var replybody = document.getElementsByTagName(\"blockquote\")[0].parentElement;var newNode = document.createElement(\"img\");newNode.src = \"file:///var/containers/Bundle/Application/B6B86B64-73F7-4B6F-9563-571BC2623208/Criptext Secure Email.app/showmore.png\";newNode.width = 30;newNode.style.paddingTop = \"10px\";newNode.style.paddingBottom = \"10px\";replybody.style.display = \"none\";replybody.parentElement.insertBefore(newNode, replybody);newNode.addEventListener(\"click\", function(){ if(replybody.style.display == \"block\"){ replybody.style.display = \"none\";} else {replybody.style.display = \"block\";} window.location.href = \"inapp://heightUpdate\";});</script></html>"
    
    static func htmlTopWrapper(bgColor: String, color: String, anchorColor: String) -> String {
        return "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" +
            "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"height: auto !important\">" +
            " <head>" +
            "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">" +
            "  <meta name=\"viewport\" content=\"width=device-width\">" +
            "    <style type='text/css'>html { background: #\(bgColor) !important; color: #\(color) !important; margin: 0px 24px 0px 18px; padding: 0px; }</style>" +
            "    <style type='text/css'>" +
            "      @font-face { font-family: 'NunitoSans'; src: url('Fonts/NunitoSans-Regular.ttf')}" +
            "      body { background: #\(bgColor) !important; color: #\(color) !important; margin: 0px; padding: 0px; font-family: 'NunitoSans', sans-serif} a { color: #\(anchorColor) }" +
            "    </style>" +
            " </head>" +
            " <body style=\"height: auto !important\">"
    }
    
    static let imagePath = Bundle.main.path(forResource: "showmore.png", ofType: nil) ?? ""
    
    static let darkPath = Bundle.main.path(forResource: "dark-showmore.png", ofType: nil) ?? ""
    
    static let imageExpandedPath = Bundle.main.path(forResource: "showmore-light-opened.png", ofType: nil) ?? ""
    
    static let darkExpandedPath = Bundle.main.path(forResource: "showmore-dark-opened.png", ofType: nil) ?? ""
    
    static func quoteScript(theme: String, isFwd: Bool) -> String {
        let expandedPath = theme == "Dark" ? darkExpandedPath : imageExpandedPath
        let path = theme == "Dark" ? darkPath : imagePath
        let initialDisplay = isFwd ? "block" : "none"
        let initialPath = isFwd ? expandedPath : path
        
        let script = "var replybody = document.getElementsByClassName(\"criptext_quote\")[0] ||document.getElementsByClassName(\"gmail_quote\")[0] || document.getElementById(\"criptext_quote\") || document.getElementsByTagName(\"blockquote\")[0];" +
            "var newNode = document.createElement(\"img\");" +
            "newNode.src = \"file://\(initialPath)\";" +
            "newNode.width = 30;" +
            "newNode.id = \"criptext_more_button\";" +
            "newNode.style.paddingTop = \"10px\";" +
            "newNode.style.paddingBottom = \"10px\";" +
            "replybody.style.display = \"\(initialDisplay)\";" +
            "replybody.parentElement.insertBefore(newNode, replybody);" +
            "newNode.addEventListener(\"click\", function(){ if(replybody.style.display == \"block\"){ " +
            "newNode.src = \"file://\(path)\";" +
            "replybody.style.display = \"none\";} else {" +
            "replybody.style.display = \"block\";" +
            "newNode.src = \"file://\(expandedPath)\";" +
        "} window.webkit.messageHandlers.iosListener.postMessage('heightChange'); });"
        
        let reloadImages = """

        function replaceSrc()
        {
            var images = document.getElementsByTagName('img');
            for(var i = 0; i < images.length; i++)
            {
                var dt = new Date();
                var img = images[i];
                if(img.src.length >= 0)
                {
                    img.src = img.src + "";
                }
            }
        }
        """
        
        return "</body><script>\(script)\(reloadImages)</script></html>"
    }
    
    static func singleEmail (image: String, subject: String, contact: String, completeDate: String,
                             contacts: String, content: String) -> String{
        return "<html><head><meta name=\"viewport\"  content=\"width=device-width, initial-scale=1, maximum-scale=1\"/><style> " +
        " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Heavy.otf) format(\"opentype\");font-weight:900;font-style:normal} " +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Heavy+Italic.otf) format();font-weight:900;font-style:italic} " +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Bold.otf) format(\"opentype\");font-weight:800;font-style:normal}" +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Bold+Italic.otf) format(\"opentype\");font-weight:800;font-style:italic}" +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Demi+Bold.otf) format(\"opentype\");font-weight:700;font-style:normal}" +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Demi+Bold+Italic.otf) format(\"opentype\");font-weight:700;font-style:italic}" +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Medium.otf) format(\"opentype\");font-weight:600;font-style:normal}" +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Medium+Italic.otf) format(\"opentype\");font-weight:600;font-style:italic}" +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Regular.otf) format(\"opentype\");font-weight:400;font-style:normal}" +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Italic.otf) format(\"opentype\");font-weight:400;font-style:italic}" +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Ultra+Light.otf) format(\"opentype\");font-weight:300;font-style:normal}" +
           " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Ultra+Light+Italic.otf) format(\"opentype\");font-weight:300;font-style:italic}" +
            "* {" +
            "font-family: 'Avenir Next';" +
            "font-size: 11px;" +
            "};" +
            "</style></head>" +
            "<body>" +
            " <div><img src=\"data:image/png;base64, \(image)\"  alt=\"Criptext Logo\" style=\" width=3% !important; height=1% !important \"></div>" +
            "<hr>" +
            "<div><p><b>\(subject)</b></br></p></div>" +
            "<div><p>1 \(String.localize("MESSAGE"))</br></p></div>" +
            "<hr>" +
            "\(Constants.bodyEmail(contact: contact, completeDate: completeDate, contacts: contacts, content: content))" +
        "</body></html>"
    }
    
    static func bodyEmail(contact: String, completeDate: String,
                          contacts: String, content: String) -> String {
        return "<table style=\"width:100%\">\n" +
            "  <td><b>\(contact)</b></td>\n" +
            "    <td style=\"text-align:right\">\(completeDate)</td>\n" +
            "  </tr>\n" +
            "  <tr>\n" +
            "    <td>\(String.localize("TO")): \(contacts)</td>\n" +
            "  </tr>\n </table> <br>" +
        " \(content)"
    }
    
    static func threadEmail (image: String, subject: String, body: String, messages: String) -> String{
        return "<html><head><meta name=\"viewport\"  content=\"width=device-width, initial-scale=1, maximum-scale=1\"/><style> " +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Heavy.otf) format(\"opentype\");font-weight:900;font-style:normal} " +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Heavy+Italic.otf) format();font-weight:900;font-style:italic} " +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Bold.otf) format(\"opentype\");font-weight:800;font-style:normal}" +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Bold+Italic.otf) format(\"opentype\");font-weight:800;font-style:italic}" +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Demi+Bold.otf) format(\"opentype\");font-weight:700;font-style:normal}" +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Demi+Bold+Italic.otf) format(\"opentype\");font-weight:700;font-style:italic}" +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Medium.otf) format(\"opentype\");font-weight:600;font-style:normal}" +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Medium+Italic.otf) format(\"opentype\");font-weight:600;font-style:italic}" +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Regular.otf) format(\"opentype\");font-weight:400;font-style:normal}" +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Italic.otf) format(\"opentype\");font-weight:400;font-style:italic}" +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Ultra+Light.otf) format(\"opentype\");font-weight:300;font-style:normal}" +
            " @font-face{font-family:Avenir Next;src:url(https://cdn.criptext.com/Criptext-Email-Website/fonts/Avenir+Next+Ultra+Light+Italic.otf) format(\"opentype\");font-weight:300;font-style:italic}" +
            "* {" +
            "font-family: 'Avenir Next';" +
            "font-size: 11px;" +
            "};" +
            "</style></head>" +
            "<body>" +
            " <div><img src=\"data:image/png;base64, \(image)\" alt=\"Criptext Logo\" style=\" width=3% !important; height=1% !important \"></div>" +
            "<hr>" +
            "<div><p><b>\(subject)</b></br></p></div>" +
            "<div><p>\(messages)</br></p></div>" +
            "<hr>" +
            " \(body) " +
        "</body></html>"
    }
    
    static func contentUnsent(_ content: String) -> String {
        return "<span style=\"color:#eea3a3; font-style: italic;\">\(content)</span>"
    }
    
    static let contentEmpty = "<i style=\"color:#ccc;\">\(String.localize("NO_CONTENT"))</i>"
    
    static let popoverWidth = 270
    static let singleTextPopoverHeight = 178
    
    static let enterprise = 2
    static func isPlus(customerType: Int) -> Bool {
        return (customerType > 0 && customerType < 3)
    }
}
