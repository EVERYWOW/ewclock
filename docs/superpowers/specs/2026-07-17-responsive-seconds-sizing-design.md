# Responsive Seconds Sizing Design

## Purpose

Keep the `HH:MM` line at 98% of the available width while ensuring that the centered two-line clock block leaves a margin of at least 5% of the available height above and below it.

## Typography

The `HH:MM` line continues to determine its font size from the available width. Its measured width remains exactly `0.98 × available width`, and the line gap remains `0.1 ×` the `HH:MM` font size.

The seconds line starts at two-thirds of the `HH:MM` font size. The complete clock block may use at most 90% of the available height. When the two-thirds seconds size would exceed that height, the app reduces only the seconds font size until the block fits. The seconds font size is clamped between zero and two-thirds of the `HH:MM` font size.

If the `HH:MM` line and gap already use 90% or more of the available height, the seconds font size becomes zero. The `HH:MM` line and gap remain unchanged. The resulting block stays centered vertically, which gives equal top and bottom margins.

## Implementation

`ClockTypography.layout` receives the available width and height. It first derives the width-based `HH:MM` font size, then finds the largest seconds line height that fits within the 90% height limit. The layout uses font metrics to convert the allowed line height into a seconds font size.

`ClockView` passes its current width and height to the typography calculation. Resizing a window or rotating a device recalculates the layout immediately.

The logo inset continues to depend only on the `HH:MM` line's width-based font size, so the vertical constraint does not move the logo horizontally.

## Verification

Automated tests cover a window with enough height for the two-thirds seconds size, a constrained window where seconds shrink, a constrained window where the clock block reaches the 90% height limit and leaves exactly 5% above and below, and a window where the seconds size reaches zero. Existing fixed-slot, 98% width, and logo-inset tests remain valid.

The iPhone screenshot referenced in the README is regenerated from the updated app and checked for a black background, white clock, visible progress bars and logo, and the new vertical margin behavior.
