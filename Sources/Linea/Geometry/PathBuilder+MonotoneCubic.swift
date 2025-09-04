//
//  PatchBuilder+MonotoneCubic.swift
//  Linea
//
//  Created by Igor Gun on 04.09.25.
//

import SwiftUI

extension PathBuilder {
    
    // MARK: - Monotone cubic (Fritsch–Carlson): x must be strictly increasing
    static func monotoneCubic(xs: [CGFloat], ys: [CGFloat]) -> Path {
        let n = xs.count
        guard n > 1 else { return Path() }
        
        // Slopes of secant lines
        var m = [CGFloat](repeating: 0, count: n-1)
        for i in 0..<n-1 {
            let dx = xs[i+1] - xs[i]
            let dy = ys[i+1] - ys[i]
            m[i] = dy / max(dx, 1e-6)
        }
        
        // Tangents (derivatives) at points
        var t = [CGFloat](repeating: 0, count: n)
        t[0] = m[0]
        t[n-1] = m[n-2]
        for i in 1..<n-1 {
            if m[i-1] * m[i] <= 0 { // change of sign → set tangent to 0 to preserve monotonicity
                t[i] = 0
            } else {
                t[i] = (m[i-1] + m[i]) / 2
            }
        }
        
        var path = Path()
        path.move(to: CGPoint(x: xs[0], y: ys[0]))
        for i in 0..<n-1 {
            let x0 = xs[i],   y0 = ys[i]
            let x1 = xs[i+1], y1 = ys[i+1]
            let dx = x1 - x0
            
            // Cubic Hermite to Bézier control points
            let c1 = CGPoint(x: x0 + dx/3, y: y0 + t[i]*dx/3)
            let c2 = CGPoint(x: x1 - dx/3, y: y1 - t[i+1]*dx/3)
            path.addCurve(to: CGPoint(x: x1, y: y1), control1: c1, control2: c2)
        }
        return path
    }
}
