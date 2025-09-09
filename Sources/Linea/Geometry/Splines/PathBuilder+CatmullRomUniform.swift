//
//  PatchBuilder+CatmullRomUniform.swift
//  Linea
//
//  Created by Igor Gun on 04.09.25.
//

import SwiftUI

extension PathBuilder {
    
    // MARK: - Uniform Catmull–Rom → Cubic Bézier
    // tension = 1.0 for classic CR; lower to soften tangents a bit (e.g. 0.8)
    static func catmullRomUniform(points: [CGPoint], tension: CGFloat = 1.0) -> Path {
        var pts = points
        let n = pts.count
        guard n >= 2 else { return Path() }
        if n == 2 { return linePath(points: pts) }
        
        // De-dup consecutive identical points (avoid zero-length segments)
        var cleaned: [CGPoint] = [pts[0]]
        for p in pts.dropFirst() {
            if p != cleaned.last! { cleaned.append(p) }
        }
        pts = cleaned
        if pts.count == 1 { return Path() }
        
        var path = Path()
        path.move(to: pts[0])
        
        // Helper vector ops
        @inline(__always) func add(_ a: CGPoint, _ b: CGPoint) -> CGPoint { .init(x: a.x+b.x, y: a.y+b.y) }
        @inline(__always) func sub(_ a: CGPoint, _ b: CGPoint) -> CGPoint { .init(x: a.x-b.x, y: a.y-b.y) }
        @inline(__always) func mul(_ a: CGPoint, _ s: CGFloat) -> CGPoint { .init(x: a.x*s, y: a.y*s) }
        
        let k = tension / 6.0
        
        for i in 0 ..< pts.count - 1 {
            let p0 = (i == 0) ? pts[i]     : pts[i-1]
            let p1 = pts[i]
            let p2 = pts[i+1]
            let p3 = (i+2 < pts.count) ? pts[i+2] : pts[i+1]
            
            let c1 = add(p1, mul(sub(p2, p0), k))
            let c2 = sub(p2, mul(sub(p3, p1), k))
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }
}
