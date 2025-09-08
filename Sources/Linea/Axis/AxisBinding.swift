//
//  YAxisGroup.swift
//  Linea
//
//  Created by Igor Gun on 06.09.25.
//

import Foundation

public final class AxisBinding<SeriesId: Hashable> {
    public let axis: YAxis
    public let seriesIds: Set<SeriesId>
    
    public init(
        axes: YAxis = .init(),
        seriesIds: Set<SeriesId> = []
    ) {
        self.axis = axes
        self.seriesIds = seriesIds
    }
}
