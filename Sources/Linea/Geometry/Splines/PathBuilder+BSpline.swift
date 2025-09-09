//
//  PatchBuilder+BSpline.swift
//  Linea
//
//  Created by Igor Gun on 04.09.25.
//

import SwiftUI

/// PathBuilder converts arrays of points into Path using selected smoothing:
/// - B-spline (de Boor; degree; knot parameterization).
/// Each method accepts already-mapped view points (CGPoint).
extension PathBuilder {
    
    // MARK: - B-spline (de Boor) — general degree, optional non-uniform knots
    static func bSplinePath(control: [CGPoint],
                            degree k: Int = 3,
                            knots U: [CGFloat]? = nil,
                            samplesPerSpan: Int = 16,
                            parameterization: BSplineParam = .openUniform) -> Path {
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
