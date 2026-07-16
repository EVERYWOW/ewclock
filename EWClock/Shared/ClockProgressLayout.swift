import CoreGraphics

struct ClockProgressLayout: Equatable, Sendable {
    static let thicknessFraction: CGFloat = 0.005

    let thickness: CGFloat
    let topFrame: CGRect
    let bottomFrame: CGRect

    init(
        availableSize: CGSize,
        hourFraction: Double,
        minuteFraction: Double
    ) {
        let width = max(availableSize.width, 0)
        let height = max(availableSize.height, 0)
        thickness = min(width * Self.thicknessFraction, height)
        topFrame = CGRect(
            x: 0,
            y: 0,
            width: width * Self.clamp(hourFraction),
            height: thickness
        )
        bottomFrame = CGRect(
            x: 0,
            y: height - thickness,
            width: width * Self.clamp(minuteFraction),
            height: thickness
        )
    }

    private static func clamp(_ value: Double) -> CGFloat {
        CGFloat(min(max(value, 0), 1))
    }
}
