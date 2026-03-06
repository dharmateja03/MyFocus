import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var bootstrap: AppBootstrap

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MyFocus")
                .font(.headline)

            Text("Phase: \(bootstrap.sessionSnapshot.phase.rawValue.capitalized)")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Remaining: \(formattedTime(bootstrap.sessionSnapshot.remainingSeconds))")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)

            Stepper(
                "Duration: \(bootstrap.selectedDurationMinutes)m",
                value: $bootstrap.selectedDurationMinutes,
                in: 1...180
            )

            HStack(spacing: 8) {
                Button("Start") {
                    bootstrap.startSession()
                }
                .buttonStyle(.borderedProminent)

                Button(bootstrap.isPaused ? "Resume" : "Pause") {
                    bootstrap.togglePauseResume()
                }
                .disabled(!(bootstrap.isRunning || bootstrap.isPaused))

                Button("Stop") {
                    bootstrap.stopSession()
                }
                .disabled(!(bootstrap.isRunning || bootstrap.isPaused))
            }

            Divider()

            Button("Open Main Window") {
                NSApp.activate(ignoringOtherApps: true)
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 280)
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
