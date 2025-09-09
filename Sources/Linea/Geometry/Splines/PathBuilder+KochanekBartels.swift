//
//  PatchBuilder+KochanekBartels.swift
//  Linea
//
//  Created by Igor Gun on 04.09.25.
//

import SwiftUI

/// PathBuilder converts arrays of points into Path using selected smoothing:
/// - Kochanek–Bartels (TCB),
/// Each method accepts already-mapped view points (CGPoint).
extension PathBuilder {
    
    // MARK: - Kochanek–Bartels (TCB) → Cubic Bézier
    // Uses single global T, B, C for simplicity; extend to per-point if needed.
    static func kochanekBartels(points: [CGPoint],
                                tension T: CGFloat = 0,
                                bias B: CGFloat = 0,
                                continuity C: CGFloat = 0) -> Path {
        let n = points.count
        guard n >= 2 else { return Path() }
        if n == 2 { return linePath(points: points) }
        
        var path = Path()
        path.move(to: points[0])
        
        func vadd(_ a: CGPoint, _ b: CGPoint) -> CGPoint { .init(x: a.x+b.x, y: a.y+b.y) }
        func vsub(_ a: CGPoint, _ b: CGPoint) -> CGPoint { .init(x: a.x-b.x, y: a.y-b.y) }
        func vmul(_ a: CGPoint, _ s: CGFloat) -> CGPoint { .init(x: a.x*s, y: a.y*s) }
        
        // Helper to get clamped point
        func P(_ i: Int) -> CGPoint {
            if i < 0 { return points.first! }
            if i >= n { return points.last! }
            return points[i]
        }
        
        for i in 0..<(n-1) {
            let p0 = P(i-1), p1 = P(i), p2 = P(i+1), p3 = P(i+2)
            
            // Outgoing tangent at p1
            let d10 = vsub(p1, p0)
            let d21 = vsub(p2, p1)
            let out = vadd(vmul(d10, (1 - T) * (1 + C) * (1 + B) / 2), vmul(d21, (1 - T) * (1 - C) * (1 - B) / 2))
            
            // Incoming tangent at p2
            let d32 = vsub(p3, p2)
            let in_ = vadd(vmul(d21, (1 - T) * (1 + C) * (1 - B) / 2), vmul(d32, (1 - T) * (1 - C) * (1 + B) / 2))
            
            // Convert Hermite (p1, p2, out, in) to cubic Bézier
            let c1 = vadd(p1, vmul(out, 1.0/3.0))
            let c2 = vadd(p2, vmul(in_, -1.0/3.0))
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }
}
