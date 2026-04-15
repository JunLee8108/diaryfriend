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
                // ⭐ GeometryReader로 실제 container width를 측정해서 BannerAdView에
                // 주입. UIScreen.main 의존을 제거하고 UIView의 intrinsic size를
                // SwiftUI frame으로 강제 제약해 overflow를 원천 차단한다.
                GeometryReader { geo in
                    BannerAdView(unitID: unitID, width: geo.size.width)
                        .frame(width: geo.size.width, height: 50)
                }
                .frame(height: 50)  // adaptive banner는 ~50-80pt, 최소 보장
            } else {
                EmptyView()
            }
        }
    }
}
