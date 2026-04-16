//
//  TodayDateLabel.swift
//  DiaryFriend
//

import SwiftUI

struct TodayDateLabel: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared
    var showListView: Binding<Bool>? = nil

    private var todayText: String {
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

            Spacer()

            if let showListView {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showListView.wrappedValue.toggle()
                    }
                } label: {
                    Image(systemName: showListView.wrappedValue ? "calendar" : "list.bullet")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
