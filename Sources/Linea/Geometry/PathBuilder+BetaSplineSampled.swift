//
//  PatchBuilder+BetaSplineSampled.swift
//  Linea
//
//  Created by Igor Gun on 04.09.25.
//

import SwiftUI

extension PathBuilder {
    
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
}
