# Two-Line Clock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single-line clock with a stable centered `HH:MM` / `SS` layout, scale the first line to 98% of available width, render seconds at two-thirds size, and release build 2 to internal TestFlight.

**Architecture:** Extend the existing CoreText metrics and Canvas renderer rather than using SwiftUI text measurement. A layout value will calculate fixed segment geometry, both font sizes, exact CoreText line boxes, the interline gap, and a vertically centered block; `ClockView` remains the shared second-aligned presentation for iOS, iPadOS, and macOS.

**Tech Stack:** Swift 6, SwiftUI, CoreText, Swift Testing, XcodeGen, Xcode 26, App Store Connect/TestFlight.

## Global Constraints

- The first line is `HH:MM`, fixed in position, and exactly `0.98 × available width`.
- The second line is `SS`, fixed in position, centered, and uses exactly `2/3` of the main font size.
- The line-box gap is exactly `0.1 ×` the main font size; the combined block is centered vertically.
- Keep EVERYWOW Display Black, pure white glyphs, a pure black background, and no controls or added features.
- Preserve iOS/iPadOS full-screen behavior, Mac window resizing, and display-sleep prevention.
- Release both platforms as version `1.0`, build `2`, only to `EVERYWOW Internal`.

---

### Task 1: Two-Line Typography Geometry

**Files:**
- Modify: `EWClockTests/ClockTests.swift`
- Modify: `EWClock/Shared/ClockTypography.swift`

**Interfaces:**
- Consumes: `ClockTypography.metrics(fontName:referenceSize:)` and the registered `EVERYWOWDisplay-Black` font.
- Produces: `Metrics.mainReferenceAdvance`, `Layout.mainFontSize`, `Layout.secondsFontSize`, `Layout.mainRunWidth`, `Layout.blockHeight`, `Layout.mainSlots(hours:minutes:)`, and `ClockTypography.glyphPath(time:layout:canvasSize:fontName:)`.

- [ ] **Step 1: Replace the width test with failing two-line geometry assertions**

```swift
let availableWidth = 1_200.0
let layout = ClockTypography.layout(availableWidth: availableWidth, metrics: metrics)
#expect(abs(layout.mainRunWidth - (0.98 * availableWidth)) < 0.000_001)
#expect(abs(layout.secondsFontSize - ((2.0 / 3.0) * layout.mainFontSize)) < 0.000_001)
#expect(abs(layout.lineGap - (0.1 * layout.mainFontSize)) < 0.000_001)
#expect(abs(layout.blockHeight - (layout.mainLineHeight + layout.lineGap + layout.secondsLineHeight)) < 0.000_001)
```

- [ ] **Step 2: Add failing slot and glyph-path tests**

```swift
let slots = layout.mainSlots(hours: "12", minutes: "34")
#expect(slots.map(\.text) == ["12", ":", "34"])
#expect(slots.map(\.centerX) == layout.mainSlots(hours: "00", minutes: "00").map(\.centerX))

let path = ClockTypography.glyphPath(
    time: ClockTime(date: date),
    layout: layout,
    canvasSize: CGSize(width: 1_000, height: layout.blockHeight + 200),
    fontName: BrandFont.postScriptName
)
#expect(!path.isEmpty)
#expect(path.boundingBoxOfPath.midX > 0)
```

- [ ] **Step 3: Run the focused tests and verify they fail to compile against the old API**

Run: `xcodegen generate && xcodebuild test -project EWClock.xcodeproj -scheme EWClockTests -destination 'platform=macOS' -only-testing:EWClockTests/ClockTypographyTests`

Expected: failure because the two-line layout properties and `glyphPath(time:...)` do not exist.

- [ ] **Step 4: Implement the metrics and layout model**

```swift
struct Metrics: Equatable, Sendable {
    let referenceSize: CGFloat
    let widestSegment: String
    let segmentAdvance: CGFloat
    let colonAdvance: CGFloat
    let ascent: CGFloat
    let descent: CGFloat

    var mainReferenceAdvance: CGFloat {
        (2 * segmentAdvance) + colonAdvance
    }
}

struct Layout: Equatable, Sendable {
    let mainFontSize: CGFloat
    let secondsFontSize: CGFloat
    let mainSegmentWidth: CGFloat
    let mainColonWidth: CGFloat
    let secondsSegmentWidth: CGFloat
    let mainAscent: CGFloat
    let mainDescent: CGFloat
    let secondsAscent: CGFloat
    let secondsDescent: CGFloat
    let lineGap: CGFloat

    var mainRunWidth: CGFloat { (2 * mainSegmentWidth) + mainColonWidth }
    var mainLineHeight: CGFloat { mainAscent + mainDescent }
    var secondsLineHeight: CGFloat { secondsAscent + secondsDescent }
    var blockHeight: CGFloat { mainLineHeight + lineGap + secondsLineHeight }
}
```

