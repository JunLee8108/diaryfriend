//
//  ConsentManager.swift
//  DiaryFriend
//
//  Google User Messaging Platform (UMP) + App Tracking Transparency (ATT)
//  consent orchestration for AdMob.
//
//  EEA/UK users see the Google-provided GDPR form when required.
//  iOS 14.5+ users are asked for IDFA tracking permission.
//  Callers should check `canRequestAds` before initializing GoogleMobileAds.
//

import Foundation
import UIKit
import UserMessagingPlatform
import AppTrackingTransparency
import AdSupport

@MainActor
final class ConsentManager {
    static let shared = ConsentManager()
    private init() {}

    /// UMP이 광고 요청을 허용했는지 여부.
    /// EEA/UK 사용자가 동의를 거부했거나 아직 form을 보지 않은 경우 false.
    var canRequestAds: Bool {
        ConsentInformation.shared.canRequestAds
    }

    /// 앱 시작 시 1회 호출.
    /// UMP consent info를 갱신하고, 필요한 경우 동의 폼을 표시한 뒤
    /// 이어서 ATT 권한을 요청합니다.
    func bootstrap() async {
        await requestConsentIfNeeded()
        await requestATTIfPossible()
    }

    // MARK: - UMP

    private func requestConsentIfNeeded() async {
        let parameters = RequestParameters()
        #if DEBUG
        // 개발 중 동의 흐름을 강제로 재확인하고 싶을 때 주석 해제:
        // let debug = DebugSettings()
        // debug.geography = .EEA
        // parameters.debugSettings = debug
        #endif

        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
            try await loadAndPresentFormIfRequired()
        } catch {
            #if DEBUG
            print("⚠️ UMP consent update failed: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadAndPresentFormIfRequired() async throws {
        guard ConsentInformation.shared.formStatus == .available else { return }
        guard let rootVC = Self.rootViewController() else { return }
        try await ConsentForm.loadAndPresentIfRequired(from: rootVC)
    }

    // MARK: - ATT

    private func requestATTIfPossible() async {
        guard #available(iOS 14.5, *) else { return }
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        _ = await ATTrackingManager.requestTrackingAuthorization()
    }

    // MARK: - Helpers

    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }
}
