import SwiftUI

@main
struct EWClockIOSApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var isLogoVisible = true

    private let displaySleepController = IOSDisplaySleepController()

    init() {
        try! BrandFont.register()
    }

    var body: some Scene {
        WindowGroup {
            ClockView(isLogoVisible: $isLogoVisible)
                .persistentSystemOverlays(.hidden)
                .onChange(of: scenePhase, initial: true) { _, newPhase in
                    displaySleepController.setSceneActive(newPhase == .active)
                }
        }
    }
}
