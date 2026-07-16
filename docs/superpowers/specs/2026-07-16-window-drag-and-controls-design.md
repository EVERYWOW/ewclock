# Window Drag and Mac Controls Design

## Purpose

EW Clock should let the user move its Mac window by dragging anywhere within its content. The Mac window should show its standard close, minimize, and zoom controls while the pointer is active over the window, then return to a clean clock display after pointer inactivity.

This approved feature supersedes the earlier product rule that prohibited gestures. Window dragging is the only added gesture. It does not add an app-specific control.

## Window Dragging

The Mac clock view uses SwiftUI’s `WindowDragGesture`. The gesture covers the full content area, including the digits, progress bars, black background, and EVERYWOW logo hit target. Dragging from any of these regions moves the Mac window.

SwiftUI explicitly marks `WindowDragGesture` unavailable on iOS and iPadOS 26. iPhone apps fill their screen, and iPadOS owns movement of app windows through its system window chrome. EW Clock does not attempt to replace that system behavior with a private or simulated drag API.

The window drag gesture runs alongside the logo button interaction. A press and release on the logo without drag movement hides the logo. Movement that becomes a window drag cancels the logo action and moves the window.

The Mac view accepts window activation events so a drag that begins in an inactive window activates and moves it in one action. The app keeps its normal resizable window, including edge resizing, and does not enter full screen automatically.

## Mac Window Controls

The Mac app keeps the window toolbar visible while hiding its title and background. This preserves the native controls. A narrow AppKit controller observes the app’s clock window, checks pointer position across its frame, and updates the close, minimize, and zoom controls together because SwiftUI does not expose their visibility.

The controls start hidden when the window appears. Pointer entry or movement anywhere within the window frame, including its content and title-bar region, shows all three controls immediately and starts a two-second inactivity deadline. Further movement or window dragging replaces that deadline. Leaving the window restarts the two-second deadline instead of hiding the controls immediately.

The controls stay visible while the pointer is directly over any of them. Once the pointer leaves the controls, the two-second deadline starts again. They remain standard AppKit controls with their normal pointer actions and appearance. When hidden, their standard menu and keyboard equivalents remain available.

Before attaching to another window, `MacWindowControlsController` invalidates its polling timer and restores the previous window controls’ hidden states. `stop()` removes the application-level window observers and detaches the controller. The controller keeps a weak window reference and stores no window state outside the current process.

## Existing Interaction

The EVERYWOW logo remains the only app-specific control. Clicking or tapping it hides only the logo for the current session. Dragging and window-control visibility do not affect the clock layout.

## Verification

Automated tests cover the initial hidden state, immediate reveal, the two-second inactivity deadline, repeated activity, pointer exit, control hover, and teardown without a delayed callback. Platform builds confirm that the Mac drag gesture compiles without changing the iPhone and iPad clock.

A Mac app run confirms that dragging from the background, digits, progress bars, and logo moves active and inactive windows; a click without movement still dismisses the logo; edge resizing still works; pointer activity across the content and title-bar region reveals the window controls; inactivity hides them; hovering a control keeps it visible; and all three standard actions still work.
