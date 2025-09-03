//
//  LinearGraphStyle.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

/// Global/container style (background, grid opacity, corners).
/// Per-series visuals are configured via `SeriesStyle` on `LinearSeries`.
public struct LinearGraphStyle: Sendable, Hashable {
    public var gridOpacity: Double
    public var cornerRadius: CGFloat
    public var background: AnyShapeStyle

    public init(
        gridOpacity: Double = 0.12,
        cornerRadius: CGFloat = 12,
        background: some ShapeStyle = .thinMaterial
    ) {
        self.gridOpacity = gridOpacity
        self.cornerRadius = cornerRadius
        self.background = AnyShapeStyle(background)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(gridOpacity)
        hasher.combine(cornerRadius)
    }
    
    public static func == (lhs: LinearGraphStyle, rhs: LinearGraphStyle) -> Bool {
        lhs.gridOpacity == rhs.gridOpacity
        && lhs.cornerRadius == rhs.cornerRadius
    }
}
