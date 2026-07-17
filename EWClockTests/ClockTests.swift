import CoreText
import Foundation
import Testing

@Suite("Clock time")
struct ClockTimeTests {
    private let utc = TimeZone(secondsFromGMT: 0)!

    @Test("Midnight is represented in 24-hour format")
    func midnight() {
        let time = ClockTime(date: date("2026-07-15T00:00:00Z"), timeZone: utc)

        #expect(time.hours == "00")
        #expect(time.minutes == "00")
        #expect(time.seconds == "00")
    }

    @Test("Noon is represented in 24-hour format")
    func noon() {
        let time = ClockTime(date: date("2026-07-15T12:00:00Z"), timeZone: utc)

        #expect(time.hours == "12")
        #expect(time.minutes == "00")
        #expect(time.seconds == "00")
    }

    @Test("Single-digit components are zero padded")
    func padding() {
        let time = ClockTime(date: date("2026-07-15T03:04:05Z"), timeZone: utc)

        #expect(time.hours == "03")
        #expect(time.minutes == "04")
        #expect(time.seconds == "05")
    }

    @Test("An explicit time zone controls calendar conversion")
    func explicitTimeZone() {
        let zurich = TimeZone(identifier: "Europe/Zurich")!
        let time = ClockTime(date: date("2026-01-15T23:07:09Z"), timeZone: zurich)

        #expect(time.hours == "00")
        #expect(time.minutes == "07")
        #expect(time.seconds == "09")
    }

    @Test("Segments expose the three fixed clock fields")
    func segments() {
        let time = ClockTime(date: date("2026-07-15T07:08:09Z"), timeZone: utc)

        #expect(time.segments == ["07", "08", "09"])
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}

@Suite("Clock typography")
struct ClockTypographyTests {
    @Test("The first line uses 98 percent width and seconds use two-thirds size")
    func widthEquation() throws {
        try BrandFont.register()
        let metrics = ClockTypography.metrics(
            fontName: BrandFont.postScriptName,
            referenceSize: 100
        )

        #expect(
            metrics.mainReferenceAdvance
                == (2 * metrics.segmentAdvance) + metrics.colonAdvance
        )

        let availableWidth = 1_200.0
        let layout = ClockTypography.layout(
            availableSize: CGSize(width: availableWidth, height: 1_000),
            metrics: metrics
        )

