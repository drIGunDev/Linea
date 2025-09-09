//
//  LinearSeries.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import Foundation

/// Describes a single plotted series with optional per-series style.
public struct LinearSeries: Equatable {
    public var points: [DataPoint]
    public var style: SeriesStyle
    
    public init(points: [DataPoint],
                style: SeriesStyle) {
        self.points = points
        self.style = style
    }
    
    public static func == (lhs: LinearSeries, rhs: LinearSeries) -> Bool {
        lhs.points.count == rhs.points.count 
    }
}
