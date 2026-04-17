//
//  NotificationManager.swift
//  DiaryFriend
//
//  매일 일기 알림 관리
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()
    private let notificationID = "daily_diary_reminder"

    private let defaults = UserDefaults.standard
    private let enabledKey = "notification_enabled"
    private let hourKey = "notification_hour"
    private let minuteKey = "notification_minute"
    private let permissionRequestedKey = "notification_permission_requested"

    var isEnabled: Bool {
        get { defaults.bool(forKey: enabledKey) }
        set { defaults.set(newValue, forKey: enabledKey) }
    }

    var hasRequestedPermission: Bool {
        get { defaults.bool(forKey: permissionRequestedKey) }
        set { defaults.set(newValue, forKey: permissionRequestedKey) }
    }

    var reminderHour: Int {
        get {
            let h = defaults.integer(forKey: hourKey)
            return h == 0 && !defaults.bool(forKey: enabledKey) ? 21 : h
        }
        set { defaults.set(newValue, forKey: hourKey) }
    }

    var reminderMinute: Int {
        get { defaults.integer(forKey: minuteKey) }
        set { defaults.set(newValue, forKey: minuteKey) }
    }

    var reminderTime: Date {
        get {
            var components = DateComponents()
            components.hour = reminderHour
            components.minute = reminderMinute
            return Calendar.current.date(from: components) ?? Date()
        }
        set {
            let components = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            reminderHour = components.hour ?? 21
            reminderMinute = components.minute ?? 0
        }
    }

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("❌ Notification permission error: \(error)")
            return false
        }
    }

    func checkPermission() async -> Bool {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule

    func scheduleDailyReminder(hour: Int, minute: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])

        let content = UNMutableNotificationContent()
        content.title = "DiaryFriend"
        content.body = randomNotificationBody()
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("❌ Failed to schedule notification: \(error)")
            } else {
                print("✅ Daily reminder scheduled at \(hour):\(String(format: "%02d", minute))")
            }
        }

        reminderHour = hour
        reminderMinute = minute
        isEnabled = true
    }

    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])
        isEnabled = false
        print("🔕 Daily reminder cancelled")
    }

    // MARK: - Notification Body

    private func randomNotificationBody() -> String {
        let isKorean = LocalizationManager.shared.currentLanguage == .korean
        let bodies = isKorean
            ? ["오늘 하루는 어떠셨나요? 잠깐 기록해보세요.",
               "오늘의 좋았던 순간을 놓치지 마세요.",
               "딱 3초! 오늘의 기분을 기록해보세요."]
            : ["How was your day? Take a moment to write.",
               "Don't let today's good moments slip away.",
               "Just tap your mood — 3 seconds is enough."]
        return bodies.randomElement() ?? bodies[0]
    }

    // MARK: - Debug

    #if DEBUG
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "DiaryFriend"
        content.body = randomNotificationBody()
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: "test_notification", content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                print("❌ Test notification failed: \(error)")
            } else {
                print("✅ Test notification will appear in 5 seconds (go to background!)")
            }
        }
    }
    #endif
}
