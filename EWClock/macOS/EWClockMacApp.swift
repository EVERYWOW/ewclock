import AppKit
import SwiftUI

@main
struct EWClockMacApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegate
    @State private var isLogoVisible = true

    init() {
        try! BrandFont.register()
    }

    var body: some Scene {
        Window("EW Clock", id: "clock") {
            ClockView(isLogoVisible: $isLogoVisible)
                .toolbarVisibility(.hidden, for: .windowToolbar)
        }
        .defaultSize(width: 1_000, height: 400)
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let displaySleepController = MacDisplaySleepController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        displaySleepController.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        displaySleepController.stop()
    }
}
