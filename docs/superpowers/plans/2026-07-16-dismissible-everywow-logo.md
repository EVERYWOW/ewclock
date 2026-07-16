# Dismissible EVERYWOW Logo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the supplied white EVERYWOW logo to the bottom-left corner and let the user hide it until the app process ends.

**Architecture:** A pure layout type calculates the artwork and hit-target frames from the available size, which keeps the geometry testable without rendering SwiftUI. `ClockTypography` measures the visible leading edge of every two-digit segment, and `ClockView` selects the current `HH` value. `ClockView` receives app-owned visibility as a binding and overlays a dedicated `EverywowLogoView` without changing the centered clock canvas.

**Tech Stack:** Swift 6, SwiftUI, Swift Testing, Xcode asset catalogs, and XcodeGen

## Global Constraints

- Target iOS, iPadOS, and macOS 26.0 or later.
- Keep the background pure black and the time and logo pure white.
- Keep the complete two-line time block centered and preserve its existing 98% width calculation.
- Size the logo to 16% of the available width and inset it from the left and bottom by the current `HH` glyphs' visible leading inset.
- Hide the logo immediately after activation and restore it only after the app process closes and reopens.
- Add no persistence, networking, analytics, settings, or unrelated features.
- Use `project.yml` as the Xcode project source of truth and generate the project with `xcodegen generate`.
- Preserve unrelated local changes, including the existing generated-project build-number change.

---

### Pre-Implementation Sync

- [ ] Run `git pull --rebase --autostash`. Stop and report any conflict instead of forcing it. This was completed before the plan was written for the current execution, but future executions must repeat it.

### Task 1: Test and Add Logo Geometry

**Files:**
- Create: `EWClock/Shared/EverywowLogoLayout.swift`
- Modify: `EWClock/Shared/ClockTypography.swift`
- Modify: `EWClockTests/ClockTests.swift`

**Interfaces:**
- Consumes: `CGSize`, `CGRect`, and `CGFloat` from CoreGraphics.
- Produces: `ClockTypography.mainInkLeadingInset(availableWidth:metrics:leadingSegment:)`, `EverywowLogoLayout.init(availableSize:edgeInset:)`, `artworkFrame: CGRect`, and `hitTargetFrame: CGRect`.

- [ ] **Step 1: Write failing geometry tests**

Add typography assertions that a segment's visible inset is greater than the 1% advance inset and that `08` sits farther inward than `00`. Add logo tests that use a 1,000 × 400-point canvas and assert an artwork width of 160 points, equal 30-point left and bottom insets, the SVG aspect ratio `239.4587 / 51.3128`, and a hit target of at least 44 × 44 points contained by the canvas. Add a narrow-canvas test that confirms the hit target is clamped inside the available bounds without changing `artworkFrame`.

```swift
@Suite("EVERYWOW logo layout")
struct EverywowLogoLayoutTests {
    @Test("Artwork uses sixteen percent width and equal clock edge insets")
    func artworkGeometry() {
        let layout = EverywowLogoLayout(
            availableSize: CGSize(width: 1_000, height: 400),
            edgeInset: 30
        )

        #expect(abs(layout.artworkFrame.width - 160) < 0.000_001)
        #expect(abs(layout.artworkFrame.minX - 30) < 0.000_001)
        #expect(abs(layout.artworkFrame.maxY - 370) < 0.000_001)
        #expect(
            abs(
                layout.artworkFrame.width / layout.artworkFrame.height
                    - EverywowLogoLayout.artworkAspectRatio
            ) < 0.000_001
        )
        #expect(layout.hitTargetFrame.width >= 44)
        #expect(layout.hitTargetFrame.height >= 44)
        #expect(
            CGRect(origin: .zero, size: layout.availableSize)
                .contains(layout.hitTargetFrame)
        )
    }

    @Test("Hit target clamps to bounds without moving artwork")
    func hitTargetClamping() {
        let layout = EverywowLogoLayout(
            availableSize: CGSize(width: 100, height: 60),
            edgeInset: 3
        )

        #expect(abs(layout.artworkFrame.minX - 3) < 0.000_001)
        #expect(abs(layout.artworkFrame.maxY - 57) < 0.000_001)
        #expect(layout.hitTargetFrame.minX == 0)
        #expect(layout.hitTargetFrame.maxY == 60)
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `xcodebuild test -project EWClock.xcodeproj -scheme EWClockTests -destination 'platform=macOS'`

Expected: compilation fails because `EverywowLogoLayout` does not exist.

- [ ] **Step 3: Implement the geometry type**

Create an immutable layout value with named constants for the requested dimensions. Calculate the artwork at the exact requested frame. Calculate the hit target around the artwork center, limit its size to the available size, and clamp its center so the target stays within bounds.

Extend `ClockTypography.Metrics` with `segmentLeadingInkInsets`. Build every two-digit segment's glyph path at the reference size and store each visible leading bound. Implement `mainInkLeadingInset(availableWidth:metrics:leadingSegment:)` as the 1% advance inset plus the selected segment's scaled visible leading bound.

```swift
import CoreGraphics

