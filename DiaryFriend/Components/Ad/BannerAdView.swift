//
//  BannerAdView.swift
//  DiaryFriend
//
//  SwiftUI wrapper around GoogleMobileAds.BannerView with an adaptive
//  anchored ad size so the banner height matches the current screen width.
//

import SwiftUI
import GoogleMobileAds
import UIKit

struct BannerAdView: UIViewRepresentable {
    let unitID: String
    /// 실제 렌더되는 컨테이너 width. AdContainer가 GeometryReader로 측정해서
    /// 주입한다. UIScreen.main에 의존하지 않아 Scene/기기별 편차로 인한
    /// overflow를 원천 차단한다.
    let width: CGFloat

    // ⭐ AdManager의 싱글톤 캐시에서 공유 BannerView를 가져와서 재사용한다.
    // LazyVStack이 AdContainer를 release/recreate해도 BannerView 인스턴스는
    // 앱 세션 동안 하나만 존재 → 광고 크리에이티브 누적으로 인한 OOM 방지.
    func makeUIView(context: Context) -> BannerView {
        AdManager.shared.bannerView(for: unitID, width: width)
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        // 회전/사이즈 변경 시 갱신 (대부분 no-op). AdManager와 동일한 inline
        // adaptive API를 사용해 size 일관성을 유지한다.
        let expected = inlineAdaptiveBanner(width: width, maxHeight: AdManager.maxBannerHeight)
        if uiView.adSize.size != expected.size {
            uiView.adSize = expected
            uiView.load(Request())
        }
    }

    // ⭐ BannerView 자체는 AdManager가 보관하므로 인스턴스는 파괴하지 않는다.
    // 현재 SwiftUI host에서만 분리해서 다음 makeUIView 호출 시 새 host에
    // 문제없이 add될 수 있도록 superview만 정리한다.
    static func dismantleUIView(_ uiView: BannerView, coordinator: ()) {
        uiView.removeFromSuperview()
    }
}
