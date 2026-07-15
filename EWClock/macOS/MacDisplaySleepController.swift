import Foundation

final class MacDisplaySleepController {
    private var activity: NSObjectProtocol?

    func start() {
        guard activity == nil else {
            return
        }

        activity = ProcessInfo.processInfo.beginActivity(
            options: .idleDisplaySleepDisabled,
            reason: "EW Clock is active"
        )
    }

    func stop() {
        guard let activity else {
            return
        }

        ProcessInfo.processInfo.endActivity(activity)
        self.activity = nil
    }
}
