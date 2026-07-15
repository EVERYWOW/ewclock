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
        let fontSize = ClockTypography.fontSize(
            availableWidth: availableWidth,
            metrics: metrics
        )
        let scale = fontSize / metrics.referenceSize
        let segmentWidth = metrics.segmentAdvance * scale
        let colonWidth = metrics.colonAdvance * scale

        return HStack(spacing: 0) {
            segment(time.hours, width: segmentWidth, fontSize: fontSize)
            colon(width: colonWidth, fontSize: fontSize)
            segment(time.minutes, width: segmentWidth, fontSize: fontSize)
            colon(width: colonWidth, fontSize: fontSize)
            segment(time.seconds, width: segmentWidth, fontSize: fontSize)
        }
        .foregroundStyle(Color.white)
    }

    private func segment(
        _ value: String,
        width: CGFloat,
        fontSize: CGFloat
    ) -> some View {
        Text(value)
            .font(.custom(BrandFont.postScriptName, fixedSize: fontSize))
            .lineLimit(1)
            .frame(width: width)
    }

    private func colon(width: CGFloat, fontSize: CGFloat) -> some View {
        Text(":")
            .font(.custom(BrandFont.postScriptName, fixedSize: fontSize))
            .lineLimit(1)
            .frame(width: width)
    }
}
