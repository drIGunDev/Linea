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
    public var gridEnabled: Bool = true
    public var gridOpacity: Double
    public var cornerRadius: CGFloat
    public var background: AnyShapeStyle
    public var xTickTarget: Int
    public var yTickTarget: Int
//    public var xFormatter: any AxisFormatter
    public var yFormatter: any AxisFormatter
//    public var xTickProvider: any TickProvider
    public var yTickProvider: any TickProvider
    
    public init(
        gridEnabled: Bool = true,
        gridOpacity: Double = 0.12,
        cornerRadius: CGFloat = 12,
        background: some ShapeStyle = .thinMaterial,
        xTickTarget: Int = 6,
        yTickTarget: Int = 5,
//        xFormatter: any AxisFormatter = NumberAxisFormatter(decimals: 0, useSI: true),
        yFormatter: any AxisFormatter = NumberAxisFormatter(decimals: 2),
//        xTickProvider: any TickProvider = NiceTickProvider(),
        yTickProvider: any TickProvider = NiceTickProvider()
    ) {
        self.gridEnabled = gridEnabled
        self.gridOpacity = gridOpacity
        self.cornerRadius = cornerRadius
        self.background = AnyShapeStyle(background)
        self.xTickTarget = xTickTarget
        self.yTickTarget = yTickTarget
//        self.xFormatter = xFormatter
        self.yFormatter = yFormatter
//        self.xTickProvider = xTickProvider
        self.yTickProvider = yTickProvider
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
