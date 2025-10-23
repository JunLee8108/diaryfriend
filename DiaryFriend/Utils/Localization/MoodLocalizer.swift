//
//  MoodLocalizer.swift
//  DiaryFriend
//
//  Created by Jun Lee on 10/22/25.
//

import Foundation

struct MoodLocalizer {
    /// Mood 값을 현재 언어의 표시 이름으로 변환
    /// - Parameter mood: 데이터베이스의 mood 값 (예: "happy", "sad", "neutral")
    /// - Returns: 다국어 적용된 표시 이름 (예: "Happy" / "행복")
    static func displayName(for mood: String) -> String {
        switch mood.lowercased() {
        case "happy":
            return LocalizationManager.shared.localized(.mood_happy)
        case "sad":
            return LocalizationManager.shared.localized(.mood_sad)
        case "neutral":
            return LocalizationManager.shared.localized(.mood_neutral)
        default:
            // 알 수 없는 mood는 원본 그대로 반환 (첫 글자만 대문자)
            return mood.capitalized
        }
    }
}
