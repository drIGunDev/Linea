//
//  LinearSeries.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//  Assistant: ChatGPT (AI)

import Foundation

/// LinearSeries holds raw points and per-series visual style (color, width, smoothing, fill).
/// Use `LinearSeries.path(sStyle:pts:)` to construct the curve for Canvas drawing.
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