struct EverywowLogoLayout: Equatable, Sendable {
    static let artworkAspectRatio: CGFloat = 239.4587 / 51.3128
    static let artworkWidthFraction: CGFloat = 0.16
    static let minimumHitTargetSize: CGFloat = 44

    let availableSize: CGSize
    let artworkFrame: CGRect
    let hitTargetFrame: CGRect

    init(availableSize: CGSize, edgeInset: CGFloat) {
        self.availableSize = availableSize

        let artworkWidth = availableSize.width * Self.artworkWidthFraction
        let artworkHeight = artworkWidth / Self.artworkAspectRatio
        artworkFrame = CGRect(
            x: edgeInset,
            y: availableSize.height - edgeInset - artworkHeight,
            width: artworkWidth,
            height: artworkHeight
        )

        let hitSize = CGSize(
            width: min(
                max(Self.minimumHitTargetSize, artworkWidth),
                availableSize.width
            ),
            height: min(
                max(Self.minimumHitTargetSize, artworkHeight),
                availableSize.height
            )
        )
        let centerX = min(
            max(artworkFrame.midX, hitSize.width / 2),
            availableSize.width - (hitSize.width / 2)
        )
        let centerY = min(
            max(artworkFrame.midY, hitSize.height / 2),
            availableSize.height - (hitSize.height / 2)
        )
        hitTargetFrame = CGRect(
            x: centerX - (hitSize.width / 2),
            y: centerY - (hitSize.height / 2),
            width: hitSize.width,
            height: hitSize.height
        )
    }
}
```

- [ ] **Step 4: Regenerate the project so the new source joins the test target**

Run: `xcodegen generate`

Expected: `EWClock.xcodeproj` includes `EverywowLogoLayout.swift` in the shared app and test sources while retaining build number 2 from `project.yml`.

- [ ] **Step 5: Run the focused tests and confirm they pass**

Run: `xcodebuild test -project EWClock.xcodeproj -scheme EWClockTests -destination 'platform=macOS'`

Expected: all `EWClockTests` pass.

### Task 2: Add the Vector Asset and Dismissible Overlay

**Files:**
- Create: `EWClock/Resources/Assets.xcassets/EverywowLogo.imageset/Contents.json`
- Create: `EWClock/Resources/Assets.xcassets/EverywowLogo.imageset/everywow-logo-white.svg`
- Create: `EWClock/Shared/EverywowLogoView.swift`
- Modify: `EWClock/Shared/ClockView.swift`
- Modify: `EWClock/iOS/EWClockIOSApp.swift`
- Modify: `EWClock/macOS/EWClockMacApp.swift`

**Interfaces:**
- Consumes: `EverywowLogoLayout`, the `EverywowLogo` asset, and `Binding<Bool>`.
- Produces: `EverywowLogoView(edgeInset: CGFloat, onDismiss: @escaping () -> Void)` and `ClockView(isLogoVisible: Binding<Bool>, metrics: ClockTypography.Metrics, now: Date)`.

- [ ] **Step 1: Add the supplied SVG as a universal vector image set**

Copy `/Users/steffi/Library/CloudStorage/GoogleDrive-steffi@everywow.ch/Shared drives/EW Brand Materials/01 Logo/Logo/everywow-logo-white.svg` unchanged to `EWClock/Resources/Assets.xcassets/EverywowLogo.imageset/everywow-logo-white.svg`. Use `apply_patch` to add the text SVG and image-set manifest so repository edits follow the workspace editing rules. Set `preserves-vector-representation` to `true` so the compiled asset remains sharp at every screen and window size.

```json
{
  "images" : [
    {
      "filename" : "everywow-logo-white.svg",
      "idiom" : "universal"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "preserves-vector-representation" : true
  }
}
```

- [ ] **Step 2: Build the logo overlay from independent artwork and hit-target frames**

Use a `GeometryReader` and `EverywowLogoLayout`. Draw `Image("EverywowLogo")` at `artworkFrame`. Place a plain, transparent, non-focusable `Button` at `hitTargetFrame`, label it “Hide EVERYWOW logo” for accessibility, and call `onDismiss` without animation.

```swift
import SwiftUI

struct EverywowLogoView: View {
    let edgeInset: CGFloat
    let onDismiss: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let layout = EverywowLogoLayout(
                availableSize: geometry.size,
                edgeInset: edgeInset
            )

            Image("EverywowLogo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(
                    width: layout.artworkFrame.width,
                    height: layout.artworkFrame.height
                )
                .position(
                    x: layout.artworkFrame.midX,
                    y: layout.artworkFrame.midY
                )

            Button(action: onDismiss) {
                Color.clear
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            .focusEffectDisabled()
            .accessibilityLabel("Hide EVERYWOW logo")
            .frame(
                width: layout.hitTargetFrame.width,
                height: layout.hitTargetFrame.height
            )
            .position(
                x: layout.hitTargetFrame.midX,
                y: layout.hitTargetFrame.midY
            )
        }
    }
}
```

- [ ] **Step 3: Overlay the logo without changing clock geometry**

Add `@Binding private var isLogoVisible: Bool` to `ClockView`. Add `isLogoVisible: Binding<Bool>` as the first initializer parameter and assign `_isLogoVisible = isLogoVisible`. Inside the existing timeline, measure the current hour's visible inset with `ClockTypography.mainInkLeadingInset(availableWidth:metrics:leadingSegment:)`, then pass it to `EverywowLogoView`. Place the logo after the clock in a `ZStack` and set `isLogoVisible = false` in its dismiss closure. Keep the outer black background and safe-area behavior unchanged.

- [ ] **Step 4: Own visibility for the app session on both platforms**

Add `@State private var isLogoVisible = true` to both app types and pass `$isLogoVisible` into `ClockView`. Do not use `@AppStorage`, `UserDefaults`, or another persistent store.

- [ ] **Step 5: Regenerate the Xcode project and build both platforms**

Run: `xcodegen generate`

Expected: the generated project includes `EverywowLogoLayout.swift`, `EverywowLogoView.swift`, and the `EverywowLogo` asset while retaining build number 2 from `project.yml`.

Run: `./script/test.sh`

Expected: unit tests and platform build checks pass.

### Task 3: Update Durable Product Rules and Verify the Result

**Files:**
- Modify: `AGENTS.md`
- Verify: `docs/superpowers/specs/2026-07-16-dismissible-everywow-logo-design.md`

**Interfaces:**
- Consumes: the approved logo specification and completed implementation.
- Produces: repository instructions that describe the logo as an intentional exception to the previous time-only and no-interaction rules.

- [ ] **Step 1: Update the durable product rules**

Replace “Show only the current local time” with wording that also allows the bottom-left EVERYWOW logo. Replace the blanket control and gesture prohibition with a narrow rule that permits only tapping or clicking the logo to hide it for the current app session. Record the asset path, logo width, visible clock inset calculation, and disabled focus border.

- [ ] **Step 2: Check the finished diff**

Run: `git diff --check`

Expected: no whitespace errors.

Run: `git status --short`

Expected: only the logo feature files, the updated design and plan, and the pre-existing generated-project build-number change are present.

- [ ] **Step 3: Run the full verification again**

Run: `./script/test.sh`

Expected: all unit tests and platform builds pass.

- [ ] **Step 4: Complete the manual platform checks**

Verify iPhone and iPad portrait and landscape, plus Mac resizing. Confirm that the artwork is white, its left and bottom insets are equal, and the centered clock does not move. Confirm immediate dismissal on tap and click. On Mac, reopen the window without terminating the process and confirm the logo stays hidden. Terminate and relaunch each app and confirm the logo returns.

- [ ] **Step 5: Commit only the logo feature changes**

Stage the logo implementation, tests, resources, and `AGENTS.md`. Stage only the new-file references from `EWClock.xcodeproj/project.pbxproj` with hunk-level staging. Run `git diff --cached` and confirm that the pre-existing build-number hunk and every unrelated change remain unstaged. Confirm that no credentials are staged, then commit with `Add dismissible EVERYWOW logo`.

- [ ] **Step 6: Push synchronized `main`**

Run: `git push origin main`

Expected: the focused design and implementation commits are published to `origin/main`.
