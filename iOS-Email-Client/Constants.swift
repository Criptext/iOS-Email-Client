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
    static let domain = Env.domain
    static let maxPreviewSize = 100
    
    static let basePopoverHeight = 102
    static let labelPopoverHeight = 48
    
    static let footer = "<br/><br/><br/><span>Sent with <a style=\"color:#0091ff;text-decoration: none;\" href=\"https://goo.gl/qW4Aks\">Criptext</a> secure email</span>"
    
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
    
    static let htmlTopWrapper = "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\" \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" +
    "<html xmlns=\"http://www.w3.org/1999/xhtml\" style=\"height: auto !important\">" +
    " <head>" +
    "  <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">" +
    "  <meta name=\"viewport\" content=\"width=device-width\">" +
    "    <style type='text/css'>html, body { margin: 0px; padding: 0px; }</style>" +
    "    <style type='text/css'>" +
    "      @font-face { font-family: 'NunitoSans'; src: url('Fonts/NunitoSans-Regular.ttf')}" +
    "      body { font-family: 'NunitoSans', sans-serif}" +
    "    </style>" +
    " </head>" +
    " <body style=\"height: auto !important\">"
    
    static let htmlBottomWrapper = "</body><script>\(quoteHideScript)</script></html>"
    
    static let imagePath = Bundle.main.path(forResource: "showmore.png", ofType: nil) ?? ""
    
    static let quoteHideScript = "var replybody = document.getElementsByClassName(\"criptext_quote\")[0] ||document.getElementsByClassName(\"gmail_quote\")[0] || document.getElementById(\"criptext_quote\") || document.getElementsByTagName(\"blockquote\")[0];" +
        "var newNode = document.createElement(\"img\");" +
        "newNode.src = \"file://\(imagePath)\";" +
        "newNode.width = 30;" +
        "newNode.style.paddingTop = \"10px\";" +
        "newNode.style.paddingBottom = \"10px\";" +
        "replybody.style.display = \"none\";" +
        "replybody.parentElement.insertBefore(newNode, replybody);" +
        "newNode.addEventListener(\"click\", function(){ if(replybody.style.display == \"block\"){ " +
        "replybody.style.display = \"none\";} else {" +
        "replybody.style.display = \"block\";} window.webkit.messageHandlers.iosListener.postMessage('heightChange'); });"
    
    static let fullScript = "<html><head><style type='text/css'>body{ font-family: 'Helvetica Neue', Helvetica, Arial; margin:0; padding: 0px 30px;} hr {border: 0; height: 1px; background-color: #bdc3c7;}.show { display: block;}.hide:target + .show { display: inline;} .hide:target { display: block;} .content { display:block;} .hide:target ~ .content { display:inline;} </style></head><body></body><iframe src='x-mailcore-msgviewloaded:' style='width: 0px; height: 0px; border: none;'></iframe><script>\(quoteHideScript)</script></html>"


    static let popoverWidth = 270
    static let singleTextPopoverHeight = 178
}
