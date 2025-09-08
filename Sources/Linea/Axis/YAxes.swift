//
//  YAxes.swift
//  Linea
//
//  Created by Igor Gun on 08.09.25.
//

import Foundation

public final class YAxes<SeriesId: Hashable> {
    public let bindings: [AxisBinding<SeriesId>]
    
    public init(bindings: [AxisBinding<SeriesId>] = .init()) {
        self.bindings = bindings
    }
    
    func setRanges(series: [SeriesId: LinearSeries], targetTicks: Int) {
        func resolveRange(axisSeries: [LinearSeries], axis: YAxis) {
            guard !axisSeries.isEmpty else { return }
            let (ymin, ymax) = AutoRanger.dataBoundsY(series: axisSeries)
            axis.resolveRange(maxMin: (ymin, ymax), targetTicks: targetTicks)
        }
        
        guard !bindings.isEmpty else { return }
    
        for binding in bindings {
            let axis = binding.axis
            var axisSeries: [LinearSeries] = []
            if binding.seriesIds.isEmpty {
                axisSeries = Array(series.values)
                resolveRange(axisSeries: axisSeries, axis: axis)
            }
            else {
                for id in binding.seriesIds {
                    guard let s = series[id] else { continue }
                    axisSeries.append(s)
                }
                resolveRange(axisSeries: axisSeries, axis: axis)
            }
        }
    }
    
    func foreachAxis(_ body: (Axis) -> Void) {
        for binding in bindings {
            body(binding.axis)
        }
    }
    
    func foreachScale(_ body: (LinearScale) -> Void) {
        for binding in bindings {
            body(binding.axis.scale)
        }
    }

}
