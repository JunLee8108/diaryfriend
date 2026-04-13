//
//  TodayDateLabel.swift
//  DiaryFriend
//

import SwiftUI

struct TodayDateLabel: View {
    private var todayText: String {
        let dateString = DateUtility.shared.fullDateWithWeekday(from: Date())
        let template = LocalizationManager.shared.localized(.home_today_date)
        return String(format: template, dateString)
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
