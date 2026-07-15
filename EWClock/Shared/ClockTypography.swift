import CoreText

enum ClockTypography {
    struct Metrics: Equatable, Sendable {
        let referenceSize: CGFloat
        let segmentAdvance: CGFloat
        let colonAdvance: CGFloat

        var referenceAdvance: CGFloat {
            (3 * segmentAdvance) + (2 * colonAdvance)
        }
    }

    static func metrics(fontName: String, referenceSize: CGFloat) -> Metrics {
        precondition(referenceSize > 0, "Reference font size must be positive")

        let font = CTFontCreateWithName(fontName as CFString, referenceSize, nil)
        return Metrics(
            referenceSize: referenceSize,
            segmentAdvance: advance(of: "88", in: font),
            colonAdvance: advance(of: ":", in: font)
        )
    }

    static func fontSize(availableWidth: CGFloat, metrics: Metrics) -> CGFloat {
        precondition(availableWidth >= 0, "Available width cannot be negative")
        precondition(metrics.referenceAdvance > 0, "Reference advance must be positive")

        return metrics.referenceSize
            * ((0.9 * availableWidth) / metrics.referenceAdvance)
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
}
