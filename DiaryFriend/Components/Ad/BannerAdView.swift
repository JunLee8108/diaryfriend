//
//  BannerAdView.swift
//  DiaryFriend
//
//  SwiftUI wrapper around GoogleMobileAds.BannerView. Uses a UIView wrapper
//  with clipsToBounds=true (Google-recommended pattern) to guarantee that
//  the ad creative never renders outside the allocated slot. Uses the
//  BannerViewDelegate callback to report the actual served ad size back
//  to SwiftUI so the container can size itself exactly.
//

import SwiftUI
import GoogleMobileAds
import UIKit

struct BannerAdView: UIViewRepresentable {
    let unitID: String
    /// 실제 렌더되는 컨테이너 width. AdContainer가 GeometryReader로 측정해서 주입.
    let width: CGFloat
    /// 광고 로드 완료 시 실제 서빙된 ad size를 SwiftUI로 전달.
    let onAdSizeChanged: (CGSize) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onAdSizeChanged: onAdSizeChanged)
    }

    // ⭐ Google 공식 패턴: UIView wrapper + clipsToBounds
    // SwiftUI .clipped()는 hosting layer에서만 mask를 걸어 복잡한 UIView
    // subview tree의 렌더링을 완전히 클립 못 하는 경우가 있다. UIView
    // level에서 clipsToBounds=true를 설정해 UIKit 렌더 파이프라인이
    // 확실히 wrapper 밖 픽셀을 차단한다.
    func makeUIView(context: Context) -> UIView {
        let wrapper = UIView()
        wrapper.clipsToBounds = true
        wrapper.backgroundColor = .clear

        let banner = AdManager.shared.bannerView(for: unitID, width: width)
        banner.delegate = context.coordinator
        context.coordinator.banner = banner

        // BannerView는 AdManager가 보관하는 공용 인스턴스이므로 기존 superview에서
        // 먼저 떼어낸 뒤 새 wrapper에 붙인다 (UIView는 superview 하나만 가능).
        banner.removeFromSuperview()
        banner.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(banner)

        NSLayoutConstraint.activate([
            banner.centerXAnchor.constraint(equalTo: wrapper.centerXAnchor),
            banner.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor),
            banner.widthAnchor.constraint(lessThanOrEqualTo: wrapper.widthAnchor),
            banner.heightAnchor.constraint(lessThanOrEqualTo: wrapper.heightAnchor),
        ])

        // 이미 로드된 캐시 배너라면 delegate 콜백이 다시 안 오므로 현재 adSize를 바로 보고.
        let currentSize = banner.adSize.size
        if currentSize.width > 0, currentSize.height > 0 {
            DispatchQueue.main.async {
                onAdSizeChanged(currentSize)
            }
        }

        return wrapper
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 회전/사이즈 변경 시 갱신 (대부분 no-op). AdManager와 동일한 inline
        // adaptive API를 사용해 size 일관성을 유지한다.
        guard let banner = context.coordinator.banner else { return }
        let expected = inlineAdaptiveBanner(width: width, maxHeight: AdManager.maxBannerHeight)
        if banner.adSize.size != expected.size {
            banner.adSize = expected
            banner.load(Request())
        }
    }

    // ⭐ wrapper만 SwiftUI host에서 분리. 내부 BannerView는 AdManager가 계속 보관.
    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        if let banner = coordinator.banner {
            // cached banner가 현재 wrapper에 붙어 있으면 떼어내 다음 host에 재사용 가능하게.
            if banner.superview === uiView {
                banner.removeFromSuperview()
            }
            banner.delegate = nil
        }
        uiView.removeFromSuperview()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, BannerViewDelegate {
        let onAdSizeChanged: (CGSize) -> Void
        weak var banner: BannerView?

        init(onAdSizeChanged: @escaping (CGSize) -> Void) {
            self.onAdSizeChanged = onAdSizeChanged
        }

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            // 실제 서빙된 광고의 size. 요청한 adSize와 다를 수 있다.
            let size = bannerView.adSize.size
            DispatchQueue.main.async { [onAdSizeChanged] in
                onAdSizeChanged(size)
            }
        }
    }
}
