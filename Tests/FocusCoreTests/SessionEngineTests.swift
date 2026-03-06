import Foundation
import Testing
@testable import FocusCore

@Test
func sessionEngineCanStartAndUpdateBlockedBundleIDs() async throws {
    let engine = SessionEngine()

    try await engine.start(durationSeconds: 120, blockedBundleIDs: ["com.apple.Music"])
    await engine.updateBlockedBundleIDs(["com.apple.Notes", "com.apple.Safari"])

    let snapshot = await engine.snapshot()
    #expect(snapshot.phase == .running)
    #expect(snapshot.blockedBundleIDs == ["com.apple.Notes", "com.apple.Safari"])
}
