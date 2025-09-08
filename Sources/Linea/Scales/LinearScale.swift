//
//  LinearScale.swift
//  Linea
//
//  Created by Igor Gun on 06.09.25.
//

import SwiftUI

@Observable public final class LinearScale: AxisScale, Hashable {
    
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
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(originalMin)
        hasher.combine(originalMax)
        hasher.combine(min)
        hasher.combine(max)
    }
    
    public static func == (lhs: LinearScale, rhs: LinearScale) -> Bool {
        lhs.originalMax == rhs.originalMax &&
        lhs.originalMin == rhs.originalMin &&
        lhs.min == rhs.min &&
        lhs.max == rhs.max
    }

    private func applyClampToOriginal() {
        guard clampToOriginal else { return }
        let span = max - min
        if min < originalMin { min = originalMin; max = originalMin + span }
        if max > originalMax { max = originalMax; min = originalMax - span }
    }
}
