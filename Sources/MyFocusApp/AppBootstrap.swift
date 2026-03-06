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
    @Published var blockedAppBundleIDs: [String] = []
    @Published var lastSessionError: String?

    private let sessionEngine = SessionEngine()
    private var streamTask: Task<Void, Never>?

    init() {
        // XPC wiring is intentionally shallow in scaffold commit.
        helperStatus = "Scaffold ready"
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

    private func bindSessionEngine() {
        streamTask = Task {
            let stream = await sessionEngine.stream()
            for await snapshot in stream {
                await MainActor.run {
                    self.sessionSnapshot = snapshot
                }
            }
        }
    }
}
