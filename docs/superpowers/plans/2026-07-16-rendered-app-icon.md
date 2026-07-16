# Rendered App Icon Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install the approved rendered EW Clock app icon while preserving the colored EVERYWOW artwork and rendered source separately.

**Architecture:** Keep both source images under `docs/assets` and derive the shipping 1,024 × 1,024 PNG from the approved render. The existing asset-catalog entry continues to serve iPhone, iPad, and Mac.

**Tech Stack:** PNG, ImageMagick, XcodeGen, Xcode asset catalogs

## Global Constraints

- Preserve the current colored EVERYWOW artwork unchanged.
- Keep the approved rendered source unchanged.
- The shipping icon must be a 1,024 × 1,024 sRGB PNG without alpha.
- Do not change the in-app white EVERYWOW SVG.
- Use the existing `AppIcon.appiconset` configuration for iPhone, iPad, and Mac.

### Task 1: Install and Verify the Rendered Icon

**Files:**
- Create: `docs/assets/everywow-logo-color.png`
- Create: `docs/assets/ew-clock-app-icon-rendered-source.png`
- Modify: `EWClock/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`

**Interfaces:**
- Consumes: the current app icon and the approved generated render
- Produces: preserved source artwork and the shared 1,024 × 1,024 app icon

- [ ] **Step 1: Preserve both sources**

Copy the current app icon unchanged to `docs/assets/everywow-logo-color.png`. Store the final approved rendered composite unchanged at `docs/assets/ew-clock-app-icon-rendered-source.png`.

- [ ] **Step 2: Derive the shipping icon**

Resize the repository copy with Lanczos resampling, convert it to sRGB, remove alpha, and write it to `EWClock/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`.

- [ ] **Step 3: Verify image properties**

Run `identify` on all three files. Expect the shipping icon to report `1024x1024`, `sRGB`, and no alpha channel.

- [ ] **Step 4: Regenerate and test**

Run `xcodegen generate` and `./script/test.sh`. Expect all tests and platform build checks to pass.

- [ ] **Step 5: Build and open the Mac app**

Run `./script/build_and_run.sh`. Expect `BUILD SUCCEEDED` and the new EW Clock app to open.

- [ ] **Step 6: Commit and push**

Stage the source images, shipping icon, specification, and plan. Commit the focused change and push `main`.
