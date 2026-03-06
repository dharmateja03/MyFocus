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

            if !bootstrap.accessibilityGranted || !bootstrap.notificationPermissionGranted {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permissions Required")
                        .font(.headline)
                    Text("Accessibility is required for app blocking. Notifications are used for session reminders.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 10) {
                        if !bootstrap.accessibilityGranted {
                            Button("Grant Accessibility") {
                                bootstrap.requestAccessibilityPermission()
                            }
                            Button("Open Accessibility Settings") {
                                bootstrap.openAccessibilitySettings()
                            }
                        }

                        if !bootstrap.notificationPermissionGranted {
                            Button("Grant Notifications") {
                                bootstrap.requestNotificationPermission()
                            }
                            Button("Open Notification Settings") {
                                bootstrap.openNotificationSettings()
                            }
                        }

                        Button("Refresh") {
                            bootstrap.refreshPermissions()
                        }
                    }
                }
                .padding(12)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            Stepper("Duration: \(bootstrap.selectedDurationMinutes) min", value: $bootstrap.selectedDurationMinutes, in: 1...180)
            Toggle("Enable Session Notifications", isOn: $bootstrap.notificationsEnabled)

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

            VStack(alignment: .leading, spacing: 8) {
                Text("Blocked Apps (Bundle IDs)")
                    .font(.headline)

                HStack {
                    TextField("com.apple.Safari", text: $bootstrap.blockedAppInput)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        bootstrap.addBlockedBundleID()
                    }
                    .disabled(bootstrap.blockedAppInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                List {
                    ForEach(bootstrap.blockedAppBundleIDs, id: \.self) { bundleID in
                        HStack {
                            Text(bundleID)
                                .font(.caption.monospaced())
                            Spacer()
                            Button("Remove") {
                                bootstrap.removeBlockedBundleID(bundleID)
                            }
                            .buttonStyle(.link)
                        }
                    }
                }
                .frame(height: 120)

                Text("Blocked attempts: \(bootstrap.blockedEventCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let lastBlockedBundleID = bootstrap.lastBlockedBundleID {
                    Text("Last blocked app: \(lastBlockedBundleID)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Sessions")
                    .font(.headline)

                List {
                    ForEach(bootstrap.sessionHistory.prefix(10)) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(entry.finalPhase.rawValue.capitalized) • \(formattedTime(entry.durationSeconds))")
                                .font(.caption.weight(.semibold))
                            Text(entry.startedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 120)
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
