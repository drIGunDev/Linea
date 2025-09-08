//
//  LinearSeries.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import Foundation

/// Describes a single plotted series with optional per-series style.
public struct LinearSeries: Identifiable, Equatable {
    public var id: String
    public var points: [DataPoint]
    public var style: SeriesStyle?
//    public var yGroupID: String
    
    public init(id: String = UUID().uuidString,
                points: [DataPoint],
                style: SeriesStyle? = nil/*,
                yGroupID: String*/) {
        self.id = id
        self.points = points
        self.style = style
//        self.yGroupID = yGroupID
    }
    
    public static func == (lhs: LinearSeries, rhs: LinearSeries) -> Bool {
        lhs.id == rhs.id
    }
}
