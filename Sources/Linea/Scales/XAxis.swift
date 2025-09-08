//
//  XAxis.swift
//  Linea
//
//  Created by Igor Gun on 06.09.25.
//

import SwiftUI

@Observable public final class XAxis {
    public let scale: LinearScale
    public let autoRange: AxisAutoRange
    public let tickProvider: any TickProvider
    public let formatter: any AxisFormatter
    
    public init(scale: LinearScale,
                autoRange: AxisAutoRange = .padded(frac: 0.05, nice: true),
                tickProvider: any TickProvider = NiceTickProvider(),
                formatter: any AxisFormatter = NumberAxisFormatter(decimals: 2),
                gridEnabled: Bool = true,
                color: Color? = nil) {
        self.scale = scale
        self.autoRange = autoRange
        self.tickProvider = tickProvider
        self.formatter = formatter
    }
    
    public convenience init(autoRange: AxisAutoRange = .padded(frac: 0.05, nice: true),
                            tickProvider: any TickProvider = NiceTickProvider(),
                            formatter: any AxisFormatter = NumberAxisFormatter(decimals: 2),
                            gridEnabled: Bool = true,
                            color: Color? = nil) {
        self.init(
            scale: .init(min: 0, max: 0),
            autoRange: autoRange,
            tickProvider: tickProvider,
            formatter: formatter
        )
    }

    public func resolveRange(maxMin: (Double, Double), targetTicks: Int) {
        let xr = Linea.resolveRange(range: autoRange, raw: maxMin, targetTicks: targetTicks)
        setMinMax(xr.0, xr.1)
        setOriginalMinMax(xr.0, xr.1)
    }
    
    func setMinMax(_ min: Double, _ max: Double) {
        scale.min = min
        scale.max = max
    }
    
    func setOriginalMinMax(_ min: Double, _ max: Double) {
        scale.setOriginalRange(min: min, max: max)
    }
    
    func recoverOriginalMinMax() {
        scale.min = scale.originalMin
        scale.max = scale.originalMax
    }
}

fileprivate func resolveRange(range: AxisAutoRange,
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
