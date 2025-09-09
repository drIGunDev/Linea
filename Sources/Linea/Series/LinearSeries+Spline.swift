//
//  LinearSeries+Spline.swift
//  Linea
//
//  Created by Igor Gun on 09.09.25.
//

import SwiftUI

extension LinearSeries {
    static func path(sStyle: SeriesStyle, pts: [CGPoint]) -> Path {
        let path: Path
        switch sStyle.smoothing {
        case .none:
            path = PathBuilder.linePath(points: pts)
        case let .catmullRom(tension):
            path = PathBuilder.catmullRomUniform(points: pts, tension: tension)
        case .monotoneCubic:
            let xs = pts.map { $0.x }, ys = pts.map { $0.y }
            path = PathBuilder.monotoneCubic(xs: xs, ys: ys)
        case let .tcb(t, b, c):
            path = PathBuilder.kochanekBartels(points: pts, tension: t, bias: b, continuity: c)
        case let .betaSpline(bias, tension, samples):
            path = PathBuilder.betaSplineSampled(points: pts, bias: bias, tension: tension, samplesPerSegment: samples)
        case .bSpline(let degree, let knots, let samples, let param):
            path = PathBuilder.bSplinePath(control: pts,
                                           degree: max(1, degree),
                                           knots: knots,
                                           samplesPerSpan: samples,
                                           parameterization: param)
        }
        return path
    }
}
