# Window Drag and Mac Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users drag an EW Clock window from its full content area and reveal the standard Mac window controls during pointer activity.

**Architecture:** The shared `ClockView` owns the cross-platform SwiftUI window-drag gesture. A small macOS-only `NSViewRepresentable` attaches pointer monitors to its containing window and delegates testable deadline decisions to a pure state type.

**Tech Stack:** Swift 6, SwiftUI, AppKit, Swift Testing, XcodeGen, iOS 26, iPadOS 26, and macOS 26

## Global Constraints

- Keep the clock, progress bars, logo layout, and session-only logo dismissal unchanged.
- Window dragging is the only new gesture and must coexist with the EVERYWOW logo button.
- Keep the Mac window normal, resizable, and windowed at launch.
- Show standard Mac close, minimize, and zoom controls during pointer activity, then hide them after two seconds of inactivity.
- Keep standard menu and keyboard window commands available.
- Use `project.yml` as the Xcode project source of truth.
- Add no persistence, networking, analytics, settings, or third-party dependencies.

---

### Task 1: Add the Testable Mac Window-Control Policy

**Files:**
- Create: `EWClock/macOS/WindowControlVisibilityState.swift`
- Modify: `EWClockTests/ClockTests.swift`
- Modify: `project.yml`

**Interfaces:**
- Consumes: monotonic `Duration` values supplied by the macOS bridge.
- Produces: `WindowControlVisibilityState`, `recordPointerActivity(at:)`, `setPointerOverControl(_:at:)`, `pointerExitedWindow(at:)`, `reset()`, `update(at:)`, `isVisible`, and `nextHideDeadline`.

- [ ] **Step 1: Add failing state tests**

Add a `@Suite("Mac window control visibility")` suite to `EWClockTests/ClockTests.swift`. Use `Duration.zero` as the origin and assert these transitions:

```swift
@Suite("Mac window control visibility")
struct WindowControlVisibilityStateTests {
    @Test("Controls start hidden and hide two seconds after activity")
    func inactivityDeadline() {
        var state = WindowControlVisibilityState()

        #expect(!state.isVisible)
        state.recordPointerActivity(at: .zero)
        #expect(state.isVisible)
        #expect(state.nextHideDeadline == .seconds(2))

        state.update(at: .seconds(1.999))
        #expect(state.isVisible)
        state.update(at: .seconds(2))
        #expect(!state.isVisible)
    }

    @Test("New activity replaces the pending deadline")
    func repeatedActivity() {
        var state = WindowControlVisibilityState()
        state.recordPointerActivity(at: .zero)
        state.recordPointerActivity(at: .seconds(1))
        state.update(at: .seconds(2))
        #expect(state.isVisible)
        state.update(at: .seconds(3))
        #expect(!state.isVisible)
    }

    @Test("Hover keeps controls visible and leaving restarts the deadline")
    func controlHover() {
        var state = WindowControlVisibilityState()
        state.recordPointerActivity(at: .zero)
        state.setPointerOverControl(true, at: .seconds(1))
        state.update(at: .seconds(5))
        #expect(state.isVisible)
        #expect(state.nextHideDeadline == nil)

        state.setPointerOverControl(false, at: .seconds(5))
        #expect(state.nextHideDeadline == .seconds(7))
        state.update(at: .seconds(7))
        #expect(!state.isVisible)
    }

    @Test("Pointer exit clears control hover and teardown resets state")
    func exitAndReset() {
        var state = WindowControlVisibilityState()
        state.recordPointerActivity(at: .zero)
        state.setPointerOverControl(true, at: .seconds(1))
        state.pointerExitedWindow(at: .seconds(2))
        #expect(state.nextHideDeadline == .seconds(4))
        state.update(at: .seconds(4))
        #expect(!state.isVisible)

        state.recordPointerActivity(at: .seconds(5))
        state.reset()
        #expect(state == WindowControlVisibilityState())
    }
}
```

Add `EWClock/macOS/WindowControlVisibilityState.swift` as an explicit source of `EWClockTests` in `project.yml` so the macOS-only state can be tested without compiling the AppKit bridge into the test target.

- [ ] **Step 2: Generate the project and confirm the tests fail**

Run: `xcodegen generate && xcodebuild test -project EWClock.xcodeproj -scheme EWClockTests -destination 'platform=macOS'`

Expected: compilation fails because `WindowControlVisibilityState` does not exist.

- [ ] **Step 3: Implement the state type**

Create `EWClock/macOS/WindowControlVisibilityState.swift`:

```swift
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

    mutating func update(at now: Duration) {
        guard !isPointerOverControl,
              let nextHideDeadline,
              now >= nextHideDeadline else {
            return
        }
        isVisible = false
        self.nextHideDeadline = nil
    }

    mutating func pointerExitedWindow(at now: Duration) {
        isPointerOverControl = false
        nextHideDeadline = isVisible
            ? now + Self.inactivityInterval
            : nil
    }

    mutating func reset() {
        self = Self()
    }
}
```

- [ ] **Step 4: Generate and run the focused tests**

Run: `xcodegen generate && xcodebuild test -project EWClock.xcodeproj -scheme EWClockTests -destination 'platform=macOS'`

Expected: all tests pass.

- [ ] **Step 5: Commit the state and tests**

Run:

```bash
git add project.yml EWClock/macOS/WindowControlVisibilityState.swift EWClockTests/ClockTests.swift EWClock.xcodeproj
git commit -m "Test Mac window control timing"
```

