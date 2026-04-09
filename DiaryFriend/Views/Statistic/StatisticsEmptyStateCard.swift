//
//  StatisticsEmptyStateCard.swift
//  DiaryFriend
//

import SwiftUI

struct StatisticsEmptyStateCard: View {
    let month: Date
    
    // ⭐ @Localized 추가 - 언어 변경 시 자동 업데이트!
    @Localized(.stats_empty_no_entries) var noEntriesTemplate
    @Localized(.stats_empty_start_writing) var startWritingMessage
    
    // ⭐ locale 적용된 월 이름
    private var monthName: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.code)
        formatter.dateFormat = "MMMM"
        return formatter.string(from: month)
    }
    
    // ⭐ 다국어 메시지
    private var noEntriesMessage: String {
        String(format: noEntriesTemplate, monthName)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(noEntriesMessage)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.primary)
            
            Text(startWritingMessage)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.modernSurfacePrimary)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 3)
        )
    }
}
