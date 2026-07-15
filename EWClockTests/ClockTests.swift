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
    @Test("The reference run is three 88 advances plus two colon advances")
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

        #expect(
            abs(metrics.segmentAdvance - measuredAdvance(of: "88", in: font))
                < 0.000_001
        )
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
