import SwiftUI

@main
struct MyFocusApp: App {
    @StateObject private var bootstrap = AppBootstrap()

    var body: some Scene {
        WindowGroup("MyFocus") {
            ContentView()
                .environmentObject(bootstrap)
                .frame(minWidth: 420, minHeight: 280)
        }

        MenuBarExtra("MyFocus", systemImage: "timer") {
            MenuBarView()
                .environmentObject(bootstrap)
        }
        .menuBarExtraStyle(.window)
    }
}
