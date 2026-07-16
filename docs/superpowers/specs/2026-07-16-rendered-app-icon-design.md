# Rendered App Icon Design

## Purpose

EW Clock replaces its current app icon with the approved rendered design. The icon shows the clock app on a floating landscape tablet, with the colored EVERYWOW artwork overlapping the tablet at the bottom right.

## Artwork

The tablet keeps the approved dark metal frame, black glass screen, restrained reflections, and studio lighting. Its screen shows `09:41` on the first line and `00` centered beneath it. Thin white progress bars run along the screen’s top and bottom edges.

The overlapping EVERYWOW artwork stays flat and two-dimensional. It has no border, frame, bevel, thickness, or shadow. The black, blue, and white artwork remains as shown in `docs/assets/ew-clock-app-icon-rendered-source.png`.

The operating system applies the final icon mask. The source image remains a full square without rounded outer corners.

## Source Preservation

Before replacing the app icon, copy the current `EWClock/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png` unchanged to `docs/assets/everywow-logo-color.png`.

Copy the approved rendered image from `/Users/steffi/.codex/generated_images/019f69e4-b8e9-75b3-bd67-ebb4bf04bbc0/exec-34d33671-b038-4626-ae84-a7add7d3e727.png` unchanged to `docs/assets/ew-clock-app-icon-rendered-source.png`, then derive the app icon from that repository copy. This keeps later refinements independent of the resized app icon.

The in-app white EVERYWOW logo at `EWClock/Resources/Assets.xcassets/EverywowLogo.imageset/everywow-logo-white.svg` remains unchanged.

## App Icon Output

Derive `EWClock/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png` from the approved rendered source. Resize it to exactly 1,024 × 1,024 pixels using Lanczos resampling, preserve the square composition, use the sRGB color space, and remove any alpha channel.

The existing asset-catalog configuration continues to use the same file for iPhone, iPad, and Mac.

## Verification

Verify the preserved colored artwork and rendered source exist as separate files. Confirm the app icon is a 1,024 × 1,024 sRGB PNG without alpha, regenerate the Xcode project, run the project test script, and inspect the icon at 16 × 16 and 1,024 × 1,024 pixels. The clock, tablet, and flat EVERYWOW artwork must remain readable after resizing.