### Task 2: Add Cross-Platform Window Dragging

**Files:**
- Modify: `EWClock/Shared/ClockView.swift`

**Interfaces:**
- Consumes: SwiftUI `WindowDragGesture` and the existing full-window `ClockView` content shape.
- Produces: a full-content simultaneous window drag that keeps the logo button's click action.

- [ ] **Step 1: Attach the native drag gesture**

Add these modifiers after `.ignoresSafeArea()` on the root `ClockView` content:

```swift
.contentShape(Rectangle())
.simultaneousGesture(WindowDragGesture())
#if os(macOS)
.allowsWindowActivationEvents(true)
#endif
```

The simultaneous gesture lets a stationary logo press remain a button activation while drag movement is handled as window movement.

- [ ] **Step 2: Build iPhone, iPad, and Mac targets**

Run: `./script/test.sh`

Expected: unit tests pass and the iOS and macOS targets build without warnings. The iOS target covers both iPhone and iPad device families.

- [ ] **Step 3: Commit shared window dragging**

Run:

```bash
git add EWClock/Shared/ClockView.swift
git commit -m "Make the clock surface draggable"
```

### Task 3: Reveal Mac Window Controls During Pointer Activity

**Files:**
- Create: `EWClock/macOS/MacWindowControlsView.swift`
- Modify: `EWClock/macOS/EWClockMacApp.swift`

**Interfaces:**
- Consumes: the containing `NSWindow`, AppKit mouse-movement events, `ContinuousClock`, and `WindowControlVisibilityState`.
- Produces: `MacWindowControlsView`, which starts the controls hidden, reveals them during pointer movement inside the window frame, and hides them after the state deadline.

- [ ] **Step 1: Add the AppKit bridge**

Create `EWClock/macOS/MacWindowControlsView.swift` with an `NSViewRepresentable` whose coordinator:

```swift
import AppKit
import SwiftUI

struct MacWindowControlsView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WindowObserverView {
        let view = WindowObserverView()
        view.onWindowChange = { [weak coordinator = context.coordinator] window in
            coordinator?.attach(to: window)
        }
        return view
    }

    func updateNSView(_ view: WindowObserverView, context: Context) {}

    static func dismantleNSView(_ view: WindowObserverView, coordinator: Coordinator) {
        view.onWindowChange = nil
        coordinator.detach()
    }
}
```

`WindowObserverView.viewDidMoveToWindow()` reports the current window. `Coordinator.attach(to:)` first calls `detach()`, hides the three `NSWindow.ButtonType` controls, sets `window.acceptsMouseMovedEvents = true`, and installs local and global monitors for `.mouseMoved`, `.leftMouseDragged`, `.rightMouseDragged`, and `.otherMouseDragged`.

Each monitor calls one main-actor method. That method reads `NSEvent.mouseLocation`, detects whether the point falls inside the window and any standard button's screen-space frame, and updates `WindowControlVisibilityState` with `origin.duration(to: clock.now)`. An event outside the window calls `pointerExitedWindow(at:)` when needed so control hover cannot remain stuck. The coordinator applies `isHidden = !state.isVisible` to all three buttons and schedules one cancellable `Task` for `nextHideDeadline`.

The deadline task sleeps until the deadline, checks the pointer against the standard controls again, calls `state.update(at:)`, applies visibility, and clears itself. If the pointer is over a control, it calls `setPointerOverControl(true, at:)` and waits for the next movement event. `detach()` cancels the task, removes both event monitors, restores the prior `acceptsMouseMovedEvents` value, resets the state, and clears the weak window reference. The state test verifies that reset removes the pending deadline so detached work cannot change visibility later.

- [ ] **Step 2: Overlay the bridge without changing layout**

Update the Mac scene content in `EWClock/macOS/EWClockMacApp.swift`:

```swift
ClockView(isLogoVisible: $isLogoVisible)
    .overlay {
        MacWindowControlsView()
            .allowsHitTesting(false)
    }
    .toolbarVisibility(.hidden, for: .windowToolbar)
```

The transparent observer does not take layout space or intercept clicks, drags, or edge resizing.

- [ ] **Step 3: Run the complete automated checks**

Run: `./script/test.sh`

Expected: all unit tests pass, both platform targets build, and no warning is emitted.

- [ ] **Step 4: Run the Mac app and verify interactions**

Run: `./script/build_and_run.sh`

Verify that:

- dragging the background, digits, progress bars, and logo moves the window;
- clicking the logo without dragging dismisses it;
- dragging an inactive window activates and moves it;
- edge resizing still works;
- pointer movement over the content or title-bar region reveals all three controls;
- two seconds without movement hides the controls;
- hovering a control keeps it visible; and
- close, minimize, and zoom keep their standard behavior.

- [ ] **Step 5: Update the durable product rules**

Edit `AGENTS.md` so the interaction rule allows full-content window dragging on every platform and documents the two-second Mac window-control reveal behavior. Keep the existing restriction against unrelated controls, settings, gestures, networking, analytics, and persistence.

- [ ] **Step 6: Commit and push the completed feature**

Run:

```bash
git add AGENTS.md EWClock/macOS/MacWindowControlsView.swift EWClock/macOS/EWClockMacApp.swift
git commit -m "Reveal Mac window controls on pointer activity"
git push origin main
```

Expected: `origin/main` contains the complete tested feature and its documentation.
