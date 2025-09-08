//
//  Axis.swift
//  Linea
//
//  Created by Igor Gun on 08.09.25.
//

import SwiftUI

public class Axis {
    public let scale: LinearScale
    public let autoRange: AxisAutoRange
    public let tickProvider: any TickProvider
    public let formatter: any AxisFormatter
    
    public init(
        scale: LinearScale,
        autoRange: AxisAutoRange = .padded(frac: 0.05, nice: true),
        tickProvider: any TickProvider = NiceTickProvider(),
        formatter: any AxisFormatter = NumberAxisFormatter(decimals: 2),
        labelingEnabled: Bool = true,
        labelColor: Color? = nil
    ) {
        self.scale = scale
        self.autoRange = autoRange
        self.tickProvider = tickProvider
        self.formatter = formatter
    }
    
    func resolveRange(maxMin: (Double, Double), targetTicks: Int) {
        let xr = Self.resolveRange(range: autoRange, raw: maxMin, targetTicks: targetTicks)
        setMinMax(xr.0, xr.1)
        setOriginalMinMax(xr.0, xr.1)
    }
    
    private func setMinMax(_ min: Double, _ max: Double) {
        scale.min = min
        scale.max = max
    }
    
    private func setOriginalMinMax(_ min: Double, _ max: Double) {
        scale.setOriginalRange(min: min, max: max)
    }
    
    private class func resolveRange(range: AxisAutoRange,
                                    raw: (Double, Double),
                                    targetTicks: Int) -> (Double, Double) {
        var (a,b) = raw
        switch range {
        case .none:
            return (a,b)
        case let .fixed(min, max):
            return (min, max)
        case let .padded(frac, nice):
            (a,b) = AutoRanger.withPadding(min: a, max: b, frac: frac)
            if nice {
                (a,b) = AutoRanger.nice(min: a, max: b, targetTicks: targetTicks)
            }
            return (a,b)
        }
    }
}