        #expect(
            abs(layout.mainRunWidth - (0.98 * availableWidth))
                < 0.000_001
        )
        #expect(
            abs(
                layout.secondsFontSize
                    - ((2.0 / 3.0) * layout.mainFontSize)
            ) < 0.000_001
        )
        #expect(
            abs(layout.lineGap - (0.1 * layout.mainFontSize))
                < 0.000_001
        )
        #expect(
            ClockTypography.mainInkLeadingInset(
                availableWidth: availableWidth,
                metrics: metrics,
                leadingSegment: "08"
            ) > (0.01 * availableWidth)
        )
        #expect(
            ClockTypography.mainInkLeadingInset(
                availableWidth: availableWidth,
                metrics: metrics,
                leadingSegment: "08"
            )
                > ClockTypography.mainInkLeadingInset(
                    availableWidth: availableWidth,
                    metrics: metrics,
                    leadingSegment: "00"
                )
        )
        #expect(
            abs(
                layout.blockHeight
                    - (
                        layout.mainLineHeight
                            + layout.lineGap
                            + layout.secondsLineHeight
                    )
            ) < 0.000_001
        )
    }

    @Test("Seconds shrink to preserve vertical margins")
    func heightLimitedSeconds() throws {
        try BrandFont.register()
        let metrics = ClockTypography.metrics(
            fontName: BrandFont.postScriptName,
            referenceSize: 100
        )
        let unconstrained = ClockTypography.layout(
            availableSize: CGSize(width: 1_200, height: 1_000),
            metrics: metrics
        )

        #expect(
            abs(
                unconstrained.secondsFontSize
                    - ((2.0 / 3.0) * unconstrained.mainFontSize)
            ) < 0.000_001
        )

        let halfSecondsHeight = unconstrained.secondsLineHeight / 2
        let constrainedHeight = (
            unconstrained.mainLineHeight
                + unconstrained.lineGap
                + halfSecondsHeight
        ) / 0.9
        let constrained = ClockTypography.layout(
            availableSize: CGSize(
                width: 1_200,
                height: constrainedHeight
            ),
            metrics: metrics
        )

        #expect(
            abs(
                constrained.secondsFontSize
                    - (unconstrained.secondsFontSize / 2)
            ) < 0.000_001
        )
        #expect(
            abs(constrained.blockHeight - (0.9 * constrainedHeight))
                < 0.000_001
        )
        #expect(
            abs(
                constrained.blockOriginY(canvasHeight: constrainedHeight)
                    - (0.05 * constrainedHeight)
            ) < 0.000_001
        )

        let secondsFreeHeight = (
            unconstrained.mainLineHeight + unconstrained.lineGap
        ) / 0.9 - 1
        let secondsFree = ClockTypography.layout(
            availableSize: CGSize(
                width: 1_200,
                height: secondsFreeHeight
            ),
            metrics: metrics
        )

        #expect(secondsFree.secondsFontSize == 0)
        #expect(secondsFree.secondsLineHeight == 0)

        let time = ClockTime(
            date: Date(timeIntervalSince1970: 0),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )
        let canvasSize = CGSize(
            width: 1_200,
            height: secondsFreeHeight
        )
        let path = ClockTypography.glyphPath(
            time: time,
            layout: secondsFree,
            canvasSize: canvasSize,
            fontName: BrandFont.postScriptName
        )
        let mainLineMaxY = secondsFree.blockOriginY(
            canvasHeight: canvasSize.height
        ) + secondsFree.mainLineHeight

        #expect(!path.isEmpty)
        #expect(
            path.boundingBoxOfPath.maxY <= mainLineMaxY + 0.000_001
        )
    }

    @Test("Metrics match independent CoreText line measurements")
    func metricsMatchMeasuredAdvances() throws {
        try BrandFont.register()
        let referenceSize = 100.0
        let font = CTFontCreateWithName(
            BrandFont.postScriptName as CFString,
            referenceSize,
            nil
        )
        let metrics = ClockTypography.metrics(
            fontName: BrandFont.postScriptName,
            referenceSize: referenceSize
        )

        let measurements = (0...99).map { value in
            let text = twoDigits(value)
            return (text: text, advance: measuredAdvance(of: text, in: font))
        }
        let maximumAdvance = measurements.map(\.advance).max()!
        let widestSegments = measurements
            .filter { abs($0.advance - maximumAdvance) < 0.000_001 }
            .map(\.text)

        #expect(abs(metrics.segmentAdvance - maximumAdvance) < 0.000_001)
        #expect(metrics.widestSegment == "00")
        #expect(widestSegments == ["00", "04", "40", "44"])
        #expect(
            abs(metrics.colonAdvance - measuredAdvance(of: ":", in: font))
                < 0.000_001
        )
    }

    @Test("Registration exposes the approved PostScript instance")
    func approvedFontIsRegistered() throws {
        try BrandFont.register()

        let font = CTFontCreateWithName(BrandFont.postScriptName as CFString, 100, nil)
        let resolvedName = CTFontCopyPostScriptName(font) as String

        #expect(resolvedName == BrandFont.postScriptName)
    }

    @Test("Every two-character value uses fixed two-line slot centers")
    func everyValueUsesFixedSlotCenters() throws {
        try BrandFont.register()
        let metrics = ClockTypography.metrics(
            fontName: BrandFont.postScriptName,
            referenceSize: 100
        )
        let layout = ClockTypography.layout(
            availableSize: CGSize(width: 1_000, height: 1_000),
            metrics: metrics
        )
        let expectedCenters = layout
            .mainSlots(hours: "00", minutes: "00")
            .map(\.centerX)
        let expectedSecondsCenter = layout.secondsSlot(seconds: "00").centerX
        let font = CTFontCreateWithName(
            BrandFont.postScriptName as CFString,
            metrics.referenceSize,
            nil
        )
        let clockTime = ClockTime(
            date: Date(timeIntervalSince1970: 0),
            timeZone: TimeZone(secondsFromGMT: 0)!
        )

        for value in 0...99 {
            let text = twoDigits(value)
            let slots = layout.mainSlots(hours: text, minutes: text)
            let canvasSize = CGSize(
                width: 1_000,
                height: layout.blockHeight + 200
            )
            let path = ClockTypography.glyphPath(
                time: clockTime,
                layout: layout,
                canvasSize: canvasSize,
                fontName: BrandFont.postScriptName
            )
            let pathBounds = path.boundingBoxOfPath

            #expect(
                measuredAdvance(of: text, in: font)
                    <= metrics.segmentAdvance
            )
            #expect(slots.map(\.text) == [text, ":", text])
            #expect(slots.map(\.centerX) == expectedCenters)
            #expect(
                layout.secondsSlot(seconds: text).centerX
                    == expectedSecondsCenter
            )
            #expect(!path.isEmpty)
            #expect(pathBounds.minX >= 10)
            #expect(pathBounds.maxX <= 990)
            #expect(pathBounds.minY >= 0)
            #expect(pathBounds.maxY <= canvasSize.height)
            #expect(
                abs(
                    layout.blockOriginY(canvasHeight: canvasSize.height)
                        - 100
                ) < 0.000_001
            )
        }

        #expect(abs(layout.mainRunWidth - 980) < 0.000_001)
    }

    private func twoDigits(_ value: Int) -> String {
        String(
            format: "%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            value
        )
    }

    private func measuredAdvance(of text: String, in font: CTFont) -> CGFloat {
        let fontAttribute = NSAttributedString.Key(kCTFontAttributeName as String)
        let attributedText = NSAttributedString(
            string: text,
            attributes: [fontAttribute: font]
        )
        let line = CTLineCreateWithAttributedString(attributedText)

        return CTLineGetTypographicBounds(line, nil, nil, nil)
    }
}

