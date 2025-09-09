//
//  YAxisGroup.swift
//  Linea
//
//  Created by Igor Gun on 06.09.25.
//

import Foundation

public final class AxisBinding<SeriesID: Hashable> {
    public let axis: YAxis
    public let seriesIds: Set<SeriesID>
    
    public init(
        axes: YAxis = .init(),
        seriesIds: Set<SeriesID> = []
    ) {
        self.axis = axes
        self.seriesIds = seriesIds
    }
}
