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
    @Test("The reference run uses three maximum segment advances and two colons")
    func widthEquation() throws {
        try BrandFont.register()
        let metrics = ClockTypography.metrics(
            fontName: BrandFont.postScriptName,
            referenceSize: 100
        )

        #expect(
            metrics.referenceAdvance
                == (3 * metrics.segmentAdvance) + (2 * metrics.colonAdvance)
        )

        let availableWidth = 1_200.0
        let fontSize = ClockTypography.fontSize(
            availableWidth: availableWidth,
            metrics: metrics
        )
        let scaledReferenceAdvance = metrics.referenceAdvance
            * fontSize / metrics.referenceSize

        #expect(abs(scaledReferenceAdvance - (0.9 * availableWidth)) < 0.000_001)
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

    @Test("Every two-character value uses the same fixed slot centers")
    func everyValueUsesFixedSlotCenters() throws {
        try BrandFont.register()
        let metrics = ClockTypography.metrics(
            fontName: BrandFont.postScriptName,
            referenceSize: 100
        )
        let layout = ClockTypography.layout(
            availableWidth: 1_000,
            metrics: metrics
        )
        let expectedCenters = layout
            .slots(for: ["00", "00", "00"])
            .map(\.centerX)
        let font = CTFontCreateWithName(
            BrandFont.postScriptName as CFString,
            metrics.referenceSize,
            nil
        )

        for value in 0...99 {
            let text = twoDigits(value)
            let slots = layout.slots(for: [text, text, text])
            let path = ClockTypography.glyphPath(
                segments: [text, text, text],
                layout: layout,
                canvasSize: CGSize(width: 1_000, height: 400),
                fontName: BrandFont.postScriptName
            )
            let pathBounds = path.boundingBoxOfPath

            #expect(
                measuredAdvance(of: text, in: font)
                    <= metrics.segmentAdvance
            )
            #expect(slots.map(\.text) == [text, ":", text, ":", text])
            #expect(slots.map(\.centerX) == expectedCenters)
            #expect(!path.isEmpty)
            #expect(pathBounds.minX >= 50)
            #expect(pathBounds.maxX <= 950)
            #expect(pathBounds.minY >= 0)
            #expect(pathBounds.maxY <= 400)
        }

        #expect(abs(layout.runWidth - 900) < 0.000_001)
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
