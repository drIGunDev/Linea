//
//  AxisScale.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//  Assistant: ChatGPT (AI)

import SwiftUI

/// LinearScale holds current and original min/max and supports:
/// - unit mapping (value ↔︎ [0,1]),
/// - pan/zoom with clamping to original range (if enabled),
/// - `reset()` to original.
public protocol AxisScale: AnyObject, Hashable {
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

extension AxisScale {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(originalMin)
        hasher.combine(originalMax)
        hasher.combine(min)
        hasher.combine(max)
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.originalMax == rhs.originalMax &&
        lhs.originalMin == rhs.originalMin &&
        lhs.min == rhs.min &&
        lhs.max == rhs.max
    }
}
