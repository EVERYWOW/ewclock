# Clock Progress Bars Design

## Purpose

EW Clock adds two thin white progress bars to show movement within the current hour and minute. The top bar shows elapsed time in the current hour. The bottom bar shows elapsed time in the current minute.

## Presentation

Each bar starts at the left edge and grows smoothly towards the right edge. The elapsed portion is pure white. The remaining portion is the existing pure-black background, with no separate track.

Each bar’s requested height is exactly `0.0025 × available width`. Available width and height are the full `GeometryReader` dimensions after `.ignoresSafeArea()` has expanded the clock to its outer content bounds. The top bar sits flush with the top edge, and the bottom bar sits flush with the bottom edge. Both bars span unsafe regions and adapt immediately to every iPhone and iPad orientation and every Mac or iPad window size. If a degenerate window is shorter than the requested bar height, the rendered height clamps to the available height.

The bars are decorative, use `.allowsHitTesting(false)`, and are hidden from accessibility. They remain visible when the EVERYWOW logo is present. The bars render in front of the clock, and the logo renders in front of the bars. Dismissing the logo does not affect either bar.

## Time Progress

The top progress value is:

`(minute × 60 + second + fractional second) ÷ 3,600`

The bottom progress value is:

`(second + fractional second) ÷ 60`

Fractional second is the calendar nanosecond component divided by `1,000,000,000`. The supplied calendar’s time zone determines the minute, second, and nanosecond components.

Both values are clamped to the closed range from zero to one. The top bar resets to zero at the start of each hour. The bottom bar resets to zero at the start of each minute.

The clock text keeps its existing second-aligned update schedule. A separate `TimelineView(.animation)` refreshes only the progress-bar view. Every refresh calculates progress from `context.date`, without interpolating stored progress values.

## Structure

A shared time-progress value calculates the two progress fractions from a date and calendar. A shared layout value calculates the rectangle geometry. The rendered thickness is the smaller of `0.0025 × availableWidth` and `availableHeight`. Each elapsed rectangle has the width `availableWidth × progress`. The top rectangle starts at `(0, 0)`, and the bottom rectangle starts at `(0, availableHeight − thickness)`. A SwiftUI view uses those values to draw the white rectangles.

The progress calculations and layout geometry stay independent of SwiftUI so automated tests can verify them directly.

## Verification

Automated tests cover representative hour and minute progress, fractional seconds, hour and minute resets, and clamping. Layout tests cover width-based thickness, zero-width, half-width, and full-width rectangles, plus top and bottom placement in normal and degenerate view sizes. The existing project test script checks the shared tests and the iPhone, iPad, and Mac builds.

Visual verification confirms smooth left-to-right movement, pure-white bars, a pure-black unelapsed area, safe-area coverage, correct resizing, and unchanged logo dismissal behavior.
