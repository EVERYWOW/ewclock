import Foundation

struct ClockTime: Equatable, Sendable {
    let hours: String
    let minutes: String
    let seconds: String

    var segments: [String] {
        [hours, minutes, seconds]
    }

    init(date: Date, timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = timeZone

        let components = calendar.dateComponents(
            [.hour, .minute, .second],
            from: date
        )

        hours = Self.twoDigits(components.hour ?? 0)
        minutes = Self.twoDigits(components.minute ?? 0)
        seconds = Self.twoDigits(components.second ?? 0)
    }

    private static func twoDigits(_ value: Int) -> String {
        String(
            format: "%02d",
            locale: Locale(identifier: "en_US_POSIX"),
            value
        )
    }
}
