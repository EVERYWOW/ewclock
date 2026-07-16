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
