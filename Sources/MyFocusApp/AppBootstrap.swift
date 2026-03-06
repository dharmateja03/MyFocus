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
    @Published var selectedDurationMinutes = 25
    @Published var blockedAppInput = ""
    @Published private(set) var blockedAppBundleIDs: [String] = []
    @Published private(set) var blockedEventCount = 0
    @Published private(set) var lastBlockedBundleID: String?
    @Published var lastSessionError: String?

    private let sessionEngine = SessionEngine()
    private let appBlocker = ForegroundAppBlocker()
    private var streamTask: Task<Void, Never>?

    init() {
        helperStatus = "Scaffold ready"
        appBlocker.start()
        bindAppBlocker()
        bindSessionEngine()
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
                }
            }
        }
    }

    private func syncBlockedBundleIDs() {
        appBlocker.updateBlockedBundleIDs(blockedAppBundleIDs)
        Task {
            await sessionEngine.updateBlockedBundleIDs(blockedAppBundleIDs)
        }
    }
}
