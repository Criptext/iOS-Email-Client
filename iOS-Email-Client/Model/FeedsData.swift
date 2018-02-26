//
//  FeedsData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class FeedsData{
    var oldFeeds: [Feed] = []
    var newFeeds: [Feed] = []
    var loadingFeeds = false
    var reachedEnd = false
    
    func mockFeeds(){
        let feed1 = Feed()
        feed1.message = "Daniel Tigse downloaded:"
        feed1.subject = "This is it.pdf"
        feed1.timestamp = 1519319708
        newFeeds.append(feed1)
        let feed2 = Feed()
        feed2.message = "Erika Perugachi opened:"
        feed2.subject = "RE: Pending report"
        feed2.timestamp = 1519233308
        feed2.isOpen = true
        feed2.isNew = true
        newFeeds.append(feed2)
        let feed3 = Feed()
        feed3.message = "Brian Cave opened:"
        feed3.subject = "RE: Pending report"
        feed3.timestamp = 1519146908
        feed3.isOpen = true
        newFeeds.append(feed3)
        let feed4 = Feed()
        feed4.message = "Pedri downloaded:"
        feed4.subject = "This is it 2.pdf"
        feed4.timestamp = 1519060508
        feed4.isNew = true
        newFeeds.append(feed4)
        let feed5 = Feed()
        feed5.message = "Gianni con u ntexto suuuper largo infinito opened:"
        feed5.subject = "Yaaaaaaasssss"
        feed5.timestamp = 1518974108
        feed5.isOpen = true
        newFeeds.append(feed5)
        let feed6 = Feed()
        feed6.message = "Peperepe opened:"
        feed6.subject = "Subject con un texto super largo hasta el infinito"
        feed6.timestamp = 1518887708
        feed6.isOpen = true
        newFeeds.append(feed6)
    }
    
    func mockFeeds2(){
        let feed1 = Feed()
        feed1.message = "Daniel Tigse downloaded:"
        feed1.subject = "This is it.pdf"
        feed1.timestamp = 1519319708
        oldFeeds.append(feed1)
        let feed2 = Feed()
        feed2.message = "Erika Perugachi opened:"
        feed2.subject = "RE: Pending report"
        feed2.timestamp = 1519233308
        feed2.isOpen = true
        feed2.isNew = true
        oldFeeds.append(feed2)
        let feed3 = Feed()
        feed3.message = "Brian Cave opened:"
        feed3.subject = "RE: Pending report"
        feed3.timestamp = 1519146908
        feed3.isOpen = true
        oldFeeds.append(feed3)
        let feed4 = Feed()
        feed4.message = "Pedri downloaded:"
        feed4.subject = "This is it 2.pdf"
        feed4.timestamp = 1519060508
        feed4.isNew = true
        oldFeeds.append(feed4)
        let feed5 = Feed()
        feed5.message = "Gianni con u ntexto suuuper largo infinito opened:"
        feed5.subject = "Yaaaaaaasssss"
        feed5.timestamp = 1518974108
        feed5.isOpen = true
        oldFeeds.append(feed5)
        let feed6 = Feed()
        feed6.message = "Peperepe opened:"
        feed6.subject = "Subject con un texto super largo hasta el infinito"
        feed6.timestamp = 1518887708
        feed6.isOpen = true
        oldFeeds.append(feed6)
    }
}
