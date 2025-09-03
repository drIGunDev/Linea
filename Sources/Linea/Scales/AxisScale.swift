//
//  AxisScale.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//
import SwiftUI

public protocol AxisScale: AnyObject {
    // current visible range
    var min: Double { get set }
    var max: Double { get set }

    // original data range (for clamping)
    var originalMin: Double { get }
    var originalMax: Double { get }
    var clampToOriginal: Bool { get set }

    // transforms
    func toUnit(_ v: Double) -> Double        // value → [0,1]
    func fromUnit(_ u: Double) -> Double      // [0,1] → value

    // viewport control
    func setOriginalRange(min: Double, max: Double)
    func clampSpan(minSpan: Double)
    func zoom(by factor: CGFloat, around value: Double)
    func pan(by delta: Double)
    func reset()
}

public enum AutoRangeMode {
    case none          // don't touch
    case tight         // exact data min/max
    case padded(x: Double = 0.05, y: Double = 0.05, nice: Bool = true) // add % padding, optionally round to nice ticks
}

@Observable public final class LinearScale: AxisScale {
    public var min: Double
    public var max: Double

    public private(set) var originalMin: Double
    public private(set) var originalMax: Double
    public var clampToOriginal: Bool = true

    public init(min: Double, max: Double) {
        self.min = min; self.max = max
        self.originalMin = min; self.originalMax = max
    }

    public func setOriginalRange(min: Double, max: Double) {
        self.originalMin = min; self.originalMax = max
    }

    public func toUnit(_ v: Double) -> Double {
        let span = Swift.max(max - min, 1e-12)
        return (v - min) / span
    }
    public func fromUnit(_ u: Double) -> Double {
        min + (max - min) * u
    }

    public func clampSpan(minSpan: Double) {
        if max - min < minSpan { let c = (min + max)/2; min = c - minSpan/2; max = c + minSpan/2 }
        applyClampToOriginal()
    }

    public func zoom(by factor: CGFloat, around value: Double) {
        let span = (max - min) / Double(factor)
        min = value - span/2
        max = value + span/2
        applyClampToOriginal()
    }

    public func pan(by delta: Double) {
        min += delta; max += delta
        applyClampToOriginal()
    }

    public func reset() {
        self.min = originalMin
        self.max = originalMax
    }
    
    private func applyClampToOriginal() {
        guard clampToOriginal else { return }
        let span = max - min
        if min < originalMin { min = originalMin; max = originalMin + span }
        if max > originalMax { max = originalMax; min = originalMax - span }
    }
}

// MARK: - Auto range helpers
public struct AutoRanger {
    public static func dataBoundsX(series: [LinearSeries]) -> (min: Double, max: Double) {
        var mn = Double.infinity, mx = -Double.infinity
        for s in series { for p in s.points { mn = min(mn, p.x); mx = max(mx, p.x) } }
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
