//
//  PatchBuilder.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

public enum BSplineParam: Equatable {
    case openUniform              // clamped open-uniform knots
    case chordLength              // non-uniform (centripetal-ish) from chord lengths
}

public enum Smoothing: Equatable {
    case none
    case catmullRom(_ tension: Double = 0.85)    // 0…1; 0.5 = centripetal (good)
    case monotoneCubic                           // preserves monotonicity in Y
    case tcb(tension: CGFloat = 0.25, bias: CGFloat = 0, continuity: CGFloat = 0)
    case betaSpline(bias: CGFloat = 0.3, tension: CGFloat = 1.2, samplesPerSegment: Int = 10)
    case bSpline(degree: Int = 3,
                     knots: [CGFloat]? = nil,    // if nil → auto open-uniform or chord-length
                     samplesPerSpan: Int = 16,
                     parameterization: BSplineParam = .openUniform)
}

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
}
