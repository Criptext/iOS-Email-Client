//
//  FeedsData.swift
//  iOS-Email-Client
//
//  Created by Pedro Aim on 2/22/18.
//  Copyright © 2018 Criptext Inc. All rights reserved.
//

import Foundation
import RealmSwift

class FeedsData{
    var oldFeeds: Results<FeedItem>!
    var newFeeds: Results<FeedItem>!
    var lastSeen = Date()
}
