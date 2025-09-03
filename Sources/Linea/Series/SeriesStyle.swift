//
//  SeriesStyle.swift
//  Linea
//
//  Created by Igor Gun on 03.09.25.
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

public struct SeriesStyle {
    public var color: Color
    public var lineWidth: CGFloat
    public var opacity: Double
    public var dash: [CGFloat]?             // e.g., [4,3]
    public var fill: Color?                 // optional area fill under the line
    public var smoothing: Smoothing

    public init(color: Color = .accentColor,
                lineWidth: CGFloat = 2,
                opacity: Double = 1,
                dash: [CGFloat]? = nil,
                fill: Color? = nil,
                smoothing: Smoothing = .none) {
        self.color = color
        self.lineWidth = lineWidth
        self.opacity = opacity
        self.dash = dash
        self.fill = fill
        self.smoothing = smoothing
    }
}
