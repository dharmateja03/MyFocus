import Foundation

public enum SessionTransitionError: Error, Equatable, Sendable {
    case invalidTransition(from: SessionPhase, to: SessionPhase)
    case invalidDuration
}

public struct SessionRuntimeState: Equatable, Sendable {
    public var phase: SessionPhase
    public var durationSeconds: Int
    public var remainingSeconds: Int
    public var startedAt: Date?
    public var endedAt: Date?
    public var blockedBundleIDs: [String]

    public init(
        phase: SessionPhase = .idle,
        durationSeconds: Int = 0,
        remainingSeconds: Int = 0,
        startedAt: Date? = nil,
        endedAt: Date? = nil,
        blockedBundleIDs: [String] = []
    ) {
        self.phase = phase
        self.durationSeconds = durationSeconds
        self.remainingSeconds = remainingSeconds
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.blockedBundleIDs = blockedBundleIDs
    }

    public func snapshot() -> SessionSnapshot {
        SessionSnapshot(
            phase: phase,
            remainingSeconds: remainingSeconds,
            blockedBundleIDs: blockedBundleIDs
        )
    }
}

public actor SessionStateMachine {
    private var state = SessionRuntimeState()

    public init() {}

    public func snapshot() -> SessionSnapshot {
        state.snapshot()
    }

    @discardableResult
    public func start(durationSeconds: Int, blockedBundleIDs: [String], now: Date = .now) throws -> SessionSnapshot {
        guard durationSeconds > 0 else {
            throw SessionTransitionError.invalidDuration
        }

        guard state.phase == .idle || state.phase == .completed || state.phase == .cancelled else {
            throw SessionTransitionError.invalidTransition(from: state.phase, to: .running)
        }

        state.phase = .running
        state.durationSeconds = durationSeconds
        state.remainingSeconds = durationSeconds
        state.startedAt = now
        state.endedAt = nil
        state.blockedBundleIDs = blockedBundleIDs

        return state.snapshot()
    }

    @discardableResult
    public func pause() throws -> SessionSnapshot {
        guard state.phase == .running else {
            throw SessionTransitionError.invalidTransition(from: state.phase, to: .paused)
        }

        state.phase = .paused
        return state.snapshot()
    }

    @discardableResult
    public func resume() throws -> SessionSnapshot {
        guard state.phase == .paused else {
            throw SessionTransitionError.invalidTransition(from: state.phase, to: .running)
        }

        state.phase = .running
        return state.snapshot()
    }

    @discardableResult
    public func cancel(now: Date = .now) throws -> SessionSnapshot {
        guard state.phase == .running || state.phase == .paused else {
            throw SessionTransitionError.invalidTransition(from: state.phase, to: .cancelled)
        }

        state.phase = .cancelled
        state.endedAt = now
        return state.snapshot()
    }

    @discardableResult
    public func tick() -> SessionSnapshot? {
        guard state.phase == .running else {
            return nil
        }

        state.remainingSeconds = max(0, state.remainingSeconds - 1)

        if state.remainingSeconds == 0 {
            state.phase = .completed
            state.endedAt = .now
        }

        return state.snapshot()
    }

    @discardableResult
    public func updateBlockedBundleIDs(_ bundleIDs: [String]) -> SessionSnapshot {
        state.blockedBundleIDs = bundleIDs
        return state.snapshot()
    }
}
