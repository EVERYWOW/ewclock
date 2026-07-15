import CoreText
import Foundation

enum ClockTypography {
    struct Metrics: Equatable, Sendable {
        let referenceSize: CGFloat
        let widestSegment: String
        let segmentAdvance: CGFloat
        let colonAdvance: CGFloat

        var referenceAdvance: CGFloat {
            (3 * segmentAdvance) + (2 * colonAdvance)
        }
    }

    struct Layout: Equatable, Sendable {
        struct Slot: Equatable, Sendable {
            let text: String
            let centerX: CGFloat
        }

        let fontSize: CGFloat
        let segmentWidth: CGFloat
        let colonWidth: CGFloat

        var runWidth: CGFloat {
            (3 * segmentWidth) + (2 * colonWidth)
        }

        func slots(for segments: [String]) -> [Slot] {
            precondition(segments.count == 3, "The clock requires three segments")

            let values = [
                segments[0],
                ":",
                segments[1],
                ":",
                segments[2]
            ]
            let widths = [
                segmentWidth,
                colonWidth,
                segmentWidth,
                colonWidth,
                segmentWidth
            ]
            var leadingEdge = CGFloat.zero

            return zip(values, widths).map { value, width in
                defer { leadingEdge += width }
                return Slot(
                    text: value,
                    centerX: leadingEdge + (width / 2)
                )
            }
        }
    }

    static func metrics(fontName: String, referenceSize: CGFloat) -> Metrics {
        precondition(referenceSize > 0, "Reference font size must be positive")

        let font = CTFontCreateWithName(fontName as CFString, referenceSize, nil)
        let segmentMeasurements = (0...99).map { value in
            let text = String(
                format: "%02d",
                locale: Locale(identifier: "en_US_POSIX"),
                value
            )
            return (text: text, advance: advance(of: text, in: font))
        }
        let maximumAdvance = segmentMeasurements.map(\.advance).max()!
        let widestSegment = segmentMeasurements.first {
            $0.advance == maximumAdvance
        }!

        return Metrics(
            referenceSize: referenceSize,
            widestSegment: widestSegment.text,
            segmentAdvance: widestSegment.advance,
            colonAdvance: advance(of: ":", in: font)
        )
    }

    static func fontSize(availableWidth: CGFloat, metrics: Metrics) -> CGFloat {
        precondition(availableWidth >= 0, "Available width cannot be negative")
        precondition(metrics.referenceAdvance > 0, "Reference advance must be positive")

        return metrics.referenceSize
            * ((0.9 * availableWidth) / metrics.referenceAdvance)
    }

    static func layout(availableWidth: CGFloat, metrics: Metrics) -> Layout {
        let fontSize = fontSize(
            availableWidth: availableWidth,
            metrics: metrics
        )
        let scale = fontSize / metrics.referenceSize

        return Layout(
            fontSize: fontSize,
            segmentWidth: metrics.segmentAdvance * scale,
            colonWidth: metrics.colonAdvance * scale
        )
    }

    static func glyphPath(
        segments: [String],
        layout: Layout,
        canvasSize: CGSize,
        fontName: String
    ) -> CGPath {
        let font = CTFontCreateWithName(
            fontName as CFString,
            layout.fontSize,
            nil
        )
        let path = CGMutablePath()
        let runOriginX = (canvasSize.width - layout.runWidth) / 2
        let baselineY = (canvasSize.height / 2)
            + ((CTFontGetAscent(font) - CTFontGetDescent(font)) / 2)

        for slot in layout.slots(for: segments) {
            append(
                slot.text,
                centeredAt: runOriginX + slot.centerX,
                baselineY: baselineY,
                font: font,
                to: path
            )
        }

        return path
    }

    private static func advance(of text: String, in font: CTFont) -> CGFloat {
        let characters = Array(text.utf16)
        var glyphs = Array(repeating: CGGlyph(), count: characters.count)

        let allCharactersMapped = characters.withUnsafeBufferPointer { characterBuffer in
            glyphs.withUnsafeMutableBufferPointer { glyphBuffer in
                CTFontGetGlyphsForCharacters(
                    font,
                    characterBuffer.baseAddress!,
                    glyphBuffer.baseAddress!,
                    characters.count
                )
            }
        }
        precondition(allCharactersMapped, "The clock font must contain \(text)")

        return glyphs.withUnsafeBufferPointer { glyphBuffer in
            CTFontGetAdvancesForGlyphs(
                font,
                .horizontal,
                glyphBuffer.baseAddress!,
                nil,
                glyphs.count
            )
        }
    }

    private static func append(
        _ text: String,
        centeredAt centerX: CGFloat,
        baselineY: CGFloat,
        font: CTFont,
        to path: CGMutablePath
    ) {
        let characters = Array(text.utf16)
        var glyphs = Array(repeating: CGGlyph(), count: characters.count)
        var advances = Array(repeating: CGSize.zero, count: characters.count)

        let allCharactersMapped = characters.withUnsafeBufferPointer { characters in
            glyphs.withUnsafeMutableBufferPointer { glyphs in
                CTFontGetGlyphsForCharacters(
                    font,
                    characters.baseAddress!,
                    glyphs.baseAddress!,
                    characters.count
                )
            }
        }
        precondition(allCharactersMapped, "The clock font must contain \(text)")

        _ = glyphs.withUnsafeBufferPointer { glyphs in
            advances.withUnsafeMutableBufferPointer { advances in
                CTFontGetAdvancesForGlyphs(
                    font,
                    .horizontal,
                    glyphs.baseAddress!,
                    advances.baseAddress!,
                    glyphs.count
                )
            }
        }

        var glyphOriginX = centerX
            - (advances.reduce(0) { $0 + $1.width } / 2)
        for (glyph, advance) in zip(glyphs, advances) {
            var transform = CGAffineTransform(
                a: 1,
                b: 0,
                c: 0,
                d: -1,
                tx: glyphOriginX,
                ty: baselineY
            )
            if let glyphPath = CTFontCreatePathForGlyph(
                font,
                glyph,
                &transform
            ) {
                path.addPath(glyphPath)
            }
            glyphOriginX += advance.width
        }
    }
}
