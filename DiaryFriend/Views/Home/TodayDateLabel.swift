//
//  TodayDateLabel.swift
//  DiaryFriend
//

import SwiftUI

struct TodayDateLabel: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared

    private var todayText: String {
        // localizationManager를 참조하여 언어 변경 시 View 갱신 트리거
        let _ = localizationManager.currentLanguage
        return DateUtility.shared.fullDateWithWeekday(from: Date())
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "calendar")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "00C896"))

            Text(todayText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
