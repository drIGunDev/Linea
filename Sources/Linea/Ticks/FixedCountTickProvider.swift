//
//  FixedCountTickProvider.swift
//  Linea
//
//  Created by Igor Gun on 04.09.25.
//

import Foundation

public struct FixedCountTickProvider: TickProvider {
    public func ticks(scale: AxisScale, target: Int) -> [Tick] {
        let a = scale.min, b = scale.max
        guard b > a else { return [] }
        let step = (b - a) / Double(target)
        return (0...target).map { i in
            Tick(value: a + Double(i) * step, label: "")
        }
    }
}
