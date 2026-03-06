import Foundation
import FocusCore

final class HelperRuntime {
    func start() {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[FocusHelper] started at \(timestamp)")

        // Placeholder run loop keeps helper alive until real XPC listener is added.
        RunLoop.current.run()
    }
}

HelperRuntime().start()
