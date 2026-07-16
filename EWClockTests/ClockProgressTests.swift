import CoreGraphics
import Foundation
import Testing

@Suite("Clock progress")
struct ClockProgressTests {
    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    @Test("Hour and minute progress include fractional seconds")
    func fractionalProgress() {
        let date = utcCalendar.date(
            from: DateComponents(
                year: 2026,
                month: 7,
                day: 16,
                hour: 12,
                minute: 30,
                second: 30,
                nanosecond: 250_000_000
            )
        )!
        let progress = ClockProgress(date: date, calendar: utcCalendar)

        #expect(
            abs(progress.hourFraction - (1_830.25 / 3_600))
                < 0.000_001
        )
        #expect(
            abs(progress.minuteFraction - (30.25 / 60))
                < 0.000_001
        )
    }

    @Test("Progress resets at hour and minute boundaries")
    func resets() {
        let date = utcCalendar.date(
            from: DateComponents(
                year: 2026,
                month: 7,
                day: 16,
                hour: 13
            )
        )!
        let progress = ClockProgress(date: date, calendar: utcCalendar)

        #expect(progress.hourFraction == 0)
        #expect(progress.minuteFraction == 0)
    }
}

@Suite("Clock progress layout")
struct ClockProgressLayoutTests {
    @Test("Bars use width-based thickness and elapsed widths")
    func normalGeometry() {
        let layout = ClockProgressLayout(
            availableSize: CGSize(width: 1_000, height: 400),
            hourFraction: 0.5,
            minuteFraction: 1
        )

        #expect(layout.thickness == 5)
        #expect(
            layout.topFrame
                == CGRect(x: 0, y: 0, width: 500, height: 5)
        )
        #expect(
            layout.bottomFrame
                == CGRect(
                    x: 0,
                    y: 395,
                    width: 1_000,
                    height: 5
                )
        )
    }

    @Test("Elapsed widths clamp from zero through full width")
    func clampedWidths() {
        let layout = ClockProgressLayout(
            availableSize: CGSize(width: 800, height: 300),
            hourFraction: -1,
            minuteFraction: 2
        )

        #expect(layout.topFrame.width == 0)
        #expect(layout.bottomFrame.width == 800)
    }

    @Test("Zero available width produces empty bars")
    func zeroWidth() {
        let layout = ClockProgressLayout(
            availableSize: CGSize(width: 0, height: 300),
            hourFraction: 0.5,
            minuteFraction: 0.5
        )

        #expect(layout.thickness == 0)
        #expect(layout.topFrame.width == 0)
        #expect(layout.bottomFrame.width == 0)
        #expect(layout.bottomFrame.minY == 300)
    }

    @Test("Thickness clamps to a degenerate available height")
    func degenerateHeight() {
        let layout = ClockProgressLayout(
            availableSize: CGSize(width: 1_000, height: 1),
            hourFraction: 0.5,
            minuteFraction: 0.5
        )

        #expect(layout.thickness == 1)
        #expect(layout.topFrame.minY == 0)
        #expect(layout.bottomFrame.minY == 0)
    }
}
