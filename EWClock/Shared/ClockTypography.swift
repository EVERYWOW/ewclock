import CoreText
import Foundation

enum ClockTypography {
    struct Metrics: Equatable, Sendable {
        let referenceSize: CGFloat
        let widestSegment: String
        let segmentAdvance: CGFloat
        let colonAdvance: CGFloat
        let segmentLeadingInkInsets: [String: CGFloat]
        let ascent: CGFloat
        let descent: CGFloat

        var mainReferenceAdvance: CGFloat {
            (2 * segmentAdvance) + colonAdvance
        }
    }

    struct Layout: Equatable, Sendable {
        struct Slot: Equatable, Sendable {
            let text: String
            let centerX: CGFloat
        }

        let mainFontSize: CGFloat
        let secondsFontSize: CGFloat
        let mainSegmentWidth: CGFloat
        let mainColonWidth: CGFloat
        let secondsSegmentWidth: CGFloat
        let mainAscent: CGFloat
        let mainDescent: CGFloat
        let secondsAscent: CGFloat
        let secondsDescent: CGFloat
        let lineGap: CGFloat

        var mainRunWidth: CGFloat {
            (2 * mainSegmentWidth) + mainColonWidth
        }

        var mainLineHeight: CGFloat {
            mainAscent + mainDescent
        }

        var secondsLineHeight: CGFloat {
            secondsAscent + secondsDescent
        }

        var blockHeight: CGFloat {
            mainLineHeight + lineGap + secondsLineHeight
        }

        func blockOriginY(canvasHeight: CGFloat) -> CGFloat {
            (canvasHeight - blockHeight) / 2
        }

        func mainSlots(hours: String, minutes: String) -> [Slot] {
            precondition(hours.count == 2, "Hours require two characters")
            precondition(minutes.count == 2, "Minutes require two characters")

            let values = [
                hours,
                ":",
                minutes
            ]
            let widths = [
                mainSegmentWidth,
                mainColonWidth,
                mainSegmentWidth
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

        func secondsSlot(seconds: String) -> Slot {
            precondition(seconds.count == 2, "Seconds require two characters")

            return Slot(
                text: seconds,
                centerX: secondsSegmentWidth / 2
            )
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
        let segmentLeadingInkInsets = Dictionary(
            uniqueKeysWithValues: segmentMeasurements.map { measurement in
                let path = CGMutablePath()
                append(
                    measurement.text,
                    centeredAt: maximumAdvance / 2,
                    baselineY: 0,
                    font: font,
                    to: path
                )
                return (measurement.text, path.boundingBoxOfPath.minX)
            }
        )

        return Metrics(
            referenceSize: referenceSize,
            widestSegment: widestSegment.text,
            segmentAdvance: widestSegment.advance,
            colonAdvance: advance(of: ":", in: font),
            segmentLeadingInkInsets: segmentLeadingInkInsets,
            ascent: CTFontGetAscent(font),
            descent: CTFontGetDescent(font)
        )
    }

    static func mainFontSize(
        availableWidth: CGFloat,
        metrics: Metrics
    ) -> CGFloat {
        precondition(availableWidth >= 0, "Available width cannot be negative")
        precondition(
            metrics.mainReferenceAdvance > 0,
            "Reference advance must be positive"
        )

        return metrics.referenceSize
            * ((0.98 * availableWidth) / metrics.mainReferenceAdvance)
    }

    static func mainInkLeadingInset(
        availableWidth: CGFloat,
        metrics: Metrics,
        leadingSegment: String
    ) -> CGFloat {
        precondition(
            leadingSegment.count == 2,
            "The leading segment requires two characters"
        )
        guard let referenceInkInset = metrics
            .segmentLeadingInkInsets[leadingSegment] else {
            preconditionFailure("The leading segment must contain ASCII digits")
        }
        let mainFontSize = mainFontSize(
            availableWidth: availableWidth,
            metrics: metrics
        )
        let scale = mainFontSize / metrics.referenceSize
        let mainRunWidth = metrics.mainReferenceAdvance * scale
        let advanceInset = (availableWidth - mainRunWidth) / 2

        return advanceInset + (referenceInkInset * scale)
    }

    static func layout(availableSize: CGSize, metrics: Metrics) -> Layout {
        precondition(
            availableSize.height >= 0,
            "Available height cannot be negative"
        )
        precondition(
            metrics.ascent + metrics.descent > 0,
            "Reference line height must be positive"
        )

        let mainFontSize = mainFontSize(
            availableWidth: availableSize.width,
            metrics: metrics
        )
        let normalSecondsFontSize = mainFontSize * (2.0 / 3.0)
        let mainScale = mainFontSize / metrics.referenceSize
        let lineGap = mainFontSize * 0.1
        let referenceLineHeight = metrics.ascent + metrics.descent
        let mainLineHeight = referenceLineHeight * mainScale
        let allowedSecondsLineHeight = max(
            0,
            (0.9 * availableSize.height) - mainLineHeight - lineGap
        )
        let heightLimitedSecondsFontSize = metrics.referenceSize
            * (allowedSecondsLineHeight / referenceLineHeight)
        let secondsFontSize = min(
            normalSecondsFontSize,
            heightLimitedSecondsFontSize
        )
        let secondsScale = secondsFontSize / metrics.referenceSize

        return Layout(
            mainFontSize: mainFontSize,
            secondsFontSize: secondsFontSize,
            mainSegmentWidth: metrics.segmentAdvance * mainScale,
            mainColonWidth: metrics.colonAdvance * mainScale,
            secondsSegmentWidth: metrics.segmentAdvance * secondsScale,
            mainAscent: metrics.ascent * mainScale,
            mainDescent: metrics.descent * mainScale,
            secondsAscent: metrics.ascent * secondsScale,
            secondsDescent: metrics.descent * secondsScale,
            lineGap: lineGap
        )
    }

    static func glyphPath(
        time: ClockTime,
        layout: Layout,
        canvasSize: CGSize,
        fontName: String
    ) -> CGPath {
        let mainFont = CTFontCreateWithName(
            fontName as CFString,
            layout.mainFontSize,
            nil
        )
        let path = CGMutablePath()
        let mainOriginX = (canvasSize.width - layout.mainRunWidth) / 2
        let secondsOriginX = (
            canvasSize.width - layout.secondsSegmentWidth
        ) / 2
        let blockOriginY = layout.blockOriginY(
            canvasHeight: canvasSize.height
        )
        let mainBaselineY = blockOriginY + layout.mainAscent
        let secondsBaselineY = blockOriginY
            + layout.mainLineHeight
            + layout.lineGap
            + layout.secondsAscent

        for slot in layout.mainSlots(
            hours: time.hours,
            minutes: time.minutes
        ) {
            append(
                slot.text,
                centeredAt: mainOriginX + slot.centerX,
                baselineY: mainBaselineY,
                font: mainFont,
                to: path
            )
        }

        if layout.secondsFontSize > 0 {
            let secondsFont = CTFontCreateWithName(
                fontName as CFString,
                layout.secondsFontSize,
                nil
            )
            let secondsSlot = layout.secondsSlot(seconds: time.seconds)
            append(
                secondsSlot.text,
                centeredAt: secondsOriginX + secondsSlot.centerX,
                baselineY: secondsBaselineY,
                font: secondsFont,
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
