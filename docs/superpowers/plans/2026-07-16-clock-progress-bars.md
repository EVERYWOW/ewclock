# Clock Progress Bars Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add smooth white bars that show progress through the current hour and minute along the top and bottom edges of EW Clock.

**Architecture:** Keep the existing clock text on its one-second timeline. Calculate progress and rectangle geometry in small shared value types, then draw both bars in a separate animation timeline between the clock and logo layers.

**Tech Stack:** Swift 6, SwiftUI, Foundation, CoreGraphics, Swift Testing, XcodeGen

## Global Constraints

- Support iOS, iPadOS, and macOS 26.0 or later with no third-party runtime dependencies.
- Keep the background pure black and the bars pure white.
- Base each bar’s height on `0.005 × available width` and cover safe-area regions.
- Keep the bars noninteractive and hidden from accessibility.
- Preserve the existing clock typography, logo display and dismissal, idle-timer behavior, and window behavior.
- Use `project.yml` as the Xcode project source of truth and do not hand-edit the generated project.
- Preserve unrelated local logo changes.

---

### Task 1: Time Progress Calculation

**Files:**
- Create: `EWClock/Shared/ClockProgress.swift`
- Create: `EWClockTests/ClockProgressTests.swift`

**Interfaces:**
- Consumes: `Foundation.Date` and a supplied `Foundation.Calendar`.
- Produces: `ClockProgress.init(date:calendar:)`, `ClockProgress.hourFraction: Double`, and `ClockProgress.minuteFraction: Double`.

- [ ] **Step 1: Write the failing time-progress tests**

```swift
import CoreGraphics
import Foundation
import Testing

@Suite("Clock progress")
struct ClockProgressTests {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("Hour and minute progress include fractional seconds")
    func fractionalProgress() {
        let date = utcCalendar.date(
            from: DateComponents(
                year: 2026,
                month: 7,
                day: 16,
                hour: 12,
                minute: 30,
                second: 30,
                nanosecond: 250_000_000
            )
        )!
        let progress = ClockProgress(date: date, calendar: utcCalendar)

        #expect(abs(progress.hourFraction - (1_830.25 / 3_600)) < 0.000_001)
        #expect(abs(progress.minuteFraction - (30.25 / 60)) < 0.000_001)
    }

    @Test("Progress resets at hour and minute boundaries")
    func resets() {
        let date = utcCalendar.date(
            from: DateComponents(
                year: 2026,
                month: 7,
                day: 16,
                hour: 13
            )
        )!
        let progress = ClockProgress(date: date, calendar: utcCalendar)

        #expect(progress.hourFraction == 0)
        #expect(progress.minuteFraction == 0)
    }
}
```

- [ ] **Step 2: Run the focused tests and verify that they fail**

Run: `xcodegen generate && xcodebuild -project EWClock.xcodeproj -scheme EWClockTests -destination 'platform=macOS' -derivedDataPath build/DerivedData test -only-testing:EWClockTests/ClockProgressTests`

Expected: FAIL because `ClockProgress` is not defined.

- [ ] **Step 3: Implement the time-progress value**

```swift
import Foundation

struct ClockProgress: Equatable, Sendable {
    let hourFraction: Double
    let minuteFraction: Double

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents(
            [.minute, .second, .nanosecond],
            from: date
        )
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        let fractionalSecond = Double(components.nanosecond ?? 0)
            / 1_000_000_000

        hourFraction = Self.clamp(
            ((minute * 60) + second + fractionalSecond) / 3_600
        )
        minuteFraction = Self.clamp(
            (second + fractionalSecond) / 60
        )
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
```

- [ ] **Step 4: Run the focused tests and verify that they pass**

Run the command from Step 2.

Expected: `ClockProgressTests` passes.

### Task 2: Progress-Bar Geometry

**Files:**
- Create: `EWClock/Shared/ClockProgressLayout.swift`
- Modify: `EWClockTests/ClockProgressTests.swift`

**Interfaces:**
- Consumes: `CGSize`, `ClockProgress.hourFraction`, and `ClockProgress.minuteFraction`.
- Produces: `ClockProgressLayout.init(availableSize:hourFraction:minuteFraction:)`, `ClockProgressLayout.thickness`, `ClockProgressLayout.topFrame`, and `ClockProgressLayout.bottomFrame`.

- [ ] **Step 1: Add failing layout tests**

