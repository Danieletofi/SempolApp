import SwiftUI

/// A rounded rectangle whose edges have subtle, irregular perturbations
/// that give a hand-drawn / sketchy appearance.
///
/// The perturbations are deterministic (seeded from size + corner radius)
/// so the shape does not jitter between renders.
struct HandDrawnRoundedRect: Shape {
    var cornerRadius: CGFloat
    var perturbation: CGFloat = 1.5

    func path(in rect: CGRect) -> Path {
        let cr = min(cornerRadius, min(rect.width, rect.height) / 2)
        let seed = Int(rect.width * 7 + rect.height * 13 + cr * 19)
        var rng = SeededRNG(seed: UInt64(abs(seed)))

        let segmentLength: CGFloat = 8
        var path = Path()

        let insetRect = rect

        // We walk around the rectangle: top, right, bottom, left
        // Between the rounded corners, we subdivide each edge into small segments
        // and offset each control point by a small random amount perpendicular to the edge.

        // Start at top-left corner (after the corner arc)
        let startX = insetRect.minX + cr
        let startY = insetRect.minY
        path.move(to: jitter(CGPoint(x: startX, y: startY), perpendicular: .vertical, rng: &rng))

        // Top edge: left-to-right
        addIrregularLine(
            to: &path,
            from: CGPoint(x: startX, y: insetRect.minY),
            to: CGPoint(x: insetRect.maxX - cr, y: insetRect.minY),
            perpendicular: .vertical,
            segmentLength: segmentLength,
            rng: &rng
        )

        // Top-right corner
        addIrregularArc(to: &path, center: CGPoint(x: insetRect.maxX - cr, y: insetRect.minY + cr),
                        radius: cr, startAngle: -.pi / 2, endAngle: 0, rng: &rng)

        // Right edge: top-to-bottom
        addIrregularLine(
            to: &path,
            from: CGPoint(x: insetRect.maxX, y: insetRect.minY + cr),
            to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - cr),
            perpendicular: .horizontal,
            segmentLength: segmentLength,
            rng: &rng
        )

        // Bottom-right corner
        addIrregularArc(to: &path, center: CGPoint(x: insetRect.maxX - cr, y: insetRect.maxY - cr),
                        radius: cr, startAngle: 0, endAngle: .pi / 2, rng: &rng)

        // Bottom edge: right-to-left
        addIrregularLine(
            to: &path,
            from: CGPoint(x: insetRect.maxX - cr, y: insetRect.maxY),
            to: CGPoint(x: insetRect.minX + cr, y: insetRect.maxY),
            perpendicular: .vertical,
            segmentLength: segmentLength,
            rng: &rng
        )

        // Bottom-left corner
        addIrregularArc(to: &path, center: CGPoint(x: insetRect.minX + cr, y: insetRect.maxY - cr),
                        radius: cr, startAngle: .pi / 2, endAngle: .pi, rng: &rng)

        // Left edge: bottom-to-top
        addIrregularLine(
            to: &path,
            from: CGPoint(x: insetRect.minX, y: insetRect.maxY - cr),
            to: CGPoint(x: insetRect.minX, y: insetRect.minY + cr),
            perpendicular: .horizontal,
            segmentLength: segmentLength,
            rng: &rng
        )

        // Top-left corner
        addIrregularArc(to: &path, center: CGPoint(x: insetRect.minX + cr, y: insetRect.minY + cr),
                        radius: cr, startAngle: .pi, endAngle: 3 * .pi / 2, rng: &rng)

        path.closeSubpath()
        return path
    }

    // MARK: - Helpers

    private enum Axis {
        case horizontal, vertical
    }

    private func jitter(_ point: CGPoint, perpendicular axis: Axis, rng: inout SeededRNG) -> CGPoint {
        let offset = (rng.nextDouble() - 0.5) * 2 * Double(perturbation)
        switch axis {
        case .horizontal:
            return CGPoint(x: point.x + CGFloat(offset), y: point.y)
        case .vertical:
            return CGPoint(x: point.x, y: point.y + CGFloat(offset))
        }
    }

    private func addIrregularLine(to path: inout Path, from start: CGPoint, to end: CGPoint,
                                   perpendicular axis: Axis, segmentLength: CGFloat,
                                   rng: inout SeededRNG) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let length = sqrt(dx * dx + dy * dy)
        let segments = max(1, Int(length / segmentLength))

        for i in 1...segments {
            let t = CGFloat(i) / CGFloat(segments)
            let point = CGPoint(x: start.x + dx * t, y: start.y + dy * t)
            let jittered = (i < segments) ? jitter(point, perpendicular: axis, rng: &rng) : point
            path.addLine(to: jittered)
        }
    }

    private func addIrregularArc(to path: inout Path, center: CGPoint, radius: CGFloat,
                                  startAngle: CGFloat, endAngle: CGFloat,
                                  rng: inout SeededRNG) {
        let arcLength = abs(endAngle - startAngle) * radius
        let steps = max(3, Int(arcLength / 6))

        for i in 1...steps {
            let t = CGFloat(i) / CGFloat(steps)
            let angle = startAngle + (endAngle - startAngle) * t
            var point = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            if i < steps {
                let offset = (rng.nextDouble() - 0.5) * 2 * Double(perturbation) * 0.6
                point.x += CGFloat(offset * cos(Double(angle) + .pi / 2))
                point.y += CGFloat(offset * sin(Double(angle) + .pi / 2))
            }
            path.addLine(to: point)
        }
    }
}

// MARK: - Deterministic pseudo-random number generator

private struct SeededRNG {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 1 : seed
    }

    mutating func nextDouble() -> Double {
        // xorshift64
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return Double(state & 0x7FFFFFFF) / Double(0x7FFFFFFF)
    }
}

// MARK: - View modifier

struct HandDrawnBorderModifier: ViewModifier {
    var cornerRadius: CGFloat = 8
    var lineWidth: CGFloat = 6
    var color: Color = .black
    var fillColor: Color = .white

    func body(content: Content) -> some View {
        content
            .background(
                HandDrawnRoundedRect(cornerRadius: cornerRadius)
                    .fill(fillColor)
            )
            .overlay(
                HandDrawnRoundedRect(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

extension View {
    func handDrawnBorder(
        cornerRadius: CGFloat = 8,
        lineWidth: CGFloat = 6,
        color: Color = .black,
        fillColor: Color = .white
    ) -> some View {
        modifier(HandDrawnBorderModifier(
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            color: color,
            fillColor: fillColor
        ))
    }
}
