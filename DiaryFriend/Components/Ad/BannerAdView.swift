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

    func makeUIView(context: Context) -> BannerView {
        let width = availableWidth()
        let adSize = currentOrientationAnchoredAdaptiveBanner(width: width)

        let banner = BannerView(adSize: adSize)
        banner.adUnitID = unitID
        banner.rootViewController = Self.rootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        let width = availableWidth()
        let expected = currentOrientationAnchoredAdaptiveBanner(width: width)
        if uiView.adSize.size != expected.size {
            uiView.adSize = expected
            uiView.load(Request())
        }
    }

    // MARK: - Helpers

    private func availableWidth() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        // Config.swift 기준 앱 최대 폭 500 (iPad 등에서 제한)
        return min(screenWidth, 500)
    }

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }
}
