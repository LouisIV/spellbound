import Foundation
import CoreGraphics

public struct OverlayPlacement: Equatable, Sendable {
    public let frame: CGRect
    public let pointerX: CGFloat
    public let isAbove: Bool

    /// All rectangles use AppKit's bottom-left screen coordinates.
    public static func anchored(to word: CGRect, size: CGSize, visibleScreen: CGRect) -> Self {
        let margin: CGFloat = 8
        let width = min(size.width, visibleScreen.width - margin * 2)
        let height = min(size.height, visibleScreen.height - margin * 2)
        let x = min(max(word.midX - width / 2, visibleScreen.minX + margin),
                    visibleScreen.maxX - width - margin)
        let above = word.maxY + height + 6 <= visibleScreen.maxY - margin
        let y = above ? word.maxY + 6 : word.minY - height - 6
        let frame = CGRect(x: x, y: min(max(y, visibleScreen.minY + margin),
                                      visibleScreen.maxY - height - margin), width: width, height: height)
        return Self(frame: frame, pointerX: min(max(word.midX - x, 16), width - 16), isAbove: above)
    }
}
