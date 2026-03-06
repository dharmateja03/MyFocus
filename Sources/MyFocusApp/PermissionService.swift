import AppKit
import ApplicationServices
import Foundation
import UserNotifications

@MainActor
final class PermissionService {
    func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    func requestAccessibilityPrompt() {
        let promptKey = "AXTrustedCheckOptionPrompt"
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    func openAccessibilitySettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    func notificationAuthorizationGranted() async -> Bool {
        let statusRawValue = await notificationAuthorizationStatus()
        let status = UNAuthorizationStatus(rawValue: statusRawValue) ?? .notDetermined

        switch status {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied, .notDetermined:
            return false
        @unknown default:
            return false
        }
    }

    func requestNotificationAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            return false
        }
    }

    func openNotificationSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications")
        if let url {
            NSWorkspace.shared.open(url)
        }
    }

    private func notificationAuthorizationStatus() async -> Int {
        await withCheckedContinuation { continuation in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                continuation.resume(returning: settings.authorizationStatus.rawValue)
            }
        }
    }
}
