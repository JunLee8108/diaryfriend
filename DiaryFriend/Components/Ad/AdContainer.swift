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

    /// BannerViewDelegate 콜백으로 받은 실제 서빙된 광고 크기.
    /// 광고 로드 전/실패 시에는 .zero → fallback height 사용.
    @State private var actualAdSize: CGSize = .zero

    var body: some View {
        Group {
            if adManager.shouldShowAds {
                // ⭐ Google 공식 패턴: UIView wrapper + clipsToBounds + BannerViewDelegate
                // wrapper가 UIKit 레벨에서 overflow를 차단하고, delegate로 받은
                // 실제 ad size로 container를 정확히 맞춘다.
                GeometryReader { geo in
                    BannerAdView(
                        unitID: unitID,
                        width: geo.size.width,
                        onAdSizeChanged: { size in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                actualAdSize = size
                            }
                        }
                    )
                    .frame(width: geo.size.width, height: containerHeight(for: geo.size.width))
                }
                .frame(height: containerHeight(for: UIScreen.main.bounds.width))
            } else {
                EmptyView()
            }
        }
    }

    /// 광고가 로드됐으면 실제 서빙 높이, 아니면 inline adaptive fallback.
    private func containerHeight(for width: CGFloat) -> CGFloat {
        if actualAdSize.height > 0 {
            return actualAdSize.height
        }
        return inlineAdaptiveBanner(width: width, maxHeight: AdManager.maxBannerHeight).size.height
    }
}
