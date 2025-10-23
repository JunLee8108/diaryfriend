//
//  Localized.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/21/25.
//

import SwiftUI

@propertyWrapper
struct Localized: DynamicProperty {
    @ObservedObject private var localization = LocalizationManager.shared
    let key: LocalizationKey
    
    var wrappedValue: String {
        localization.localized(key)
    }
    
    init(_ key: LocalizationKey) {
        self.key = key
    }
}
