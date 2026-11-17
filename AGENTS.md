# EW Clock

Native SwiftUI set clock for iPhone, iPad, and Mac. The app targets iOS, iPadOS, and macOS 26.0 or later and is distributed through TestFlight by EVERYWOW AG.

## Product Rules

- Show the current local time in 24-hour format, with `HH:MM` on the first line and `SS` on the second line, plus the approved EVERYWOW logo in the bottom-left corner.
- Keep the background pure black and the time pure white.
- Draw a pure-white progress bar flush with the top edge for elapsed time in the current hour and another flush with the bottom edge for elapsed time in the current minute. Animate both smoothly from left to right, keep the remaining area black, and render them across safe-area regions.
- Size each progress bar to 0.5% of the available width in height. Keep the bars visible when the EVERYWOW logo is shown, and let logo dismissal affect only the logo.
- Keep the complete two-line time block centered in every orientation.
- Size the `HH:MM` line to 98% of the current screen or window width. Start `SS` at two-thirds of the first line's font size and center it beneath the first line. If the complete time block would leave less than 5% of the available height above or below it, reduce only the `SS` font size until the block fits within 90% of the available height. Clamp `SS` to zero when the first line and gap already use that space.
- Render hours, minutes, and seconds in fixed two-character slots sized for the widest measured ASCII value from `00` through `99`, with a fixed colon slot between hours and minutes, so digit changes do not move the layout.
- Use `EWClock/Resources/EVERYWOWDisplayVF.ttf` at variable weight 900. Its runtime PostScript instance is `EVERYWOWDisplay-Black`. EVERYWOW AG has authorized this font only for EVERYWOW’s app.
- Keep the display awake while the clock is active. Restore normal idle behavior when the iPhone or iPad scene becomes inactive, and end the Mac assertion when the app terminates.
- Support portrait and landscape on iPhone and iPad. Set `UIRequiresFullScreen = true`, apply `.persistentSystemOverlays(.hidden)`, and accept iPadOS 26 windowed mode.
- Keep the iPhone and iPad launch screen pure black with `UILaunchScreen.UIColorName = LaunchBackground` and a black `LaunchBackground.colorset`.
- Open a normal resizable Mac window. Do not enter macOS full screen automatically.
- Keep the Mac window toolbar present with its title and background hidden, so the native close, minimize, and zoom controls remain available. Show those controls during pointer activity anywhere over the window, keep them visible while the pointer is over a control, and hide them after two seconds of inactivity.
- Let the user tap or click only the EVERYWOW logo to hide it immediately for the rest of the current app session. Restore it when the app process closes and reopens. On Mac, let the user drag the window from anywhere in its content. Add no other controls, settings, gestures, networking, analytics, persistence, or unrelated features.
- Store the in-app logo at `EWClock/Resources/Assets.xcassets/EverywowLogo.imageset/everywow-logo-white.svg`. It was copied from `/Users/steffi/Library/CloudStorage/GoogleDrive-steffi@everywow.ch/Shared drives/EW Brand Materials/01 Logo/Logo/everywow-logo-white.svg`; the repository copy is the source of truth.
- Size the logo to 16% of the available width. Inset it from the left and bottom by the current `HH` glyphs' visible leading inset, so both edge distances match the visible clock margin and are equal in points. Recalculate that inset when the hour changes. Keep a clamped hit target of at least 44 × 44 points without moving or resizing the artwork, and do not show a keyboard focus border.
- Store the company-logo icon at `EWClock/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`. It was copied from `/Users/steffi/dev/ewtools/scripts/assets/everywow-favicon.png`; the repository copy is the source of truth.
- Calculate the first-line width as two maximum measured `00` through `99` advances plus one colon advance, with zero implicit horizontal padding, scaled to `0.98 × available width`. Use two-thirds of that font size as the maximum for the centered seconds line, subject to the 5% vertical-margin rule.

## Identifiers

- App name: `EW Clock`
- Bundle identifier: `ch.everywow.clock`
- App Store Connect SKU: `everywow-clock`
- App Store Connect Apple ID: `6791122125`
- Apple team: EVERYWOW AG (`L69664DD39`)
- Initial release: version `1.0`
- Initial build number: `1`
- Current internal TestFlight release: version `1.0`, build `6`
- Internal TestFlight group: `EVERYWOW Internal`
- Internal TestFlight testers: `apps@everywow.ch`, `production@everywow.ch`
- TestFlight feedback and beta-review email: `apps@everywow.ch`

Never commit Apple credentials, App Store Connect keys, provisioning profiles, or signing private keys.