@Suite("EVERYWOW logo layout")
struct EverywowLogoLayoutTests {
    @Test("Artwork uses sixteen percent width and equal clock edge insets")
    func artworkGeometry() {
        let layout = EverywowLogoLayout(
            availableSize: CGSize(width: 1_000, height: 400),
            edgeInset: 30
        )

        #expect(abs(layout.artworkFrame.width - 160) < 0.000_001)
        #expect(abs(layout.artworkFrame.minX - 30) < 0.000_001)
        #expect(abs(layout.artworkFrame.maxY - 370) < 0.000_001)
        #expect(
            abs(
                layout.artworkFrame.width / layout.artworkFrame.height
                    - EverywowLogoLayout.artworkAspectRatio
            ) < 0.000_001
        )
        #expect(layout.hitTargetFrame.width >= 44)
        #expect(layout.hitTargetFrame.height >= 44)
        #expect(
            CGRect(origin: .zero, size: layout.availableSize)
                .contains(layout.hitTargetFrame)
        )
    }

    @Test("Hit target clamps to bounds without moving artwork")
    func hitTargetClamping() {
        let layout = EverywowLogoLayout(
            availableSize: CGSize(width: 100, height: 60),
            edgeInset: 3
        )

        #expect(abs(layout.artworkFrame.minX - 3) < 0.000_001)
        #expect(abs(layout.artworkFrame.maxY - 57) < 0.000_001)
        #expect(layout.hitTargetFrame.minX == 0)
        #expect(layout.hitTargetFrame.maxY == 60)
    }
}

@Suite("Mac window control visibility")
struct WindowControlVisibilityStateTests {
    @Test("Controls start hidden and hide two seconds after activity")
    func inactivityDeadline() {
        var state = WindowControlVisibilityState()

        #expect(!state.isVisible)
        state.recordPointerActivity(at: .zero)
        #expect(state.isVisible)
        #expect(state.nextHideDeadline == .seconds(2))

        state.update(at: .seconds(1.999))
        #expect(state.isVisible)
        state.update(at: .seconds(2))
        #expect(!state.isVisible)
    }

    @Test("New activity replaces the pending deadline")
    func repeatedActivity() {
        var state = WindowControlVisibilityState()
        state.recordPointerActivity(at: .zero)
        state.recordPointerActivity(at: .seconds(1))
        state.update(at: .seconds(2))
        #expect(state.isVisible)
        state.update(at: .seconds(3))
        #expect(!state.isVisible)
    }

    @Test("Hover keeps controls visible and leaving restarts the deadline")
    func controlHover() {
        var state = WindowControlVisibilityState()
        state.recordPointerActivity(at: .zero)
        state.setPointerOverControl(true, at: .seconds(1))
        state.update(at: .seconds(5))
        #expect(state.isVisible)
        #expect(state.nextHideDeadline == nil)

        state.setPointerOverControl(false, at: .seconds(5))
        #expect(state.nextHideDeadline == .seconds(7))
        state.update(at: .seconds(7))
        #expect(!state.isVisible)
    }

    @Test("Pointer exit clears control hover and teardown resets state")
    func exitAndReset() {
        var state = WindowControlVisibilityState()
        state.recordPointerActivity(at: .zero)
        state.setPointerOverControl(true, at: .seconds(1))
        state.pointerExitedWindow(at: .seconds(2))
        #expect(state.nextHideDeadline == .seconds(4))
        state.update(at: .seconds(4))
        #expect(!state.isVisible)

        state.recordPointerActivity(at: .seconds(5))
        state.reset()
        #expect(state == WindowControlVisibilityState())
    }
}
