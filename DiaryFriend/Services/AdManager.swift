//
//  AdManager.swift
//  DiaryFriend
//
//  Google Mobile Ads SDK lifecycle + premium gating.
//
//  Responsibilities:
//  - Orchestrate Consent → ATT → MobileAds.start at launch
//  - Publish `shouldShowAds` (premium + consent aware) for the UI layer
//  - Register debug test devices so DEBUG builds never hit invalid-traffic rules
//

import Foundation
import Combine
import GoogleMobileAds

@MainActor
final class AdManager: ObservableObject {
    static let shared = AdManager()

    /// SDK가 준비되고 광고 요청 권한이 있는지 여부.
    /// HomeView의 AdContainer는 이 값을 관찰해서 배너 표시 여부를 정합니다.
    @Published private(set) var isReady: Bool = false

    private var hasBootstrapped = false

    private init() {}

    /// 앱 시작 시 1회 호출. 두 번째 호출은 무시됩니다.
    func bootstrap() async {
        guard !hasBootstrapped else { return }
        hasBootstrapped = true

        await ConsentManager.shared.bootstrap()

        guard ConsentManager.shared.canRequestAds else {
            #if DEBUG
            print("ℹ️ AdManager: consent not granted, skipping MobileAds.start")
            #endif
            return
        }

        await startMobileAds()
    }

    /// 배너/광고 뷰를 렌더링하기 전에 UI 레이어에서 확인하는 단일 진실 소스.
    /// - 프리미엄 구독자에게는 광고 표시 안 함
    /// - SDK가 준비되지 않았으면 표시 안 함
    /// - UMP consent가 없으면 표시 안 함
    var shouldShowAds: Bool {
        guard !UserProfileStore.shared.isPremium else { return false }
        guard isReady else { return false }
        guard ConsentManager.shared.canRequestAds else { return false }
        return true
    }

    // MARK: - Private

    private func startMobileAds() async {
        #if DEBUG
        // 시뮬레이터는 자동으로 테스트 디바이스로 인식되지만,
        // 실기기에서도 테스트 광고만 보려면 콘솔 로그에 찍히는 해시를 아래 배열에 넣으세요.
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = []
        #endif

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            MobileAds.shared.start { _ in
                continuation.resume()
            }
        }

        isReady = true

        #if DEBUG
        print("✅ GoogleMobileAds SDK started. App ID: \(Config.AdMob.appID)")
        #endif
    }
}
