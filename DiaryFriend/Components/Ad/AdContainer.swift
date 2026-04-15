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
                // ⭐ GeometryReader로 실제 container width를 측정.
                // AdMob SDK가 해당 width에 맞는 정확한 adaptive banner height를
                // 반환하므로 하드코딩된 50 대신 그걸 사용해서 UIView의 intrinsic
                // size와 SwiftUI frame을 완벽히 일치시킨다 (overflow 원천 차단).
                GeometryReader { geo in
                    let adSize = currentOrientationAnchoredAdaptiveBanner(width: geo.size.width)
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
        return currentOrientationAnchoredAdaptiveBanner(width: width).size.height
    }
}
