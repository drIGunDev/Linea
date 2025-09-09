//
//  YAxes.swift
//  Linea
//
//  Created by Igor Gun on 08.09.25.
//

import Foundation

/// YAxes binds multiple `YAxis` instances to sets of `SeriesId`.
/// - `bindings`: list of AxisBinding(axis, seriesIds).
/// - `foreachAxis`: iterate axes conveniently.
/// - `resolveRange(series:targetTicks:resetOriginalRange:)`: compute per-axis bounds.
public final class YAxes<SeriesID: Hashable> {
    public var bindings: [AxisBinding<SeriesID>]
    
    public init(bindings: [AxisBinding<SeriesID>] = []) {
        if bindings.count == 0 {
            self.bindings = [AxisBinding<SeriesID>()]
        }
        else {
            self.bindings = bindings
        }
    }
    
    class public func bind(axis: YAxis, to seriesIds: Set<SeriesID>) -> YAxes<SeriesID> {
        .init(bindings: [.init(axis: axis, seriesIds: seriesIds)])
    }
    
    public func bind(axis: YAxis, to seriesIds: Set<SeriesID>) -> YAxes<SeriesID> {
        bindings.append(.init(axis: axis, seriesIds: seriesIds))
        return self
    }
    
    func resolveRange(series: [SeriesID: LinearSeries], targetTicks: Int, resetOriginalRange: Bool = false) {
        func resolveRange(axis: YAxis, seriesArray: [LinearSeries]) {
            guard !seriesArray.isEmpty else { return }
            let (ymin, ymax) = AutoRanger.dataBoundsY(seriesArray: seriesArray)
            axis.resolveRange(maxMin: (ymin, ymax), targetTicks: targetTicks, resetOriginalRange: resetOriginalRange)
        }
        
        func setAxis(axis: YAxis, seriesIds: Set<SeriesID>) {
            
            if seriesIds.isEmpty {
                let seriesesArray = Array(series.values)
                guard seriesesArray.count > 0 else { return }
                
                resolveRange(axis: axis, seriesArray: seriesesArray)
            }
            else {
                var seriesesArray: [LinearSeries] = []
                for id in seriesIds {
                    guard let s = series[id] else { continue }
                    seriesesArray.append(s)
                }
                resolveRange(axis: axis, seriesArray: seriesesArray)
            }
        }
        
        if bindings.isEmpty {
            let axis = YAxis()
            let seriesIds: Set<SeriesID> = Set(series.keys)
            setAxis(axis: axis, seriesIds: seriesIds)
            return
        }
        
        for binding in bindings {
            let axis = binding.axis
            setAxis(axis: axis, seriesIds: binding.seriesIds)
        }
    }
    
    func foreachAxis(_ body: (Axis) -> Void) {
        bindings.forEach { body($0.axis) }
    }
}
