//
//  AdContainer.swift
//  DiaryFriend
//
//  Conditionally renders a BannerAdView based on AdManager.shouldShowAds.
//  Hidden for premium users, pre-init state, or non-consented users.
//

import SwiftUI

struct AdContainer: View {
    let unitID: String

    @ObservedObject private var adManager = AdManager.shared
    @ObservedObject private var profileStore = UserProfileStore.shared

    var body: some View {
        Group {
            if adManager.shouldShowAds {
                BannerAdView(unitID: unitID)
                    .frame(height: 50)  // adaptive banner는 ~50-80pt 사이, 최소 보장
                    .frame(maxWidth: .infinity)
            } else {
                EmptyView()
            }
        }
    }
}
