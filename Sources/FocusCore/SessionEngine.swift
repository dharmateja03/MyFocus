import Foundation

public actor SessionEngine {
    private let stateMachine: SessionStateMachine
    private var continuation: AsyncStream<SessionSnapshot>.Continuation?
    private var tickerTask: Task<Void, Never>?

    public init(stateMachine: SessionStateMachine = SessionStateMachine()) {
        self.stateMachine = stateMachine
    }

    deinit {
        tickerTask?.cancel()
    }

    public func stream() -> AsyncStream<SessionSnapshot> {
        AsyncStream { continuation in
            self.continuation = continuation

            Task {
                let snapshot = await self.stateMachine.snapshot()
                continuation.yield(snapshot)
            }

            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.handleTermination()
                }
            }
        }
    }

    public func start(durationSeconds: Int, blockedBundleIDs: [String]) async throws {
        let snapshot = try await stateMachine.start(durationSeconds: durationSeconds, blockedBundleIDs: blockedBundleIDs)
        continuation?.yield(snapshot)
        ensureTicker()
    }

    public func pause() async throws {
        let snapshot = try await stateMachine.pause()
        continuation?.yield(snapshot)
    }

    public func resume() async throws {
        let snapshot = try await stateMachine.resume()
        continuation?.yield(snapshot)
        ensureTicker()
    }

    public func cancel() async throws {
        let snapshot = try await stateMachine.cancel()
        continuation?.yield(snapshot)
        stopTicker()
    }

    public func snapshot() async -> SessionSnapshot {
        await stateMachine.snapshot()
    }

    public func updateBlockedBundleIDs(_ bundleIDs: [String]) async {
        let snapshot = await stateMachine.updateBlockedBundleIDs(bundleIDs)
        continuation?.yield(snapshot)
    }

    private func ensureTicker() {
        if tickerTask != nil {
            return
        }

        tickerTask = Task { [weak self] in
            await self?.runTicker()
        }
    }

    private func stopTicker() {
        tickerTask?.cancel()
        tickerTask = nil
    }

    private func runTicker() async {
        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(1))
            } catch {
                break
            }

            guard let snapshot = await stateMachine.tick() else {
                continue
            }

            continuation?.yield(snapshot)

            if snapshot.phase == .completed {
                stopTicker()
                break
            }
        }
    }

    private func handleTermination() {
        continuation = nil
        stopTicker()
    }
}
