import AppKit

@MainActor
final class MacWindowControlsController: NSObject {
    private static let pointerPollInterval: TimeInterval = 0.05
    private static let controlTypes: [NSWindow.ButtonType] = [
        .closeButton,
        .miniaturizeButton,
        .zoomButton,
    ]

    private weak var window: NSWindow?
    private var originalHiddenStates: [(button: NSButton, isHidden: Bool)] = []
    private var pollTimer: Timer?
    private var state = WindowControlVisibilityState()
    private let clock = ContinuousClock()
    private var origin = ContinuousClock.now
    private var lastPointerLocation: NSPoint?
    private var wasInsideWindow = false
    private var wasOverControl = false

    func start() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowBecameActive(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowBecameActive(_:)),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )

        if let window = NSApp.windows.first(where: isClockWindow) {
            attach(to: window)
        }
    }

    func stop() {
        NotificationCenter.default.removeObserver(self)
        detach()
    }

    @objc
    private func windowBecameActive(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              isClockWindow(window) else {
            return
        }

        attach(to: window)
    }

    private func attach(to window: NSWindow) {
        guard self.window !== window else {
            return
        }

        detach()
        self.window = window
        origin = clock.now
        originalHiddenStates = controlButtons(in: window).map {
            ($0, $0.isHidden)
        }
        applyVisibility()

        let timer = Timer(
            timeInterval: Self.pointerPollInterval,
            target: self,
            selector: #selector(pollPointer),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func detach() {
        pollTimer?.invalidate()
        pollTimer = nil

        for originalState in originalHiddenStates {
            originalState.button.isHidden = originalState.isHidden
        }

        originalHiddenStates = []
        state.reset()
        lastPointerLocation = nil
        wasInsideWindow = false
        wasOverControl = false
        window = nil
    }

    @objc
    private func pollPointer() {
        guard let window else {
            detach()
            return
        }

        let now = origin.duration(to: clock.now)
        let pointerLocation = NSEvent.mouseLocation
        let isInsideWindow = window.frame.contains(pointerLocation)

        guard isInsideWindow else {
            if wasInsideWindow {
                state.pointerExitedWindow(at: now)
            }
            state.update(at: now)
            applyVisibility()
            lastPointerLocation = pointerLocation
            wasInsideWindow = false
            wasOverControl = false
            return
        }

        let isOverControl = controlButtons(in: window).contains { button in
            let windowFrame = button.convert(button.bounds, to: nil)
            return window.convertToScreen(windowFrame).contains(pointerLocation)
        }

        if isOverControl != wasOverControl {
            state.setPointerOverControl(isOverControl, at: now)
        }

        if !wasInsideWindow || lastPointerLocation != pointerLocation {
            state.recordPointerActivity(at: now)
        }

        state.update(at: now)
        applyVisibility()
        lastPointerLocation = pointerLocation
        wasInsideWindow = true
        wasOverControl = isOverControl
    }

    private func applyVisibility() {
        guard let window else {
            return
        }

        let buttons = controlButtons(in: window)
        for button in buttons {
            button.isHidden = !state.isVisible
        }
    }

    private func controlButtons(in window: NSWindow) -> [NSButton] {
        Self.controlTypes.compactMap(window.standardWindowButton)
    }

    private func isClockWindow(_ window: NSWindow) -> Bool {
        window.identifier?.rawValue == "clock"
            || window.title == "EW Clock"
    }
}
