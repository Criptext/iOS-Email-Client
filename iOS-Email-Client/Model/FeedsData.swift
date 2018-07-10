//
//  FeedsData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation

class FeedsData{
    var oldFeeds: [FeedItem] = []
    var newFeeds: [FeedItem] = []
    var lastSeen = Date()
    var loadingFeeds = false
    var reachedEnd = false
}