`EW Clock` is the user-approved product name and the only allowed abbreviation of EVERYWOW in project copy. Write `EVERYWOW` everywhere else.

## Project and Commands

- `project.yml` is the source of truth. Generate the Xcode project with `xcodegen generate` and do not hand-edit the generated project.
- Keep `CFBundleVersion` and `CFBundleShortVersionString` in both generated Info.plists bound to `$(CURRENT_PROJECT_VERSION)` and `$(MARKETING_VERSION)`. XcodeGen otherwise writes stale literal versions when only the build setting changes.
- `./script/build_and_run.sh` builds and opens the Mac app.
- `./script/test.sh` runs unit tests and platform build checks. It and `./script/build_and_run.sh` sign local builds ad hoc through `script/local_signing.sh`, so they need no development certificate.
- `./script/archive.sh` creates iOS and Mac archives and exports them with cloud-managed distribution signing.
- `./script/upload_testflight.sh [all|ios|macos]` validates and uploads archives only when explicitly performing a release. The optional platform argument supports retrying one platform without duplicating an accepted upload.
- Keep shared app code under `EWClock/Shared`, platform adapters under `EWClock/iOS` and `EWClock/macOS`, resources under `EWClock/Resources`, and tests under `EWClockTests`.

## Git Workflow

Stefanie works across computers. Keep `main` synchronized and preserve unrelated local changes.

- At the start of future work, run `git pull --rebase --autostash`. Stop and report conflicts instead of forcing them.
- Commit focused, working changes directly to `main` and push them without asking when the requested task is complete.
- Do not rewrite published history or use destructive reset commands.

## Release Rules

- Build with the current installed stable Xcode accepted by App Store Connect.
- Authenticate every App Store Connect operation with the EVERYWOW App Store Connect API key, not the Apple ID signed into Xcode. `script/asc_env.sh` reads `ASC_KEY_ID` and `ASC_ISSUER_ID` from the environment or from the untracked file `~/.appstoreconnect/ewclock.env`, and the private key from `~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8`. On a new computer, copy both files there. Never commit the key ID, issuer ID, or key file to this public repository.
- Use cloud-managed signing with team `L69664DD39`. `./script/archive.sh` archives iOS unsigned and macOS ad hoc, then the API-key export applies Apple Distribution signing. Releases do not need local development or distribution identities in the keychain.
- Use `script/asc_api.rb METHOD PATH [JSON]` (after `source script/asc_env.sh` in bash) for App Store Connect API checks, such as build processing state and TestFlight group membership.
- Verify the installed Xcode version is accepted by App Store Connect before each release. Do not treat the version used for the first release as a permanent requirement.
- Use one App Store Connect app record with separate iPhone/iPad and Mac builds.
- Increase `CURRENT_PROJECT_VERSION` for every uploaded build.
- Verify both uploaded builds finish processing before adding them to `EVERYWOW Internal`.
- Internal testers must already be App Store Connect users. Ask before granting any new App Store Connect role solely to make someone eligible for internal testing.
- EW Clock currently uses internal-only TestFlight distribution. External builds require TestFlight Beta App Review and must not be submitted unless Stefanie explicitly changes the distribution scope again.

## Current TestFlight State

As of 16 November 2026:

- App Store Connect record `EW Clock` exists with Apple ID `6791122125` for iOS/iPadOS and macOS.
- Version `1.0`, builds `1` through `6` were uploaded for iOS/iPadOS and macOS with `ITSAppUsesNonExemptEncryption = false`. Builds `1` through `4` have expired.
- Build `6` is the latest build and was the first uploaded with the App Store Connect API key and cloud-managed signing. Both platform builds finished processing as `VALID` and show `IN_BETA_TESTING` internally.
- The internal group `EVERYWOW Internal` has access to all builds, contains builds `1` through `6` for both platforms, and has `apps@everywow.ch` and `production@everywow.ch` as internal testers.
- EW Clock is a private beta. On 17 November 2026, the public link of the external group `EVERYWOW Public Beta` was disabled and removed from `README.md`. The group has no testers and contains only the expired build `4`. Builds `5` and `6` were not submitted to TestFlight Beta App Review, and their external status is `READY_FOR_BETA_SUBMISSION`.
- Stefanie's private Apple ID installs EW Clock by redeeming one of the two internal tester invitations. App Store Connect lists that tester under the invited EVERYWOW address.
- Nothing has been submitted to App Store review or configured for App Store release.

The approved design is in `docs/superpowers/specs/2026-07-15-ew-clock-design.md`.
