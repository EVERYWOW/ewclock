import SwiftUI

struct ClockView: View {
    private let metrics: ClockTypography.Metrics
    private let timelineStart: Date

    init(
        metrics: ClockTypography.Metrics = ClockTypography.metrics(
            fontName: BrandFont.postScriptName,
            referenceSize: 100
        ),
        now: Date = Date()
    ) {
        self.metrics = metrics
        timelineStart = Date(
            timeIntervalSinceReferenceDate: floor(
                now.timeIntervalSinceReferenceDate
            )
        )
    }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.periodic(from: timelineStart, by: 1)) { context in
                clockRun(
                    time: ClockTime(date: context.date),
                    availableWidth: geometry.size.width
                )
                .frame(
                    width: geometry.size.width,
                    height: geometry.size.height,
                    alignment: .center
                )
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
    }

    private func clockRun(
        time: ClockTime,
        availableWidth: CGFloat
    ) -> some View {
        let layout = ClockTypography.layout(
            availableWidth: availableWidth,
            metrics: metrics
        )

        return Canvas { context, size in
            let glyphPath = ClockTypography.glyphPath(
                segments: time.segments,
                layout: layout,
                canvasSize: size,
                fontName: BrandFont.postScriptName
            )
            context.fill(Path(glyphPath), with: .color(.white))
        }
    }
}
