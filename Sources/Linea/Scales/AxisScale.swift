//
//  AxisScale.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

public protocol AxisScale: AnyObject {
    var min: Double { get set }
    var max: Double { get set }
    func toUnit(_ v: Double) -> Double        // value → [0,1]
    func fromUnit(_ u: Double) -> Double      // [0,1] → value
    func clampSpan(minSpan: Double)
    func zoom(by factor: CGFloat, around value: Double)
    func pan(by delta: Double)
    func reset()
}

@Observable public final class LinearScale: AxisScale {

    public var min: Double
    public var max: Double
    
    private let originalMin: Double
    private let originalMax: Double
    
    public init(min: Double, max: Double) {
        self.min = min; self.originalMin = min
        self.max = max; self.originalMax = max
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
    }

    public func zoom(by factor: CGFloat, around value: Double) {
        let span = (max - min) / Double(factor)
        min = value - span/2
        max = value + span/2
    }

    public func pan(by delta: Double) {
        min += delta; max += delta
    }
    
    public func reset() {
        self.min = originalMin
        self.max = originalMax
    }
}
