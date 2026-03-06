import XCTest
@testable import FocusCore

final class SessionEngineTests: XCTestCase {
    func testCanStartAndUpdateBlockedBundleIDs() async throws {
        let engine = SessionEngine()

        try await engine.start(durationSeconds: 120, blockedBundleIDs: ["com.apple.Music"])
        await engine.updateBlockedBundleIDs(["com.apple.Notes", "com.apple.Safari"])

        let snapshot = await engine.snapshot()
        XCTAssertEqual(snapshot.phase, .running)
        XCTAssertEqual(snapshot.blockedBundleIDs, ["com.apple.Notes", "com.apple.Safari"])
    }
}
