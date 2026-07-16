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
                .toolbar(removing: .title)
                .toolbarVisibility(.visible, for: .windowToolbar)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        }
        .defaultSize(width: 1_000, height: 400)
    }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let displaySleepController = MacDisplaySleepController()
    private let windowControlsController = MacWindowControlsController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        displaySleepController.start()
        windowControlsController.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowControlsController.stop()
        displaySleepController.stop()
    }
}
