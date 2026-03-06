import AppKit
import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var bootstrap: AppBootstrap

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MyFocus")
                .font(.headline)
            Text(bootstrap.helperStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
            Divider()
            Button("Open Main Window") {
                NSApp.activate(ignoringOtherApps: true)
            }
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(12)
        .frame(width: 220)
    }
}
