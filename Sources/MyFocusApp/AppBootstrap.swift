import Foundation
import FocusCore

@MainActor
final class AppBootstrap: ObservableObject {
    @Published private(set) var helperStatus = "Disconnected"
    @Published private(set) var sessionSnapshot = SessionSnapshot(
        phase: .idle,
        remainingSeconds: 0,
        blockedBundleIDs: []
    )
    @Published var selectedDurationMinutes = 25 {
        didSet { persistSettings() }
    }
    @Published var notificationsEnabled = true {
        didSet { persistSettings() }
    }
    @Published private(set) var accessibilityGranted = false
    @Published private(set) var notificationPermissionGranted = false
    @Published var blockedAppInput = ""
    @Published private(set) var blockedAppBundleIDs: [String] = []
    @Published private(set) var blockedEventCount = 0
    @Published private(set) var lastBlockedBundleID: String?
    @Published private(set) var sessionHistory: [SessionHistoryEntry] = []
    @Published var lastSessionError: String?

    private let sessionEngine = SessionEngine()
    private let appBlocker = ForegroundAppBlocker()
    private let permissionService = PermissionService()
    private let persistenceStore = PersistenceStore()
    private var streamTask: Task<Void, Never>?
    private var activeSessionStartedAt: Date?
    private var previousPhase: SessionPhase = .idle

    init() {
        helperStatus = "Scaffold ready"
        appBlocker.start()
        bindAppBlocker()
        bindSessionEngine()
        loadPersistedState()
        Task {
            await refreshPermissionStatuses()
        }
    }

    deinit {
        streamTask?.cancel()
    }

    var isRunning: Bool {
        sessionSnapshot.phase == .running
    }

    var isPaused: Bool {
        sessionSnapshot.phase == .paused
    }

    func addBlockedBundleID() {
        let trimmed = blockedAppInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        if !blockedAppBundleIDs.contains(trimmed) {
            blockedAppBundleIDs.append(trimmed)
            blockedAppBundleIDs.sort()
            syncBlockedBundleIDs()
        }

        blockedAppInput = ""
    }

    func removeBlockedBundleID(_ bundleID: String) {
        blockedAppBundleIDs.removeAll { $0 == bundleID }
        syncBlockedBundleIDs()
    }

    func startSession() {
        let duration = max(1, selectedDurationMinutes) * 60
        activeSessionStartedAt = .now
        blockedEventCount = 0
        lastBlockedBundleID = nil

        Task {
            do {
                try await sessionEngine.start(durationSeconds: duration, blockedBundleIDs: blockedAppBundleIDs)
                await MainActor.run {
                    self.lastSessionError = nil
                }
            } catch {
                await MainActor.run {
                    self.lastSessionError = error.localizedDescription
                }
            }
        }
    }

    func togglePauseResume() {
        Task {
            do {
                switch sessionSnapshot.phase {
                case .running:
                    try await sessionEngine.pause()
                case .paused:
                    try await sessionEngine.resume()
                default:
                    return
                }

                await MainActor.run {
                    self.lastSessionError = nil
                }
            } catch {
                await MainActor.run {
                    self.lastSessionError = error.localizedDescription
                }
            }
        }
    }

    func stopSession() {
        Task {
            do {
                try await sessionEngine.cancel()
                await MainActor.run {
                    self.lastSessionError = nil
                }
            } catch {
                await MainActor.run {
                    self.lastSessionError = error.localizedDescription
                }
            }
        }
    }

    func requestAccessibilityPermission() {
        permissionService.requestAccessibilityPrompt()
        Task {
            await refreshPermissionStatuses()
        }
    }

    func openAccessibilitySettings() {
        permissionService.openAccessibilitySettings()
    }

    func requestNotificationPermission() {
        Task {
            let granted = await permissionService.requestNotificationAuthorization()
            await MainActor.run {
                self.notificationPermissionGranted = granted
                if granted {
                    self.notificationsEnabled = true
                }
            }
        }
    }

    func openNotificationSettings() {
        permissionService.openNotificationSettings()
    }

    func refreshPermissions() {
        Task {
            await refreshPermissionStatuses()
        }
    }

    private func bindAppBlocker() {
        appBlocker.onBlockedApp = { [weak self] event in
            Task { @MainActor in
                guard let self else {
                    return
                }
                self.blockedEventCount += 1
                self.lastBlockedBundleID = event.bundleID
            }
        }
    }

    private func bindSessionEngine() {
        streamTask = Task {
            let stream = await sessionEngine.stream()
            for await snapshot in stream {
                await MainActor.run {
                    self.sessionSnapshot = snapshot
                    self.appBlocker.setEnforcementEnabled(snapshot.phase == .running)
                    self.captureHistoryIfNeeded(for: snapshot)
                }
            }
        }
    }

    private func captureHistoryIfNeeded(for snapshot: SessionSnapshot) {
        defer { previousPhase = snapshot.phase }
        guard previousPhase != snapshot.phase else {
            return
        }

        guard snapshot.phase == .completed || snapshot.phase == .cancelled else {
            return
        }

        let startedAt = activeSessionStartedAt ?? Date().addingTimeInterval(-Double(selectedDurationMinutes * 60))
        let endedAt = .now
        let entry = SessionHistoryEntry(
            id: UUID(),
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: max(0, Int(endedAt.timeIntervalSince(startedAt))),
            finalPhase: snapshot.phase,
            blockedBundleIDs: snapshot.blockedBundleIDs
        )

        sessionHistory.insert(entry, at: 0)
        activeSessionStartedAt = nil

        Task {
            await persistenceStore.appendHistory(entry)
        }
    }

    private func loadPersistedState() {
        Task {
            let persisted = await persistenceStore.loadState()
            await MainActor.run {
                self.selectedDurationMinutes = persisted.settings.selectedDurationMinutes
                self.notificationsEnabled = persisted.settings.notificationsEnabled
                self.blockedAppBundleIDs = persisted.settings.blockedAppBundleIDs
                self.sessionHistory = persisted.history
                self.syncBlockedBundleIDs()
            }
        }
    }

    private func syncBlockedBundleIDs() {
        appBlocker.updateBlockedBundleIDs(blockedAppBundleIDs)
        persistSettings()
        Task {
            await sessionEngine.updateBlockedBundleIDs(blockedAppBundleIDs)
        }
    }

    private func persistSettings() {
        let settings = AppSettings(
            selectedDurationMinutes: selectedDurationMinutes,
            blockedAppBundleIDs: blockedAppBundleIDs,
            notificationsEnabled: notificationsEnabled
        )

        Task {
            await persistenceStore.saveSettings(settings)
        }
    }

    private func refreshPermissionStatuses() async {
        let accessibility = permissionService.isAccessibilityGranted()
        let notifications = await permissionService.notificationAuthorizationGranted()

        await MainActor.run {
            self.accessibilityGranted = accessibility
            self.notificationPermissionGranted = notifications
        }
    }
}
