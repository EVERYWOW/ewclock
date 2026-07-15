import UIKit

@MainActor
final class IOSDisplaySleepController {
    func setSceneActive(_ isActive: Bool) {
        UIApplication.shared.isIdleTimerDisabled = isActive
    }
}
