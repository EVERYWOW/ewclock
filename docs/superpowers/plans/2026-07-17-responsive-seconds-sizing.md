# Responsive Seconds Sizing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Preserve the 98% width of `HH:MM` and reduce only the seconds line when the clock block would otherwise exceed 90% of the available height.

**Architecture:** `ClockTypography` owns the width-first and height-limited font calculation. `ClockView` passes its available size, while the glyph renderer omits seconds when their calculated font size is zero. The README keeps its existing image reference and uses a newly captured iPhone landscape screenshot at that path.

**Tech Stack:** Swift 6, SwiftUI, CoreText, Swift Testing, XcodeGen, Xcode Simulator tools

## Global Constraints

- Keep the `HH:MM` measured advance width at exactly `0.98 × available width`.
- Keep the line gap at `0.1 ×` the `HH:MM` font size.
- Start seconds at two-thirds of the `HH:MM` font size and reduce only seconds when the block would otherwise exceed 90% of the available height.
- Clamp the seconds font size between zero and the two-thirds size.
- Keep the complete clock block centered vertically and horizontally.
- Preserve the fixed slots, pure-black background, pure-white clock, progress bars, and EVERYWOW logo behavior.
- Support iOS, iPadOS, and macOS 26.0 or later without third-party runtime dependencies.

---

### Task 1: Height-Limited Typography

**Files:**
- Modify: `EWClockTests/ClockTests.swift`
- Modify: `EWClock/Shared/ClockTypography.swift`
- Modify: `EWClock/Shared/ClockView.swift`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: `ClockTypography.Metrics`, `GeometryProxy.size`, and the existing CoreText ascent and descent metrics.
- Produces: `ClockTypography.layout(availableSize:metrics:) -> ClockTypography.Layout` with width-based main sizing and height-limited seconds sizing.

- [ ] **Step 1: Write failing typography tests**

Update layout calls to pass `CGSize`, then add tests that prove a tall window keeps the two-thirds seconds size, a constrained window shrinks seconds until `blockHeight == 0.9 × height`, and a shorter window clamps seconds to zero without rendering a fallback seconds glyph. Use the calculated main line height and line gap to construct deterministic height limits from the font metrics.

```swift
let unconstrained = ClockTypography.layout(
    availableSize: CGSize(width: 1_200, height: 1_000),
    metrics: metrics
)
#expect(
    abs(unconstrained.secondsFontSize - ((2.0 / 3.0) * unconstrained.mainFontSize))
        < 0.000_001
)

let halfSecondsHeight = unconstrained.secondsLineHeight / 2
let constrainedHeight = (
    unconstrained.mainLineHeight + unconstrained.lineGap + halfSecondsHeight
) / 0.9
let constrained = ClockTypography.layout(
    availableSize: CGSize(width: 1_200, height: constrainedHeight),
    metrics: metrics
)
#expect(abs(constrained.secondsFontSize - (unconstrained.secondsFontSize / 2)) < 0.000_001)
#expect(abs(constrained.blockHeight - (0.9 * constrainedHeight)) < 0.000_001)
#expect(abs(constrained.blockOriginY(canvasHeight: constrainedHeight) - (0.05 * constrainedHeight)) < 0.000_001)

let secondsFreeHeight = (
    unconstrained.mainLineHeight + unconstrained.lineGap
) / 0.9 - 1
let secondsFree = ClockTypography.layout(
    availableSize: CGSize(width: 1_200, height: secondsFreeHeight),
    metrics: metrics
)
#expect(secondsFree.secondsFontSize == 0)
#expect(secondsFree.secondsLineHeight == 0)

let time = ClockTime(
    date: Date(timeIntervalSince1970: 0),
    timeZone: TimeZone(secondsFromGMT: 0)!
)
let canvasSize = CGSize(width: 1_200, height: secondsFreeHeight)
let path = ClockTypography.glyphPath(
    time: time,
    layout: secondsFree,
    canvasSize: canvasSize,
    fontName: BrandFont.postScriptName
)
let mainLineMaxY = secondsFree.blockOriginY(canvasHeight: canvasSize.height)
    + secondsFree.mainLineHeight
#expect(!path.isEmpty)
#expect(path.boundingBoxOfPath.maxY <= mainLineMaxY + 0.000_001)
```

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```bash
./script/generate.sh
xcodebuild -project EWClock.xcodeproj -scheme EWClockTests -destination 'platform=macOS' -derivedDataPath build/DerivedData test
```

Expected: compilation fails because `layout(availableSize:metrics:)` does not exist.

- [ ] **Step 3: Implement the size-aware layout**

Change the layout entry point to accept `CGSize`. Derive the main size from `availableSize.width`, calculate the remaining line height inside `0.9 × availableSize.height`, and use the reference font’s combined ascent and descent to calculate the seconds size.

