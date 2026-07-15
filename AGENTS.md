# EW Clock

Native SwiftUI set clock for iPhone, iPad, and Mac. The app targets iOS, iPadOS, and macOS 26.0 or later and is distributed through TestFlight by EVERYWOW AG.

## Product Rules

- Show only the current local time in 24-hour `hh:mm:ss` format.
- Keep the background pure black and the time pure white.
- Keep the time centered and horizontal in every orientation.
- Size the complete time to 90% of the current screen or window width.
- Render hours, minutes, and seconds in fixed two-character slots sized for `88`, with fixed colon slots, so digit changes do not move the layout.
- Use `EWClock/Resources/EVERYWOWDisplayVF.ttf` at variable weight 900. Its runtime PostScript instance is `EVERYWOWDisplay-Black`. EVERYWOW AG has authorized this font only for EVERYWOW’s app.
- Keep the display awake while the clock is active. Restore normal idle behavior when the iPhone or iPad scene becomes inactive, and end the Mac assertion when the app terminates.
- Support portrait and landscape on iPhone and iPad. Set `UIRequiresFullScreen = true`, apply `.persistentSystemOverlays(.hidden)`, and accept iPadOS 26 windowed mode.
- Keep the iPhone and iPad launch screen pure black with `UILaunchScreen.UIColorName = LaunchBackground` and a black `LaunchBackground.colorset`.
- Open a normal resizable Mac window. Do not enter macOS full screen automatically.
- Add no controls, settings, gestures, networking, analytics, persistence, or unrelated features.
- Store the company-logo icon at `EWClock/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`. It was copied from `/Users/steffi/dev/ewtools/scripts/assets/everywow-favicon.png`; the repository copy is the source of truth.
- Calculate width as three measured `88` advances plus two colon advances, with zero implicit stack spacing or horizontal padding, scaled to `0.9 × available width`.

## Identifiers

- App name: `EW Clock`
- Bundle identifier: `ch.everywow.clock`
- App Store Connect SKU: `everywow-clock`
- Apple team: EVERYWOW AG (`L69664DD39`)
- Initial release: version `1.0`
- Initial build number: `1`
- Internal TestFlight group: `EVERYWOW Internal`
- Intended testers: `stefanie@hetjens.com`, `production@everywow.ch`

Never commit Apple credentials, App Store Connect keys, provisioning profiles, or signing private keys.

`EW Clock` is the user-approved product name and the only allowed abbreviation of EVERYWOW in project copy. Write `EVERYWOW` everywhere else.

## Project and Commands

- `project.yml` is the source of truth. Generate the Xcode project with `xcodegen generate` and do not hand-edit the generated project.
- `./script/build_and_run.sh` builds and opens the Mac app.
- `./script/test.sh` runs unit tests and platform build checks.
- `./script/archive.sh` creates signed iOS and Mac archives for distribution.
- `./script/upload_testflight.sh` validates and uploads archives only when explicitly performing a release.
- Keep shared app code under `EWClock/Shared`, platform adapters under `EWClock/iOS` and `EWClock/macOS`, resources under `EWClock/Resources`, and tests under `EWClockTests`.

## Git Workflow

Stefanie works across computers. Keep `main` synchronized and preserve unrelated local changes.

- At the start of future work, run `git pull --rebase --autostash`. Stop and report conflicts instead of forcing them.
- Commit focused, working changes directly to `main` and push them without asking when the requested task is complete.
- Do not rewrite published history or use destructive reset commands.

## Release Rules

- Build with the current installed stable Xcode accepted by App Store Connect.
- Use automatic signing with team `L69664DD39`. On 15 July 2026, this Mac had valid EVERYWOW development and distribution identities. Recheck before release with `security find-identity -v -p codesigning`.
- Verify the installed Xcode version is accepted by App Store Connect before each release. Do not treat the version used for the first release as a permanent requirement.
- Use one App Store Connect app record with separate iPhone/iPad and Mac builds.
- Increase `CURRENT_PROJECT_VERSION` for every uploaded build.
- Verify both uploaded builds finish processing before adding them to `EVERYWOW Internal`.
- Internal testers must already be App Store Connect users. Ask before granting a new App Store Connect role if either intended tester is missing.

The approved design is in `docs/superpowers/specs/2026-07-15-ew-clock-design.md`.
