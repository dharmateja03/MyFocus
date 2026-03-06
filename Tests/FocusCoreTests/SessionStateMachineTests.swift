import Foundation
import Testing
@testable import FocusCore

@Test
func stateMachineStartPauseResumeCancelFlow() async throws {
    let stateMachine = SessionStateMachine()

    let started = try await stateMachine.start(
        durationSeconds: 120,
        blockedBundleIDs: ["com.apple.Safari"]
    )
    #expect(started.phase == .running)
    #expect(started.remainingSeconds == 120)

    let paused = try await stateMachine.pause()
    #expect(paused.phase == .paused)

    let resumed = try await stateMachine.resume()
    #expect(resumed.phase == .running)

    let cancelled = try await stateMachine.cancel()
    #expect(cancelled.phase == .cancelled)
}

@Test
func stateMachineCompletesOnTickCountdown() async throws {
    let stateMachine = SessionStateMachine()

    _ = try await stateMachine.start(durationSeconds: 1, blockedBundleIDs: [])
    let ticked = await stateMachine.tick()

    #expect(ticked?.phase == .completed)
    #expect(ticked?.remainingSeconds == 0)
}

@Test
func stateMachineRejectsInvalidTransition() async throws {
    let stateMachine = SessionStateMachine()

    do {
        _ = try await stateMachine.pause()
        Issue.record("Expected invalid transition error")
    } catch let error as SessionTransitionError {
        #expect(error == .invalidTransition(from: .idle, to: .paused))
    } catch {
        Issue.record("Unexpected error: \(error)")
    }
}