Calculate `mainFontSize` from `0.98 * availableWidth`, calculate `secondsFontSize` as `mainFontSize * (2.0 / 3.0)`, scale all advances and vertical metrics linearly, and calculate `lineGap` as `mainFontSize * 0.1`.

- [ ] **Step 5: Implement the two-line glyph path**

Build fixed slots for `[hours, ":", minutes]`. Center the first run horizontally. Set its baseline to `blockTop + mainAscent`; set the seconds baseline to `blockTop + mainLineHeight + lineGap + secondsAscent`; center the fixed seconds segment at `canvasSize.width / 2`. Reuse the existing `append(_:centeredAt:baselineY:font:to:)` helper.

- [ ] **Step 6: Run the focused typography tests**

Run: `xcodebuild test -project EWClock.xcodeproj -scheme EWClockTests -destination 'platform=macOS' -only-testing:EWClockTests/ClockTypographyTests`

Expected: all `ClockTypographyTests` pass.

### Task 2: Shared View Integration and Full Verification

**Files:**
- Modify: `EWClock/Shared/ClockView.swift`
- Modify: `AGENTS.md` only if implementation details differ from the recorded approved specification

**Interfaces:**
- Consumes: `ClockTime` and the two-line `ClockTypography.layout`/`glyphPath` API from Task 1.
- Produces: the same control-free `ClockView` used by both platform entry points.

- [ ] **Step 1: Update the Canvas call**

```swift
let glyphPath = ClockTypography.glyphPath(
    time: time,
    layout: layout,
    canvasSize: size,
    fontName: BrandFont.postScriptName
)
```

- [ ] **Step 2: Run all automated checks**

Run: `./script/test.sh`

Expected: Swift tests, iOS Simulator build, generic iOS build, macOS build, and project consistency checks pass.

- [ ] **Step 3: Launch the Mac app and visually verify responsive layout**

Run: `./script/build_and_run.sh`

Expected: `HH:MM` occupies 98% width, `SS` is centered beneath at two-thirds size, the combined block is vertically centered, resizing does not produce ellipses, and digit changes do not shift slots.

- [ ] **Step 4: Commit the implementation**

```bash
git add EWClock/Shared/ClockTypography.swift EWClock/Shared/ClockView.swift EWClockTests/ClockTests.swift AGENTS.md
git commit -m "Update clock to two-line layout"
```

### Task 3: Build 2 TestFlight Release

**Files:**
- Modify: `project.yml`
- Modify: `AGENTS.md`

**Interfaces:**
- Consumes: the verified source from Task 2 and the existing signing/archive/upload scripts.
- Produces: iOS/iPadOS and macOS version `1.0` build `2` in the `EVERYWOW Internal` TestFlight group.

- [ ] **Step 1: Bump both targets to build 2**

Change both `CURRENT_PROJECT_VERSION: 1` settings in `project.yml` to `CURRENT_PROJECT_VERSION: 2`, then run `xcodegen generate`.

- [ ] **Step 2: Verify signing identities and rerun all tests**

Run: `security find-identity -v -p codesigning && ./script/test.sh`

Expected: valid EVERYWOW signing identities and all checks pass.

- [ ] **Step 3: Create signed archives**

Run: `./script/archive.sh`

Expected: valid `build/archives/EWClock-iOS.xcarchive` and `build/archives/EWClock-macOS.xcarchive`, both version `1.0` build `2`.

- [ ] **Step 4: Upload both archives**

Run: `./script/upload_testflight.sh all`

Expected: App Store Connect accepts both uploads without validation errors.

- [ ] **Step 5: Verify processing and internal distribution**

In App Store Connect, wait until both build 2 uploads finish processing. Confirm automatic distribution adds them to `EVERYWOW Internal`; if not, add them manually. Complete the previously approved addition of `production@everywow.ch` to the same internal group and verify its invitation status.

- [ ] **Step 6: Record the release state**

Update `AGENTS.md` to say build `2` is the current internal TestFlight release, describe its two-line 98% layout, and list confirmed internal testers without recording credentials.

- [ ] **Step 7: Commit and push**

```bash
git add project.yml EWClock.xcodeproj AGENTS.md
git commit -m "Release two-line clock to TestFlight"
git push origin main
```

Expected: `main` is clean and synchronized with `origin/main`.
