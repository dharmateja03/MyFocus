import SwiftUI
import FocusCore

struct ContentView: View {
    @EnvironmentObject private var bootstrap: AppBootstrap

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MyFocus")
                .font(.largeTitle.weight(.semibold))
            Text("Phase: \(bootstrap.sessionSnapshot.phase.rawValue.capitalized)")
                .font(.headline)
            Text("Remaining: \(formattedTime(bootstrap.sessionSnapshot.remainingSeconds))")
                .font(.title2.monospacedDigit())
            Text("Helper status: \(bootstrap.helperStatus)")
                .font(.body)
                .foregroundStyle(.secondary)
            Stepper("Duration: \(bootstrap.selectedDurationMinutes) min", value: $bootstrap.selectedDurationMinutes, in: 1...180)

            HStack(spacing: 10) {
                Button("Start") {
                    bootstrap.startSession()
                }
                .keyboardShortcut(.return)

                Button(bootstrap.isPaused ? "Resume" : "Pause") {
                    bootstrap.togglePauseResume()
                }
                .disabled(!(bootstrap.isRunning || bootstrap.isPaused))

                Button("Stop") {
                    bootstrap.stopSession()
                }
                .disabled(!(bootstrap.isRunning || bootstrap.isPaused))
            }

            if let errorMessage = bootstrap.lastSessionError {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Spacer()
        }
        .padding(24)
    }

    private func formattedTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
