//
//  AppStoreReviewManager.swift
//  iOS-Email-Client
//
//  Created by Eshwar Ramesh on 9/29/19.
//  Copyright © 2019 Criptext Inc. All rights reserved.
//

import Foundation
import StoreKit

enum AppStoreReviewManager {
    static let minimumReviewWorthyActionCount = 5

    static func requestReviewIfAppropriate(viewController: UIViewController) {
        let defaults = UserDefaults.standard
        let bundle = Bundle.main

        var actionCount = defaults.integer(forKey: UserDefaultsKeys.reviewWorthyActionCount)
        actionCount += 1
        defaults.set(actionCount, forKey: UserDefaultsKeys.reviewWorthyActionCount)

        guard actionCount >= minimumReviewWorthyActionCount else {
            return
        }

        let bundleVersionKey = kCFBundleVersionKey as String
        let currentVersion = bundle.object(forInfoDictionaryKey: bundleVersionKey) as? String
        let lastVersion = defaults.string(forKey: UserDefaultsKeys.lastVersionPromptedForReviewKey)

        guard lastVersion == nil || lastVersion != currentVersion else {
            return
        }
        
        if viewController.navigationController?.topViewController is InboxViewController {
            SKStoreReviewController.requestReview()
        }

        defaults.set(0, forKey: UserDefaultsKeys.reviewWorthyActionCount)
        defaults.set(currentVersion, forKey: UserDefaultsKeys.lastVersionPromptedForReviewKey)
    }
}

