import SwiftUI

struct ClockView: View {
    @Binding private var isLogoVisible: Bool

    private let metrics: ClockTypography.Metrics
    private let timelineStart: Date

    init(
        isLogoVisible: Binding<Bool>,
        metrics: ClockTypography.Metrics = ClockTypography.metrics(
            fontName: BrandFont.postScriptName,
            referenceSize: 100
        ),
        now: Date = Date()
    ) {
        _isLogoVisible = isLogoVisible
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
                let time = ClockTime(date: context.date)

                ZStack {
                    clockRun(time: time)
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height,
                        alignment: .center
                    )

                    ClockProgressBarsView()

                    if isLogoVisible {
                        EverywowLogoView(
                            edgeInset: ClockTypography.mainInkLeadingInset(
                                availableWidth: geometry.size.width,
                                metrics: metrics,
                                leadingSegment: time.hours
                            )
                        ) {
                            isLogoVisible = false
                        }
                    }
                }
            }
        }
        .background(Color.black)
        .ignoresSafeArea()
        .contentShape(Rectangle())
#if os(macOS)
        .simultaneousGesture(WindowDragGesture())
        .allowsWindowActivationEvents(true)
#endif
    }

    private func clockRun(time: ClockTime) -> some View {
        return Canvas { context, size in
            let layout = ClockTypography.layout(
                availableSize: size,
                metrics: metrics
            )
            let glyphPath = ClockTypography.glyphPath(
                time: time,
                layout: layout,
                canvasSize: size,
                fontName: BrandFont.postScriptName
            )
            context.fill(Path(glyphPath), with: .color(.white))
        }
    }
}