```swift
@Suite("Clock progress layout")
struct ClockProgressLayoutTests {
    @Test("Bars use width-based thickness and elapsed widths")
    func normalGeometry() {
        let layout = ClockProgressLayout(
            availableSize: CGSize(width: 1_000, height: 400),
            hourFraction: 0.5,
            minuteFraction: 1
        )

        #expect(layout.thickness == 5)
        #expect(layout.topFrame == CGRect(x: 0, y: 0, width: 500, height: 5))
        #expect(layout.bottomFrame == CGRect(x: 0, y: 395, width: 1_000, height: 5))
    }

    @Test("Elapsed widths clamp from zero through full width")
    func clampedWidths() {
        let layout = ClockProgressLayout(
            availableSize: CGSize(width: 800, height: 300),
            hourFraction: -1,
            minuteFraction: 2
        )

        #expect(layout.topFrame.width == 0)
        #expect(layout.bottomFrame.width == 800)
    }

    @Test("Thickness clamps to a degenerate available height")
    func degenerateHeight() {
        let layout = ClockProgressLayout(
            availableSize: CGSize(width: 1_000, height: 1),
            hourFraction: 0.5,
            minuteFraction: 0.5
        )

        #expect(layout.thickness == 1)
        #expect(layout.topFrame.minY == 0)
        #expect(layout.bottomFrame.minY == 0)
    }
}
```

- [ ] **Step 2: Run the focused layout tests and verify that they fail**

Run: `xcodegen generate && xcodebuild -project EWClock.xcodeproj -scheme EWClockTests -destination 'platform=macOS' -derivedDataPath build/DerivedData test -only-testing:EWClockTests/ClockProgressTests -only-testing:EWClockTests/ClockProgressLayoutTests`

Expected: FAIL because `ClockProgressLayout` is not defined.

- [ ] **Step 3: Implement the layout value**

```swift
import CoreGraphics

struct ClockProgressLayout: Equatable, Sendable {
    static let thicknessFraction: CGFloat = 0.005

    let thickness: CGFloat
    let topFrame: CGRect
    let bottomFrame: CGRect

    init(
        availableSize: CGSize,
        hourFraction: Double,
        minuteFraction: Double
    ) {
        let width = max(availableSize.width, 0)
        let height = max(availableSize.height, 0)
        thickness = min(width * Self.thicknessFraction, height)
        topFrame = CGRect(
            x: 0,
            y: 0,
            width: width * Self.clamp(hourFraction),
            height: thickness
        )
        bottomFrame = CGRect(
            x: 0,
            y: height - thickness,
            width: width * Self.clamp(minuteFraction),
            height: thickness
        )
    }

    private static func clamp(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, 0), 1))
    }
}
```

- [ ] **Step 4: Run the focused progress tests and verify that they pass**

Run the command from Task 2, Step 2.

Expected: `ClockProgressTests` and `ClockProgressLayoutTests` pass.

### Task 3: Smooth SwiftUI Bars

**Files:**
- Create: `EWClock/Shared/ClockProgressBarsView.swift`
- Modify: `EWClock/Shared/ClockView.swift`
- Regenerate: `EWClock.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: `ClockProgress.init(date:)` and `ClockProgressLayout.init(availableSize:hourFraction:minuteFraction:)`.
- Produces: `ClockProgressBarsView`, a decorative SwiftUI layer used by `ClockView`.

- [ ] **Step 1: Add the animated progress-bar view**

```swift
import SwiftUI

struct ClockProgressBarsView: View {
    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { context in
                let progress = ClockProgress(date: context.date)
                let layout = ClockProgressLayout(
                    availableSize: geometry.size,
                    hourFraction: progress.hourFraction,
                    minuteFraction: progress.minuteFraction
                )

                Canvas { context, _ in
                    context.fill(
                        Path(layout.topFrame),
                        with: .color(.white)
                    )
                    context.fill(
                        Path(layout.bottomFrame),
                        with: .color(.white)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
```

- [ ] **Step 2: Place the bars between the clock and logo layers**

Inside the existing `ZStack`, add the following after the clock `TimelineView` closes and before `if isLogoVisible`:

```swift
ClockProgressBarsView()
```

- [ ] **Step 3: Regenerate the Xcode project**

Run: `xcodegen generate`

Expected: `EWClock.xcodeproj/project.pbxproj` includes the three new shared files and the new test file.

- [ ] **Step 4: Run the complete verification script**

Run: `./script/test.sh`

Expected: all unit tests pass, then the generic iOS Simulator and macOS builds finish with `BUILD SUCCEEDED`.

- [ ] **Step 5: Check the app visually**

Run the Mac app with `./script/build_and_run.sh`, then launch the available iPhone and iPad simulators from the generated project. Confirm smooth movement, top and bottom edge placement, safe-area coverage, resizing and rotation, pure-white elapsed areas, black remaining areas, and unchanged logo dismissal.

Expected: the top bar tracks the current hour, the bottom bar tracks the current minute, and both adapt to each available size without affecting the clock or logo.

- [ ] **Step 6: Stage and review the focused diff**

Stage the new progress-bar files and plan. Select only the progress-bar hunks from overlapping modified files, including `ClockView.swift` and the generated project file. Do not stage unrelated logo work.

Run: `git diff --cached --check && git diff --cached`

Expected: no whitespace errors, no changes to logo behavior, and only the planned progress-bar plan, source, tests, integration, and generated file references.

- [ ] **Step 7: Commit the completed feature and push main**

```bash
git commit -m "Add smooth clock progress bars"
git push origin main
```

Expected: the focused feature commit and the earlier specification commit are present on `origin/main` without Apple credentials, signing files, or unrelated changes.
