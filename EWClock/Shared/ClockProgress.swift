import Foundation

struct ClockProgress: Equatable, Sendable {
    let hourFraction: Double
    let minuteFraction: Double

    init(date: Date, calendar: Calendar = .current) {
        let components = calendar.dateComponents(
            [.minute, .second, .nanosecond],
            from: date
        )
        let minute = Double(components.minute ?? 0)
        let second = Double(components.second ?? 0)
        let fractionalSecond = Double(components.nanosecond ?? 0)
            / 1_000_000_000

        hourFraction = Self.clamp(
            ((minute * 60) + second + fractionalSecond) / 3_600
        )
        minuteFraction = Self.clamp(
            (second + fractionalSecond) / 60
        )
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }
}
