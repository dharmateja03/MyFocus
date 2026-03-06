import AppKit
import Foundation

final class ForegroundAppBlocker {
    struct Event: Sendable {
        let bundleID: String
        let timestamp: Date
    }

    var onBlockedApp: ((Event) -> Void)?

    private let workspace: NSWorkspace
    private var activationObserver: NSObjectProtocol?
    private var blockedBundleIDs = Set<String>()
    private var enforcementEnabled = false

    init(workspace: NSWorkspace = .shared) {
        self.workspace = workspace
    }

    deinit {
        if let activationObserver {
            workspace.notificationCenter.removeObserver(activationObserver)
        }
    }

    func start() {
        guard activationObserver == nil else {
            return
        }

        activationObserver = workspace.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleAppActivation(notification)
        }
    }

    func updateBlockedBundleIDs(_ bundleIDs: [String]) {
        blockedBundleIDs = Set(bundleIDs)
    }

    func setEnforcementEnabled(_ enabled: Bool) {
        enforcementEnabled = enabled
    }

    private func handleAppActivation(_ notification: Notification) {
        guard enforcementEnabled else {
            return
        }

        guard
            let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
            let bundleID = app.bundleIdentifier
        else {
            return
        }

        guard blockedBundleIDs.contains(bundleID), bundleID != Bundle.main.bundleIdentifier else {
            return
        }

        app.hide()
        NSApp.activate(ignoringOtherApps: true)
        onBlockedApp?(Event(bundleID: bundleID, timestamp: .now))
    }
}
