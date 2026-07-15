# EW Clock Design

## Purpose

EW Clock is a set clock for iPhone, iPad, and Mac. It shows the current local time in 24-hour format with `HH:MM` above `SS` and keeps the display awake. The app has no settings, buttons, gestures, network access, data collection, or persistence.

## Platforms and Distribution

- App name: `EW Clock`
- Bundle identifier: `ch.everywow.clock`
- App Store Connect SKU: `everywow-clock`
- Version: `1.0`
- Initial build number: `1`
- Minimum systems: iOS 26.0, iPadOS 26.0, and macOS 26.0
- Build tools: Xcode 26.6 with the iOS 26.5 and macOS 26.5 software development kits
- Apple team: EVERYWOW AG (`L69664DD39`)
- Distribution: one App Store Connect record with separate iPhone/iPad and Mac builds
- Intended TestFlight group: `EVERYWOW Internal`
- Intended testers: `stefanie@hetjens.com` and `production@everywow.ch`

If either email address is not already an App Store Connect user, account access must be resolved before it can join an internal TestFlight group. No credentials, tokens, or private keys belong in the repository.

## Project Structure

The repository uses XcodeGen. `project.yml` is the source of truth and generates one iOS target, one macOS target, and shared tests. Both app targets compile the same clock, formatting, typography, and resource code. Small platform-specific files manage display sleep and window or scene behavior.

The project has no third-party runtime dependencies. The EVERYWOW Display font is stored at `EWClock/Resources/EVERYWOWDisplayVF.ttf`. Its variable weight axis runs from 300 through 900, and the weight-900 PostScript instance used at runtime is `EVERYWOWDisplay-Black`.

## Clock Presentation

The whole scene or content window is pure black. The time is pure white and centered horizontally and vertically.

The clock is a two-line block with `HH:MM` on the first line and `SS` on the second. The first line's complete typographic advance width is 98% of the current screen or window width in portrait, landscape, full-screen, and windowed presentations. The seconds use two-thirds of the first line's font size and are centered beneath it. The combined two-line block is centered horizontally and vertically. Resizing or rotating recalculates both sizes immediately.

The display uses EVERYWOW Display at variable weight 900, which the font identifies as Black. The bundled source is `EVERYWOWDisplayVF.ttf` from the EVERYWOW website. EVERYWOW AG has authorized its use for this app.

Hours, minutes, and seconds are separate two-character segments. Each segment reserves the maximum advance measured across every ASCII value from `00` through `99` and centers its current value within that width. In the approved font, `00`, `04`, `40`, and `44` share the maximum advance. One fixed colon slot separates hours and minutes. The first-line reference run is exactly two maximum segment advances plus one measured colon advance, with zero implicit horizontal padding. The main font size scales this run to `0.98 × available width`. Seconds use a second fixed segment slot at two-thirds of the main font size. CoreText ascent and descent metrics define each line box. A gap equal to `0.1 ×` the main font size separates the line boxes, and their combined height is centered vertically. This keeps every glyph position stable as the digits change.

## Timekeeping

The clock reads the system time and automatically follows the system time zone. A second-aligned SwiftUI timeline refreshes the display once per second. Formatting uses a Gregorian calendar and ASCII digits to guarantee `00:00:00` through `23:59:59`, independent of the user’s 12-hour preference.

The first rendered value uses the current time immediately. Later updates derive from the current date rather than incrementing a counter, so pauses or scheduling delays cannot make the clock drift.

## Platform Behavior

On iPhone and iPad, the app supports portrait and landscape and fills the available scene. The target sets `UIRequiresFullScreen = true` for the legacy full-screen preference and applies SwiftUI’s `.persistentSystemOverlays(.hidden)` to request hidden status, Home, and multitasking overlays. iPadOS 26 may keep the app in a window when Windowed Apps is enabled; the clock adapts to that window.

The iOS target defines `UILaunchScreen.UIColorName = LaunchBackground`, backed by a pure-black `LaunchBackground.colorset`, so startup does not flash white before SwiftUI renders.

The iOS idle timer is disabled only while the scene is active and restored when it becomes inactive or moves to the background.

On Mac, the app opens one normal resizable window rather than entering full screen. The content has no toolbar or app controls. A process activity assertion prevents display sleep for as long as EW Clock is running, and the assertion ends during app termination.

## Branding

The app icon copies `/Users/steffi/dev/ewtools/scripts/assets/everywow-favicon.png`, the 1,024 × 1,024 EVERYWOW company-logo source used by the existing EVERYWOW app, into `EWClock/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`. The repository copy is the operational source on every computer; the external path records its provenance. The same company-logo artwork is the universal icon for iPhone, iPad, and Mac. When a distinct dark or tinted asset is absent, the system uses its standard rendering of the universal artwork.

## Verification

Automated tests cover midnight, noon, single-digit padding, time-zone conversion, segment parsing, the 98% first-line calculation, the two-thirds seconds scale, stable slot centers, and centered two-line geometry. Build checks cover iOS Simulator, a generic signed iOS archive, macOS, and a signed Mac archive.

Visual checks use available iPhone and iPad simulators plus the local Mac app. They confirm the black background, white font, two-line centering, fixed segment positions, both mobile orientations, Mac resizing, 98% first-line width, and the two-thirds seconds scale. A release check confirms the embedded font, icon, bundle identifiers, versions, signing team, and absence of network or privacy-sensitive capabilities.

## Repository Memory

`AGENTS.md` records the durable product rules, project commands, signing identifiers, and release process for future work. Secrets and ephemeral account sessions are excluded.

`EW Clock` is the user-approved product name and the only allowed abbreviation of EVERYWOW in written copy. Use `EVERYWOW` everywhere else.
