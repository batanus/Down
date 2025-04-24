//
//  DownLayoutManager.swift
//  Down
//
//  Created by John Nguyen on 02.08.19.
//  Copyright © 2016-2019 Down. All rights reserved.
//

#if !os(watchOS) && !os(Linux)

#if canImport(UIKit)

import UIKit

#elseif canImport(AppKit)

import AppKit

#endif

/// A layout manager capable of drawing the custom attributes set by the `DownStyler`.
///
/// Insert this into a TextKit stack manually, or use the provided `DownTextView`.

public class DownLayoutManager: NSLayoutManager {

    // MARK: - Graphic context

    #if canImport(UIKit)
    var context: CGContext? {
        return UIGraphicsGetCurrentContext()
    }

    func push(context: CGContext) {
        UIGraphicsPushContext(context)
    }

    func popContext() {
        UIGraphicsPopContext()
    }

    #elseif canImport(AppKit)
    var context: CGContext? {
        return NSGraphicsContext.current?.cgContext
    }

    func push(context: CGContext) {
        NSGraphicsContext.saveGraphicsState()
    }

    func popContext() {
        NSGraphicsContext.restoreGraphicsState()
    }

    #endif

    // MARK: - Drawing

    override public func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        drawCustomBackgrounds(forGlyphRange: glyphsToShow, at: origin)
        super.drawGlyphs(forGlyphRange: glyphsToShow, at: origin)
        drawCustomAttributes(forGlyphRange: glyphsToShow, at: origin)
    }

    private func drawCustomBackgrounds(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let context = context else { return }
        push(context: context)
        defer { popContext() }

        guard let textStorage = textStorage else { return }

        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)

        textStorage.enumerateAttributes(for: .blockBackgroundColor,
                                        in: characterRange) { (attr: BlockBackgroundColorAttribute, blockRange) in
            let inset = attr.inset

            context.setFillColor(attr.color.cgColor)

            let allBlockColorRanges = glyphRanges(for: .blockBackgroundColor,
                                                  in: textStorage,
                                                  inCharacterRange: blockRange)

            let glyphRange = self.glyphRange(forCharacterRange: blockRange, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: glyphRange) { lineRect, lineUsedRect, container, lineGlyphRange, _ in
                let isLineStartOfBlock = allBlockColorRanges.contains {
                    lineGlyphRange.overlapsStart(of: $0)
                }

                let isLineEndOfBlock = allBlockColorRanges.contains {
                    lineGlyphRange.overlapsEnd(of: $0)
                }

                let minX = lineUsedRect.minX + container.lineFragmentPadding - inset
                let maxX = lineRect.maxX
                let minY = isLineStartOfBlock ? lineUsedRect.minY - inset : lineRect.minY
                let maxY = isLineEndOfBlock ? lineUsedRect.maxY + inset : lineUsedRect.maxY
                let blockRect = CGRect(minX: minX, minY: minY, maxX: maxX, maxY: maxY).translated(by: origin)

                // Draw code‑block background with rounded corners only on the outer edges
                let cornerRadius: CGFloat = 16

                #if canImport(UIKit)
                var corners: UIRectCorner = []
                if isLineStartOfBlock { corners.formUnion([.topLeft, .topRight]) }
                if isLineEndOfBlock   { corners.formUnion([.bottomLeft, .bottomRight]) }

                if corners.isEmpty {
                    context.fill(blockRect)
                } else {
                    let path = UIBezierPath(
                        roundedRect: blockRect,
                        byRoundingCorners: corners,
                        cornerRadii: CGSize(width: cornerRadius, height: cornerRadius)
                    )
                    path.fill()
                }
                #else
                // macOS: build a CGPath that rounds only the requested corners
                let cgPath = DownLayoutManager.roundedPath(
                    in: blockRect,
                    topLeft:  isLineStartOfBlock ? cornerRadius : 0,
                    topRight: isLineStartOfBlock ? cornerRadius : 0,
                    bottomLeft:  isLineEndOfBlock ? cornerRadius : 0,
                    bottomRight: isLineEndOfBlock ? cornerRadius : 0
                )
                context.addPath(cgPath)
                context.fillPath()
                #endif
            }
        }
    }

    private func drawCustomAttributes(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        let characterRange = self.characterRange(forGlyphRange: glyphsToShow, actualGlyphRange: nil)
        drawThematicBreakIfNeeded(in: characterRange, at: origin)
        drawQuoteStripeIfNeeded(in: characterRange, at: origin)
    }

    private func drawThematicBreakIfNeeded(in characterRange: NSRange, at origin: CGPoint) {
        guard let context = context else { return }
        push(context: context)
        defer { popContext() }

        textStorage?.enumerateAttributes(for: .thematicBreak,
                                         in: characterRange) { (attr: ThematicBreakAttribute, range) in

            let firstGlyphIndex = glyphIndexForCharacter(at: range.lowerBound)

            let lineRect = lineFragmentRect(forGlyphAt: firstGlyphIndex, effectiveRange: nil)
            let usedRect = lineFragmentUsedRect(forGlyphAt: firstGlyphIndex, effectiveRange: nil)

            let lineStart = usedRect.minX + fragmentPadding(forGlyphAt: firstGlyphIndex)

            let width = lineRect.width - lineStart
            let height = lineRect.height

            let boundingRect = CGRect(x: lineStart, y: lineRect.minY, width: width, height: height)
            let adjustedLineRect = boundingRect.translated(by: origin)

            drawThematicBreak(with: context, in: adjustedLineRect, attr: attr)
        }
    }

    private func fragmentPadding(forGlyphAt glyphIndex: Int) -> CGFloat {
        let textContainer = self.textContainer(forGlyphAt: glyphIndex, effectiveRange: nil)
        return textContainer?.lineFragmentPadding ?? 0
    }

    private func drawThematicBreak(with context: CGContext, in rect: CGRect, attr: ThematicBreakAttribute) {
        context.setStrokeColor(attr.color.cgColor)
        context.setLineWidth(attr.thickness)
        context.move(to: CGPoint(x: rect.minX, y: rect.midY))
        context.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        context.strokePath()
    }

    private func drawQuoteStripeIfNeeded(in characterRange: NSRange, at origin: CGPoint) {
        guard let context = context else { return }
        push(context: context)
        defer { popContext() }

        textStorage?.enumerateAttributes(for: .quoteStripe,
                                         in: characterRange) { (attr: QuoteStripeAttribute, quoteRange) in

            context.setFillColor(attr.color.cgColor)

            let glyphRangeOfQuote = self.glyphRange(forCharacterRange: quoteRange, actualCharacterRange: nil)

            enumerateLineFragments(forGlyphRange: glyphRangeOfQuote) { lineRect, _, container, _, _ in
                let locations = attr.locations.map {
                    CGPoint(x: $0 + container.lineFragmentPadding, y: 0)
                        .translated(by: lineRect.origin)
                        .translated(by: origin)
                }

                let stripeSize = CGSize(width: attr.thickness, height: lineRect.height)
                self.drawQuoteStripes(with: context, locations: locations, size: stripeSize)
            }
        }
    }

    private func drawQuoteStripes(with context: CGContext, locations: [CGPoint], size: CGSize) {
        locations.forEach {
            let stripeRect = CGRect(origin: $0, size: size)
            context.fill(stripeRect)
        }
    }

    private func glyphRanges(for key: NSAttributedString.Key,
                             in storage: NSTextStorage,
                             inCharacterRange range: NSRange) -> [NSRange] {

        return storage
            .ranges(of: key, in: range)
            .map { self.glyphRange(forCharacterRange: $0, actualCharacterRange: nil) }
            .mergeNeighbors()
    }
}

