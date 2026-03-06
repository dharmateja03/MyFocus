import Foundation

@MainActor
final class AppBootstrap: ObservableObject {
    @Published private(set) var helperStatus = "Disconnected"

    init() {
        // XPC wiring is intentionally shallow in scaffold commit.
        helperStatus = "Scaffold ready"
    }
}
