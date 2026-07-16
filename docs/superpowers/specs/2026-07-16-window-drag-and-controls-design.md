# Window Drag and Mac Controls Design

## Purpose

EW Clock should let the user move a window by dragging anywhere within its content. The Mac window should show its standard close, minimize, and zoom controls while the pointer is active over the window, then return to a clean clock display after pointer inactivity.

This approved feature supersedes the earlier product rule that prohibited gestures. Window dragging is the only added gesture. It does not add an app-specific control.

## Window Dragging

The shared clock view uses SwiftUI’s `WindowDragGesture`, which is available on iOS, iPadOS, and macOS 26. The gesture covers the full content area, including the digits, progress bars, black background, and EVERYWOW logo hit target. Dragging from any of these regions moves a Mac or windowed iPad app window. The gesture has no visible effect when the app fills an iPhone or iPad screen.

The window drag gesture runs alongside the logo button interaction. A press and release on the logo without drag movement hides the logo. Movement that becomes a window drag cancels the logo action and moves the window.

The Mac view accepts window activation events so a drag that begins in an inactive window activates and moves it in one action. The app keeps its normal resizable window, including edge resizing, and does not enter full screen automatically.

## Mac Window Controls

The Mac app uses a narrow AppKit bridge because SwiftUI does not expose the visibility of the standard window controls. The bridge accesses only its containing `NSWindow`, observes pointer position across the window frame, and updates the close, minimize, and zoom controls together.

The controls start hidden when the window appears. Pointer entry or movement anywhere within the window frame, including its content and title-bar region, shows all three controls immediately and starts a two-second inactivity deadline. Further movement or window dragging replaces that deadline. Leaving the window does not hide the controls immediately; they hide when the current deadline expires.

The controls stay visible while the pointer is directly over any of them. Once the pointer leaves the controls, the two-second deadline starts again. They remain standard AppKit controls with their normal pointer actions and appearance. When hidden, their standard menu and keyboard equivalents remain available.

The bridge removes observers and timers from the previous view or window before attaching to another one. SwiftUI dismantling the bridge cancels all pending work, so a delayed callback cannot update a detached window. The bridge does not own the window or store window state outside the current process.

## Existing Interaction

The EVERYWOW logo remains the only app-specific control. Clicking or tapping it hides only the logo for the current session. Dragging and window-control visibility do not affect the clock layout.

## Verification

Automated tests cover the initial hidden state, immediate reveal, the two-second inactivity deadline, repeated activity, pointer exit, control hover, and teardown without a delayed callback. Platform builds confirm that the shared drag gesture compiles for iPhone, iPad, and Mac.

A Mac app run confirms that dragging from the background, digits, progress bars, and logo moves active and inactive windows; a click without movement still dismisses the logo; edge resizing still works; pointer activity across the content and title-bar region reveals the window controls; inactivity hides them; hovering a control keeps it visible; and all three standard actions still work.
