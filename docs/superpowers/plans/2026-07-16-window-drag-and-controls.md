# Window Drag and Mac Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users drag an EW Clock window from its full content area and reveal the standard Mac window controls during pointer activity.

**Architecture:** The shared `ClockView` adds SwiftUI’s window-drag gesture only when compiled for macOS, because the API is unavailable on iOS and iPadOS. A macOS-only controller owned by the application delegate observes the clock window and delegates testable deadline decisions to a pure state type.

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

### Task 2: Add Mac Window Dragging

**Files:**
- Modify: `EWClock/Shared/ClockView.swift`

**Interfaces:**
- Consumes: SwiftUI `WindowDragGesture` and the existing full-window `ClockView` content shape.
- Produces: a full-content simultaneous Mac window drag that keeps the logo button’s click action.

- [ ] **Step 1: Attach the native drag gesture**

Add these modifiers after `.ignoresSafeArea()` on the root `ClockView` content:

```swift
.contentShape(Rectangle())
#if os(macOS)
.simultaneousGesture(WindowDragGesture())
.allowsWindowActivationEvents(true)
#endif
```

The simultaneous gesture lets a stationary logo press remain a button activation while drag movement is handled as window movement. The conditional compilation is required because SwiftUI marks `WindowDragGesture` unavailable on iOS and iPadOS 26.

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
- Create: `EWClock/macOS/MacWindowControlsController.swift`
- Modify: `EWClock/macOS/EWClockMacApp.swift`

**Interfaces:**
- Consumes: the app’s clock `NSWindow`, a common-mode pointer polling timer, `ContinuousClock`, and `WindowControlVisibilityState`.
- Produces: `MacWindowControlsController`, which starts the controls hidden, reveals them during pointer movement inside the window frame, and hides them after the state deadline.

- [ ] **Step 1: Add the AppKit bridge**

Create `EWClock/macOS/MacWindowControlsController.swift` as a main-actor `NSObject`. Its `start()` method observes `NSWindow.didBecomeKeyNotification` and `NSWindow.didBecomeMainNotification`, then attaches to the clock window by identifier or title. Its `stop()` method removes observers and detaches.

`attach(to:)` first calls `detach()`, saves the three standard buttons’ prior hidden states, hides them, and starts a `Timer` with a 0.05-second interval in the main run loop’s common mode.

Each timer tick reads `NSEvent.mouseLocation`, detects whether the point falls inside the window and any standard button’s screen-space frame, and updates `WindowControlVisibilityState` with `origin.duration(to: clock.now)`. A point outside the window calls `pointerExitedWindow(at:)` when needed so control hover cannot remain stuck. The controller applies `isHidden = !state.isVisible` to all three buttons.

`detach()` invalidates the timer, restores the buttons’ prior hidden states, resets the state, and clears the weak window reference. The state test verifies that reset removes the pending deadline so detached work cannot change visibility later.

- [ ] **Step 2: Preserve the native controls and start the controller**

Keep the toolbar present so AppKit retains its native controls, but hide its title and background:

```swift
ClockView(isLogoVisible: $isLogoVisible)
    .toolbar(removing: .title)
    .toolbarVisibility(.visible, for: .windowToolbar)
    .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
```

The application delegate owns `MacWindowControlsController`, calls `start()` after launch, and calls `stop()` before termination.

- [ ] **Step 3: Run the complete automated checks**

Run: `./script/test.sh`

Expected: all unit tests pass, both platform targets build, and no new warning is emitted.

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

Edit `AGENTS.md` so the interaction rule allows full-content Mac window dragging and documents the two-second Mac window-control reveal behavior. Keep the existing restriction against unrelated controls, settings, gestures, networking, analytics, and persistence.

- [ ] **Step 6: Commit and push the completed feature**

Run:

```bash
git add AGENTS.md EWClock/macOS/MacWindowControlsController.swift EWClock/macOS/EWClockMacApp.swift
git commit -m "Reveal Mac window controls on pointer activity"
git push origin main
```

Expected: `origin/main` contains the complete tested feature and its documentation.
