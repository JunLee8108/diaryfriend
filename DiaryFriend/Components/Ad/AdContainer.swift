//
//  AdContainer.swift
//  DiaryFriend
//
//  Conditionally renders a BannerAdView based on AdManager.shouldShowAds.
//  Hidden for premium users, pre-init state, or non-consented users.
//

import SwiftUI
import GoogleMobileAds
import UIKit

struct AdContainer: View {
    let unitID: String

    @ObservedObject private var adManager = AdManager.shared
    @ObservedObject private var profileStore = UserProfileStore.shared

    var body: some View {
        Group {
            if adManager.shouldShowAds {
                // ⭐ Inline Adaptive Banner (maxHeight AdManager.maxBannerHeight) 사용.
                // Anchored 와 달리 광고 크리에이티브 크기에 맞춰 height가 가변이라
                // 큰 광고도 잘리지 않고 완전히 표시된다.
                GeometryReader { geo in
                    let adSize = inlineAdaptiveBanner(width: geo.size.width, maxHeight: AdManager.maxBannerHeight)
                    BannerAdView(unitID: unitID, width: geo.size.width)
                        .frame(width: geo.size.width, height: adSize.size.height)
                        .clipped()  // 최후 안전망: frame 밖 픽셀이 새어 나오지 않도록
                }
                .frame(height: fallbackBannerHeight)
            } else {
                EmptyView()
            }
        }
    }

    /// GeometryReader가 layout 전에 container 높이를 reserve해야 하므로
    /// UIScreen 기반 fallback으로 approximate height를 계산.
    /// 실제 렌더 시에는 GeometryReader 안의 adSize.size.height가 사용된다.
    private var fallbackBannerHeight: CGFloat {
        let width = UIScreen.main.bounds.width
        return inlineAdaptiveBanner(width: width, maxHeight: AdManager.maxBannerHeight).size.height
    }
}
