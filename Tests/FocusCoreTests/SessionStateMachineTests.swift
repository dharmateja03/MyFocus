import XCTest
@testable import FocusCore

final class SessionStateMachineTests: XCTestCase {
    func testStartPauseResumeCancelFlow() async throws {
        let stateMachine = SessionStateMachine()

        let started = try await stateMachine.start(
            durationSeconds: 120,
            blockedBundleIDs: ["com.apple.Safari"]
        )
        XCTAssertEqual(started.phase, .running)
        XCTAssertEqual(started.remainingSeconds, 120)

        let paused = try await stateMachine.pause()
        XCTAssertEqual(paused.phase, .paused)

        let resumed = try await stateMachine.resume()
        XCTAssertEqual(resumed.phase, .running)

        let cancelled = try await stateMachine.cancel()
        XCTAssertEqual(cancelled.phase, .cancelled)
    }

    func testCompletesOnTickCountdown() async throws {
        let stateMachine = SessionStateMachine()

        _ = try await stateMachine.start(durationSeconds: 1, blockedBundleIDs: [])
        let ticked = await stateMachine.tick()

        XCTAssertEqual(ticked?.phase, .completed)
        XCTAssertEqual(ticked?.remainingSeconds, 0)
    }

    func testRejectsInvalidTransition() async throws {
        let stateMachine = SessionStateMachine()

        do {
            _ = try await stateMachine.pause()
            XCTFail("Expected invalid transition error")
        } catch let error as SessionTransitionError {
            XCTAssertEqual(error, .invalidTransition(from: .idle, to: .paused))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
