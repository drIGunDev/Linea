//
//  AxisAutorange.swift
//  Linea
//
//  Created by Igor Gun on 06.09.25.
//

import Foundation

public enum AxisAutoRange: Equatable {
    case none                                 // use current scale values as-is
    case fixed(min: Double, max: Double)
    case padded(frac: Double = 0.05, nice: Bool = true)
}

// MARK: - Auto range helpers
public struct AutoRanger {
    public static func dataBoundsX<SeriesId: Hashable>(series: [SeriesId: LinearSeries]) -> (min: Double, max: Double) {
        var mn = Double.infinity, mx = -Double.infinity
        for s in series.values { for p in s.points { mn = min(mn, p.x); mx = max(mx, p.x) } }
        if !mn.isFinite || !mx.isFinite { return (0, 1) }
        if mn == mx { return (mn - 0.5, mx + 0.5) }
        return (mn, mx)
    }
    
    public static func dataBoundsY(series: [LinearSeries]) -> (min: Double, max: Double) {
        var mn = Double.infinity, mx = -Double.infinity
        for s in series { for p in s.points { mn = min(mn, p.y); mx = max(mx, p.y) } }
        if !mn.isFinite || !mx.isFinite { return (0, 1) }
        if mn == mx { return (mn - 0.5, mx + 0.5) }
        return (mn, mx)
    }
    
    public static func withPadding(min: Double, max: Double, frac: Double) -> (Double, Double) {
        let span = max - min
        let pad = span * Swift.max(frac, 0)
        return (min - pad, max + pad)
    }
    
    public static func nice(min: Double, max: Double, targetTicks: Int = 5) -> (Double, Double) {
        let span = max - min
        guard span > 0, targetTicks > 0 else { return (min, max) }
        let rough = span / Double(targetTicks)
        let pow10 = pow(10.0, floor(log10(rough)))
        let step = [1.0, 2.0, 5.0].map { $0 * pow10 }.min(by: { abs($0 - rough) < abs($1 - rough) }) ?? rough
        let niceMin = floor(min / step) * step
        let niceMax = ceil(max  / step) * step
        return (niceMin, niceMax)
    }
}
