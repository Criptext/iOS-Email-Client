//
//  PreviewItem.swift
//  Criptext Secure Email
//
//  Created by Gianni Carlo on 5/3/17.
//  Copyright © 2017 Criptext Inc. All rights reserved.
//

import Foundation
import QuickLook

class PreviewItem: NSObject, QLPreviewItem {
    var previewItemURL: URL?
    var previewItemTitle: String?
}
