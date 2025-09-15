//
//  Item.swift
//  DiaryFriend
//
//  Created by Jun Lee on 9/15/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
