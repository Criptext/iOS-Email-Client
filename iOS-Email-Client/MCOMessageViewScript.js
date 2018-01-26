
var imageElements = function() {
	var imageNodes = document.getElementsByTagName('img');
	return [].slice.call(imageNodes);
}

var findCIDImageURL = function() {
	var images = imageElements();
	
	var imgLinks = [];
	for (var i = 0; i < images.length; i++) {
		var url = images[i].getAttribute('src');
		if (url.indexOf('cid:') == 0 || url.indexOf('x-mailcore-image:') == 0)
			imgLinks.push(url);
	}
	return JSON.stringify(imgLinks);
}

var replaceImageSrc = function(info) {
	var images = imageElements();
	
	for (var i = 0; i < images.length; i++) {
		var url = images[i].getAttribute('src');
		if (url.indexOf(info.URLKey) == 0) {
			images[i].setAttribute('src', info.LocalPathKey);
			break;
		}
	}
}

var preElements = function() {
    var preNodes = document.getElementsByTagName('pre');
    return [].slice.call(preNodes);
}

var getCriptextToken = function() {
    var preTags = preElements();
    
    var token = preTags[0].innerHTML;

    return token;
}

var urlify = function() {
    var urlRegex = /(=")?(http(s)?:\/\/.)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)(<\/a>)?/g;
    
    return document.documentElement.outerHTML.replace(urlRegex, function(url) {
                                                      if(url.indexOf('="') > -1 ||
                                                         url.indexOf('.length') > -1 ||
                                                         url.indexOf('.push') > -1 ||
                                                         url.indexOf('.slice.call') > -1){
                                                        return url
                                                      }
                                                      
                                                      var trueUrl = url
                                                      if(trueUrl.indexOf('http') == -1){
                                                        trueUrl = "https://"+url
                                                      }
                                                      return '<a href="' + trueUrl + '" target="_blank">' + url + '</a>';
                        });
}
                     

