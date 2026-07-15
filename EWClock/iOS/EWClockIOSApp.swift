import SwiftUI

@main
struct EWClockIOSApp: App {
    @Environment(\.scenePhase) private var scenePhase

    private let displaySleepController = IOSDisplaySleepController()

    init() {
        try! BrandFont.register()
    }

    var body: some Scene {
        WindowGroup {
            ClockView()
                .persistentSystemOverlays(.hidden)
                .onChange(of: scenePhase, initial: true) { _, newPhase in
                    displaySleepController.setSceneActive(newPhase == .active)
                }
        }
    }
}
