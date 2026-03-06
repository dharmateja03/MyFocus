import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var bootstrap: AppBootstrap

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MyFocus")
                .font(.largeTitle.weight(.semibold))
            Text("Native macOS focus app scaffold")
                .font(.headline)
            Text("Helper status: \(bootstrap.helperStatus)")
                .font(.body)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(24)
    }
}
