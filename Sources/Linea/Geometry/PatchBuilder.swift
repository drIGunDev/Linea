//
//  PatchBuilder.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

@usableFromInline
struct PathBuilder {
    
    // MARK: - Linear
    @usableFromInline
    static func linePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        return path
    }
    
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
    
    // MARK: - Beta-spline (Barsky) — sampled evaluator
    // Practical approach: evaluate curve samples per segment (C^2 smooth), then polyline.
    // Parameters:
    //   bias β1 ~ [-1,1] (skews toward prev/next)
    //   tension β2 > 0   (tightness; 1 = B-spline-like)
    static func betaSplineSampled(points: [CGPoint],
                                  bias beta1: CGFloat = 0,
                                  tension beta2: CGFloat = 1,
                                  samplesPerSegment: Int = 12) -> Path {
        let pts = points
        let n = pts.count
        guard n >= 4 else { return linePath(points: pts) } // need at least 4 for cubic family
        
        // Basis weights per Barsky are complicated; we'll use a common practical form:
        // Treat as a β-adjusted uniform cubic B-spline; evaluate via local 4-pt window and
        // tweak blending by (beta1, beta2) to bias/tighten.
        // This is an approximation geared for chart aesthetics.
        
        func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
        }
        
        // Cubic B-spline basis (uniform) for u in [0,1]
        func b0(_ u: CGFloat) -> CGFloat { ((1-u)*(1-u)*(1-u))/6 }
        func b1(_ u: CGFloat) -> CGFloat { (3*u*u*u - 6*u*u + 4)/6 }
        func b2(_ u: CGFloat) -> CGFloat { (-3*u*u*u + 3*u*u + 3*u + 1)/6 }
        func b3(_ u: CGFloat) -> CGFloat { (u*u*u)/6 }
        
        // Adjusters derived heuristically:
        let kT = max(beta2, 1e-3)               // tension > 0
        let kB = max(min(beta1, 1), -1)         // clamp bias
        
        var path = Path()
        path.move(to: pts[1]) // start near start (B-spline starts inside the hull)
        
        for i in 0..<(n-3) {
            let p0 = pts[i], p1 = pts[i+1], p2 = pts[i+2], p3 = pts[i+3]
            
            for s in 1...samplesPerSegment {
                let u = CGFloat(s) / CGFloat(samplesPerSegment)   // [0,1]
                // Base B-spline blend
                var P = CGPoint(
                    x: p0.x * b0(u) + p1.x * b1(u) + p2.x * b2(u) + p3.x * b3(u),
                    y: p0.y * b0(u) + p1.y * b1(u) + p2.y * b2(u) + p3.y * b3(u)
                )
                // Bias toward forward/backward depending on β1
                if kB != 0 {
                    let forward = lerp(p1, p2, u)
                    P = lerp(P, forward, 0.25 * kB) // mild skew
                }
                // Tension: pull toward p1/p2 midpoint (tighten)
                if kT != 1 {
                    let mid = lerp(p1, p2, 0.5)
                    let tAmt = 0.25 * (1/kT - 1)    // >0 loosens, <0 tightens
                    P = lerp(P, mid, tAmt)
                }
                path.addLine(to: P)
            }
        }
        return path
    }
    
    // MARK: - B-spline (de Boor) — general degree, optional non-uniform knots
    static func bSplinePath(control: [CGPoint],
                            degree k: Int = 3,
                            knots U: [CGFloat]? = nil,
                            samplesPerSpan: Int = 16,
                            parameterization: BSplineParam = .openUniform) -> Path
    {
        let n = control.count
        guard n >= 2, k >= 1, n > k else { return linePath(points: control) }
        
        // Knot vector
        let knots: [CGFloat]
        if let U = U, U.count == n + k + 1 {
            knots = U
        } else {
            switch parameterization {
            case .openUniform:
                knots = openUniformKnots(nControl: n, degree: k)
            case .chordLength:
                knots = chordLengthKnots(points: control, degree: k)
            }
        }
        
        // Valid parameter range
        let u0 = knots[k]
        let u1 = knots[n]
        guard u1 > u0 else { return linePath(points: control) }
        
        // Sample each non-empty span [U[i], U[i+1])
        var path = Path()
        let startPoint = deBoor(control, knots, k, u0)
        path.move(to: startPoint)
        
        // Iterate knot spans with multiplicity (skip zero-length)
        for i in k..<(n) {
            let a = knots[i]
            let b = knots[i+1]
            if b <= a { continue }
            let steps = max(2, samplesPerSpan)
            for s in 1...steps {
                let u = a + (b - a) * CGFloat(s) / CGFloat(steps)
                let P = deBoor(control, knots, k, u)
                path.addLine(to: P)
            }
        }
        return path
    }
    
    // de Boor algorithm for point on B-spline at parameter u
    private static func deBoor(_ P: [CGPoint], _ U: [CGFloat], _ k: Int, _ u: CGFloat) -> CGPoint {
        // Find span i s.t. U[i] <= u < U[i+1]
        let i = findSpan(U, k, u)
        // Copy the local control points
        var d = (0...k).map { P[i - k + $0] }
        
        // de Boor recursion
        for r in 1...k {
            for j in stride(from: k, through: r, by: -1) {
                let ij = i - k + j
                let alpha = (u - U[ij]) / max(U[ij + k - r + 1] - U[ij], .ulpOfOne)
                let a = d[j-1], b = d[j]
                d[j] = CGPoint(x: (1 - alpha) * a.x + alpha * b.x,
                               y: (1 - alpha) * a.y + alpha * b.y)
            }
        }
        return d[k]
    }
    
    // Find span index i for u (clamped to valid range)
    private static func findSpan(_ U: [CGFloat], _ k: Int, _ u: CGFloat) -> Int {
        let m = U.count - 1
        let n = m - k - 1
        if u <= U[k]   { return k }
        if u >= U[n+1] { return n }
        var low = k, high = n+1, mid = (low + high)/2
        while !(u >= U[mid] && u < U[mid+1]) {
            if u < U[mid] { high = mid } else { low = mid }
            mid = (low + high)/2
        }
        return mid
    }
    
    // Open-uniform (clamped) knot vector
    private static func openUniformKnots(nControl n: Int, degree k: Int) -> [CGFloat] {
        let m = n + k + 1
        var U = [CGFloat](repeating: 0, count: m)
        // First k+1 zeros, last k+1 ones
        for j in 0..<(m) {
            if j <= k { U[j] = 0 }
            else if j >= m - k - 1 { U[j] = 1 }
            else {
                U[j] = CGFloat(j - k) / CGFloat(m - 2*k - 1)
            }
        }
        return U
    }
    
    // Chord-length non-uniform knots (centripetal-ish)
    private static func chordLengthKnots(points: [CGPoint], degree k: Int) -> [CGFloat] {
        let n = points.count
        var d: [CGFloat] = [0]
        for i in 1..<n {
            let dx = points[i].x - points[i-1].x
            let dy = points[i].y - points[i-1].y
            d.append(d.last! + sqrt(dx*dx + dy*dy))
        }
        let total = max(d.last!, .ulpOfOne)
        let t = d.map { $0 / total } // normalized parameters
        
        var U = [CGFloat](repeating: 0, count: n + k + 1)
        for j in 0...k { U[j] = 0 }
        for j in (n)...(n+k) { U[j] = 1 }
        if n - k - 1 > 0 {
            for j in 1...(n - k - 1) {
                // average of k interior parameters
                var sum: CGFloat = 0
                for r in j..<(j+k) { sum += t[r] }
                U[j+k] = sum / CGFloat(k)
            }
        }
        return U
    }
}
