# Dismissible EVERYWOW Logo Design

## Purpose

EW Clock shows the white EVERYWOW wordmark in the bottom-left corner while preserving the clock as the main display. The user can hide the logo for the rest of the current app session.

This approved feature replaces the earlier restrictions that allowed only the current time and prohibited controls or gestures. The durable product rules in `AGENTS.md` must be updated with the implementation.

## Layout

The logo uses the supplied `everywow-logo-white.svg` artwork and keeps its original aspect ratio. Its width is `0.08 ×` the current screen or window width. The initial 6% implementation was increased after visual review because the wide, shallow wordmark looked too small.

The clock's 98% typographic advance includes the font's side bearings, so its visible white glyphs begin farther from the edge than 1% of the width. The logo uses the current `HH` glyphs' visible leading inset for both its left and bottom insets. This value scales with the window and updates when the hour changes, keeping both logo edge distances equal in points and aligned with the clock the user sees.

The logo is an overlay and does not take part in the centered clock layout. It cannot move or resize the two-line time block. The background stays pure black, and the supplied logo stays pure white.

## Interaction and State

The visible logo is tappable on iPhone and iPad and clickable on Mac. Its hit area is at least 44 × 44 points. The hit area is centered on the artwork, then clamped to the window bounds without moving or resizing the artwork. The invisible button does not accept keyboard focus or draw a focus border.

The logo disappears immediately after activation. The visibility value lives at the app level and is shared by every scene. It is not stored on disk. Closing and reopening a window within the same running process does not restore the logo; terminating and reopening the app does.

The hidden state has no visible replacement, animation, setting, or gesture for restoring the logo during the same app session.

## Asset Handling

The supplied SVG is copied into `EWClock/Resources/Assets.xcassets/EverywowLogo.imageset/`. The repository copy becomes the source of truth for the in-app wordmark. Xcode compiles the vector asset for iPhone, iPad, and Mac.

## Verification

Automated tests cover the logo width, the clock's visible leading inset, and equal logo edge inset calculations. Platform builds confirm that the shared SwiftUI view and vector asset compile for iPhone, iPad, and Mac.

A visual check confirms that the logo is white, remains in the bottom-left corner during rotation and resizing, does not affect clock centering, and disappears immediately after a tap or click. Reopening the Mac window in the same process keeps the logo hidden. Terminating and reopening the app restores it on every platform.
