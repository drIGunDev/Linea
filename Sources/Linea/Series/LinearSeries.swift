//
//  LinearSeries.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import Foundation
import SwiftUI

public struct DataPoint: Sendable, Hashable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

/// Describes a single plotted series with optional per-series style.
public struct LinearSeries: Equatable {
    public static func == (lhs: LinearSeries, rhs: LinearSeries) -> Bool {
        lhs.id == rhs.id
    }
    
    public var id: String
    public var points: [DataPoint]
    public var style: SeriesStyle?

    public init(id: String = UUID().uuidString,
                points: [DataPoint],
                style: SeriesStyle? = nil) {
        self.id = id
        self.points = points
        self.style = style
    }
}
