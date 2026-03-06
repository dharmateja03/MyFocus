import Foundation
import UserNotifications

@MainActor
final class NotificationService {
    private let center: UNUserNotificationCenter
    private var lastBlockedEventByBundleID: [String: Date] = [:]
    private let blockedEventCooldown: TimeInterval = 60

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func sendSessionStarted(minutes: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Focus session started"
        content.body = "Stay focused for \(minutes) minutes."
        content.sound = .default

        sendNow(identifier: "session-start-\(UUID().uuidString)", content: content)
    }

    func sendSessionEnded(phase: String) {
        let content = UNMutableNotificationContent()
        content.title = "Focus session ended"
        content.body = "Session finished with status: \(phase)."
        content.sound = .default

        sendNow(identifier: "session-end-\(UUID().uuidString)", content: content)
    }

    func sendBlockedAppEvent(bundleID: String) {
        let now = Date()
        if let lastSent = lastBlockedEventByBundleID[bundleID], now.timeIntervalSince(lastSent) < blockedEventCooldown {
            return
        }

        lastBlockedEventByBundleID[bundleID] = now

        let content = UNMutableNotificationContent()
        content.title = "Blocked app closed"
        content.body = "\(bundleID) was blocked during your focus session."
        content.sound = .default

        sendNow(identifier: "blocked-app-\(bundleID)-\(UUID().uuidString)", content: content)
    }

    private func sendNow(identifier: String, content: UNMutableNotificationContent) {
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error {
                print("[NotificationService] failed to send notification: \(error)")
            }
        }
    }
}