```swift
static func layout(availableSize: CGSize, metrics: Metrics) -> Layout {
    precondition(availableSize.height >= 0, "Available height cannot be negative")
    precondition(
        metrics.ascent + metrics.descent > 0,
        "Reference line height must be positive"
    )

    let mainFontSize = mainFontSize(
        availableWidth: availableSize.width,
        metrics: metrics
    )
    let normalSecondsFontSize = mainFontSize * (2.0 / 3.0)
    let mainScale = mainFontSize / metrics.referenceSize
    let lineGap = mainFontSize * 0.1
    let mainLineHeight = (metrics.ascent + metrics.descent) * mainScale
    let allowedSecondsLineHeight = max(
        0,
        (0.9 * availableSize.height) - mainLineHeight - lineGap
    )
    let referenceLineHeight = metrics.ascent + metrics.descent
    let heightLimitedSecondsFontSize = metrics.referenceSize
        * (allowedSecondsLineHeight / referenceLineHeight)
    let secondsFontSize = min(
        normalSecondsFontSize,
        heightLimitedSecondsFontSize
    )
    let secondsScale = secondsFontSize / metrics.referenceSize

    return Layout(
        mainFontSize: mainFontSize,
        secondsFontSize: secondsFontSize,
        mainSegmentWidth: metrics.segmentAdvance * mainScale,
        mainColonWidth: metrics.colonAdvance * mainScale,
        secondsSegmentWidth: metrics.segmentAdvance * secondsScale,
        mainAscent: metrics.ascent * mainScale,
        mainDescent: metrics.descent * mainScale,
        secondsAscent: metrics.ascent * secondsScale,
        secondsDescent: metrics.descent * secondsScale,
        lineGap: lineGap
    )
}
```

Calculate the logo inset directly from the width-based main font size. In `glyphPath`, create and append the seconds font and path only when `layout.secondsFontSize > 0`. In `ClockView`, pass the full `geometry.size` to `clockRun`, then pass that size into `ClockTypography.layout`. Update the durable typography rules in `AGENTS.md` with the height constraint.

- [ ] **Step 4: Run the complete project checks**

Run:

```bash
./script/test.sh
```

Expected: all unit tests pass, and the iOS Simulator and macOS builds finish without warnings or errors.

### Task 2: Updated iPhone README Screenshot

**Files:**
- Modify: `docs/screenshots/ew-clock-iphone-landscape.png`
- Verify: `README.md`

**Interfaces:**
- Consumes: the simulator build at `build/DerivedData/Build/Products/Debug-iphonesimulator/EW Clock.app` and one booted iPhone 17 Pro simulator resolved at runtime.
- Produces: a current landscape screenshot at the existing README image path.

- [ ] **Step 1: Install and launch the updated app**

Run:

```bash
IPHONE_UDID="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone 17 Pro .*Booted/ { print $2 }')"
test -n "$IPHONE_UDID"
test "$(printf '%s\n' "$IPHONE_UDID" | wc -l | tr -d ' ')" = "1"
xcrun simctl install "$IPHONE_UDID" 'build/DerivedData/Build/Products/Debug-iphonesimulator/EW Clock.app'
xcrun simctl launch "$IPHONE_UDID" ch.everywow.clock
osascript -e 'tell application "Simulator" to activate' -e 'tell application "System Events" to keystroke (ASCII character 28) using command down'
```

Expected: EW Clock is visible on the iPhone 17 Pro simulator in landscape orientation.

- [ ] **Step 2: Capture the README image**

Run:

```bash
IPHONE_UDID="$(xcrun simctl list devices available | awk -F '[()]' '/iPhone 17 Pro .*Booted/ { print $2 }')"
xcrun simctl io "$IPHONE_UDID" screenshot docs/screenshots/ew-clock-iphone-landscape.png
sips --rotate 270 docs/screenshots/ew-clock-iphone-landscape.png
```

Expected: the file is replaced with a 2,622 × 1,206 landscape screenshot.

- [ ] **Step 3: Inspect the screenshot and README reference**

Open the PNG and confirm that the background is black, the clock is white, `HH:MM` spans 98% of the width, the complete clock block leaves at least 5% above and below it when the height constraint can be met, both progress bars are visible, and the EVERYWOW logo remains visible. Confirm `README.md` still references `docs/screenshots/ew-clock-iphone-landscape.png`.

- [ ] **Step 4: Commit and push the implementation**

Run:

```bash
git add AGENTS.md EWClock/Shared/ClockTypography.swift EWClock/Shared/ClockView.swift EWClockTests/ClockTests.swift docs/screenshots/ew-clock-iphone-landscape.png docs/superpowers/plans/2026-07-17-responsive-seconds-sizing.md
git diff --cached --check
git commit -m "Keep vertical clock margins"
git push origin main
```

Expected: the focused implementation commit is created and `main` is pushed successfully.
