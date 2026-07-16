import Foundation

struct WindowControlVisibilityState: Equatable, Sendable {
    static let inactivityInterval: Duration = .seconds(2)

    private(set) var isVisible = false
    private(set) var nextHideDeadline: Duration?
    private var isPointerOverControl = false

    mutating func recordPointerActivity(at now: Duration) {
        isVisible = true
        nextHideDeadline = isPointerOverControl
            ? nil
            : now + Self.inactivityInterval
    }

    mutating func setPointerOverControl(
        _ isPointerOverControl: Bool,
        at now: Duration
    ) {
        self.isPointerOverControl = isPointerOverControl
        isVisible = true
        nextHideDeadline = isPointerOverControl
            ? nil
            : now + Self.inactivityInterval
    }

    mutating func pointerExitedWindow(at now: Duration) {
        isPointerOverControl = false
        nextHideDeadline = isVisible
            ? now + Self.inactivityInterval
            : nil
    }

    mutating func update(at now: Duration) {
        guard !isPointerOverControl,
              let nextHideDeadline,
              now >= nextHideDeadline else {
            return
        }

        isVisible = false
        self.nextHideDeadline = nil
    }

    mutating func reset() {
        self = Self()
    }
}
