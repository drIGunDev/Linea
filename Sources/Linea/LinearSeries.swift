//
//  LinearSeries.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import Foundation

public struct DataPoint: Sendable, Hashable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}

public struct LinearSeries: Sendable, Hashable {
    public var points: [DataPoint]
    public init(points: [DataPoint]) { self.points = points }
}
