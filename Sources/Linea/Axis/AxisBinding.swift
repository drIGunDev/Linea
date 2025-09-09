//
//  YAxisGroup.swift
//  Linea
//
//  Created by Igor Gun on 06.09.25.
//

import Foundation

/// AxisBinding connects one `YAxis` to a set of series identifiers.
/// The chart uses these bindings to map each series to its Y space.
public final class AxisBinding<SeriesID: Hashable> {
    public let axis: YAxis
    public let seriesIds: Set<SeriesID>
    
    public init(
        axis: YAxis = .init(),
        seriesIds: Set<SeriesID> = []
    ) {
        self.axis = axis
        self.seriesIds = seriesIds
    }
}
