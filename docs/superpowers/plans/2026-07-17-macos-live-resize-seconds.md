# macOS Live-Resize Seconds Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Keep the seconds line responsive to the current macOS window height throughout live resizing, then publish the corrected build to internal TestFlight.

**Architecture:** `ClockTypography` already computes the correct width- and height-constrained layout for any `CGSize`. Move that calculation into the `Canvas` renderer so it uses the renderer's current size on every redraw instead of a layout captured when SwiftUI created the canvas.

**Tech Stack:** Swift 6, SwiftUI `Canvas`, Core Text, Swift Testing, XcodeGen, TestFlight.

## Global Constraints

- Keep `HH:MM` at 98% of the current width.
- Keep `SS` at two-thirds of the first-line size unless it must shrink to retain 5% top and bottom clearance.
- Preserve the pure-black background, pure-white clock, progress bars, logo behavior, and platform support.
- Release only to the existing internal TestFlight group; do not submit for external testing or App Store review.

---

### Task 1: Use the live canvas size

**Files:**
- Modify: `EWClock/Shared/ClockView.swift`
- Test: `EWClockTests/ClockTests.swift`

**Interfaces:**
- Consumes: `ClockTypography.layout(availableSize:metrics:)`
- Produces: `ClockView.clockRun(time:)`, whose `Canvas` renderer derives layout from its current `size` argument.

- [x] **Step 1: Confirm the layout engine responds to a height-only resize**

Run the existing `ClockTypographyTests.heightLimitedSeconds` test and confirm it passes. This isolates the fault to the view/rendering boundary rather than the layout equation.

```sh
xcodebuild test -project EWClock.xcodeproj -scheme EWClockTests -destination 'platform=macOS' -derivedDataPath build/DerivedData
```

- [x] **Step 2: Move layout creation into the canvas renderer**

Replace the captured layout with the canvas's live size:

```swift
private func clockRun(time: ClockTime) -> some View {
    Canvas { context, size in
        let layout = ClockTypography.layout(
            availableSize: size,
            metrics: metrics
        )
        let glyphPath = ClockTypography.glyphPath(
            time: time,
            layout: layout,
            canvasSize: size,
            fontName: BrandFont.postScriptName
        )
        context.fill(Path(glyphPath), with: .color(.white))
    }
}
```

- [x] **Step 3: Run the full verification suite**

```sh
./script/test.sh
```

Expected: all unit tests and both platform build checks pass.

### Task 2: Document and release build 4

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `project.yml`
- Regenerate: `EWClock.xcodeproj/project.pbxproj`

**Interfaces:**
- Consumes: the verified responsive clock implementation.
- Produces: version `1.0`, build `4`, uploaded to internal TestFlight for iOS/iPadOS and macOS.

- [x] **Step 1: Update public release copy**

Replace the planned-release paragraph with precise internal-TestFlight status:

```markdown
## TestFlight

EW Clock is currently available to EVERYWOW's internal testers through TestFlight for iPhone, iPad, and Mac. A public App Store release is planned. This repository contains the current source code for all three platforms.
```

- [x] **Step 2: Increment the build number**

Set `CURRENT_PROJECT_VERSION: 4` in `project.yml`, regenerate with `xcodegen generate`, and rerun `./script/test.sh`.

- [ ] **Step 3: Commit and push the release source**

```sh
git add README.md EWClock/Shared/ClockView.swift project.yml EWClock.xcodeproj/project.pbxproj docs/superpowers/plans/2026-07-17-macos-live-resize-seconds.md
git commit -m "Fix seconds sizing during Mac resize"
git push origin main
```

- [ ] **Step 4: Archive and upload both platforms**

```sh
./script/archive.sh
./script/upload_testflight.sh all
```

Expected: iOS/iPadOS and macOS uploads succeed without validation errors.

- [ ] **Step 5: Verify processing and record release state**

Wait until both build `4` entries are available to `EVERYWOW Internal`, update `AGENTS.md`, then commit and push the release record.

```sh
git add AGENTS.md
git commit -m "Record the build 4 TestFlight release"
git push origin main
```