// MARK: - Helpers

private extension NSRange {

    func overlapsStart(of range: NSRange) -> Bool {
        return lowerBound <= range.lowerBound && upperBound > range.lowerBound
    }

    func overlapsEnd(of range: NSRange) -> Bool {
        return lowerBound < range.upperBound && upperBound >= range.upperBound
    }

}

private extension Array where Element == NSRange {

    func mergeNeighbors() -> [Element] {
        let sorted = self.sorted { $0.lowerBound <= $1.lowerBound }

        let result = sorted.reduce(into: [NSRange]()) { acc, next in
            guard let last = acc.popLast() else {
                acc.append(next)
                return
            }

            guard last.upperBound == next.lowerBound else {
                acc.append(contentsOf: [last, next])
                return
            }

            acc.append(NSRange(location: last.lowerBound, length: next.upperBound - last.lowerBound))
        }

        return result
    }

}

#if canImport(AppKit) && !os(iOS)
private extension DownLayoutManager {
    /// Creates a CGPath with individually rounded corners (needed for macOS).
    static func roundedPath(
        in rect: CGRect,
        topLeft: CGFloat,
        topRight: CGFloat,
        bottomLeft: CGFloat,
        bottomRight: CGFloat
    ) -> CGPath {

        guard [topLeft, topRight, bottomLeft, bottomRight].contains(where: { $0 > 0 }) else {
            return CGPath(rect: rect, transform: nil)
        }

        let path = CGMutablePath()
        let maxX = rect.maxX, maxY = rect.maxY, minX = rect.minX, minY = rect.minY

        // start at top‑left
        path.move(to: CGPoint(x: minX + topLeft, y: minY))

        // top edge
        path.addLine(to: CGPoint(x: maxX - topRight, y: minY))
        if topRight > 0 {
            path.addArc(center: CGPoint(x: maxX - topRight, y: minY + topRight),
                        radius: topRight,
                        startAngle: -.pi/2,
                        endAngle: 0,
                        clockwise: false)
        }

        // right edge
        path.addLine(to: CGPoint(x: maxX, y: maxY - bottomRight))
        if bottomRight > 0 {
            path.addArc(center: CGPoint(x: maxX - bottomRight, y: maxY - bottomRight),
                        radius: bottomRight,
                        startAngle: 0,
                        endAngle: .pi/2,
                        clockwise: false)
        }

        // bottom edge
        path.addLine(to: CGPoint(x: minX + bottomLeft, y: maxY))
        if bottomLeft > 0 {
            path.addArc(center: CGPoint(x: minX + bottomLeft, y: maxY - bottomLeft),
                        radius: bottomLeft,
                        startAngle: .pi/2,
                        endAngle: .pi,
                        clockwise: false)
        }

        // left edge
        path.addLine(to: CGPoint(x: minX, y: minY + topLeft))
        if topLeft > 0 {
            path.addArc(center: CGPoint(x: minX + topLeft, y: minY + topLeft),
                        radius: topLeft,
                        startAngle: .pi,
                        endAngle: 3 * .pi / 2,
                        clockwise: false)
        }

        path.closeSubpath()
        return path
    }
}
#endif

#endif
