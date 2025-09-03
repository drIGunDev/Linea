//
//  NiceTickProvider.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import Foundation

public struct Tick { public let value: Double; public let label: String }

public protocol TickProvider { func ticks(scale: AxisScale, target: Int) -> [Tick] }

public struct NiceTickProvider: TickProvider {
    public init() {}
    public func ticks(scale: AxisScale, target: Int) -> [Tick] {
        let span = max(scale.max - scale.min, 1e-12)
        let rough = span / Double(max(target, 2))
        let pow10 = pow(10.0, floor(log10(rough)))
        let candidates = [1.0, 2.0, 5.0].map { $0 * pow10 }
        let step = candidates.min(by: { abs($0 - rough) < abs($1 - rough) }) ?? rough
        let start = floor(scale.min / step) * step
        let end   = ceil(scale.max / step)  * step
        var out: [Tick] = []
        var v = start
        let fmt: (Double)->String = { String(format: "%g", $0) }
        while v <= end + step*0.5 {
            out.append(.init(value: v, label: fmt(v)))
            v += step
        }
        return out
    }
}
