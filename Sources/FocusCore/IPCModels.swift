import Foundation

public enum SessionPhase: String, Codable {
    case idle
    case running
    case paused
    case completed
    case cancelled
}

public struct SessionStartRequest: Codable, Equatable {
    public let durationSeconds: Int
    public let startedAt: Date

    public init(durationSeconds: Int, startedAt: Date) {
        self.durationSeconds = durationSeconds
        self.startedAt = startedAt
    }
}

public struct SessionSnapshot: Codable, Equatable {
    public let phase: SessionPhase
    public let remainingSeconds: Int
    public let blockedBundleIDs: [String]

    public init(phase: SessionPhase, remainingSeconds: Int, blockedBundleIDs: [String]) {
        self.phase = phase
        self.remainingSeconds = remainingSeconds
        self.blockedBundleIDs = blockedBundleIDs
    }
}
