//
//  FixedCountTickProvider.swift
//  Linea
//
//  Created by Igor Gun on 04.09.25.
//  Assistant: ChatGPT (AI)

import Foundation

/// - FixedCountTickProvider: exactly N intervals over [min,max].
public struct FixedCountTickProvider: TickProvider {
    public init() {}
    public func ticks(scale: any AxisScale, target: Int) -> [Tick] {
        let a = scale.min, b = scale.max
        guard b > a else { return [] }
        let step = (b - a) / Double(target)
        return (0...target).map { i in
            Tick(value: a + Double(i) * step, label: "")
        }
    }
}
