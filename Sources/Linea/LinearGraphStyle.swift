//
//  LinearGraphStyle.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

public protocol AxisFormatter: Sendable {
    func string(for value: Double) -> String
}

public struct NumberAxisFormatter: AxisFormatter {
    public init(decimals: Int = 2, useSI: Bool = false) {
        self.decimals = decimals; self.useSI = useSI
    }
    public var decimals: Int
    public var useSI: Bool
    public func string(for value: Double) -> String {
        if useSI {
            let absv = abs(value)
            if absv >= 1_000_000 { return String(format: "%.*fM", decimals, value/1_000_000) }
            if absv >= 1_000 { return String(format: "%.*fk", decimals, value/1_000) }
        }
        return String(format: "%.*f", decimals, value)
    }
}

/// Global/container style (background, grid opacity, corners).
/// Per-series visuals are configured via `SeriesStyle` on `LinearSeries`.
public struct LinearGraphStyle: Sendable, Hashable {
    public var gridOpacity: Double
    public var cornerRadius: CGFloat
    public var background: AnyShapeStyle
    public var xTickTarget: Int
    public var yTickTarget: Int
    public var xFormatter: AxisFormatter   
    public var yFormatter: AxisFormatter
    public var xTickProvider: any TickProvider
    public var yTickProvider: any TickProvider
    
    public init(
        gridOpacity: Double = 0.12,
        cornerRadius: CGFloat = 12,
        background: some ShapeStyle = .thinMaterial,
        xTickTarget: Int = 6,
        yTickTarget: Int = 5,
        xFormatter: AxisFormatter = NumberAxisFormatter(decimals: 0, useSI: true),
        yFormatter: AxisFormatter = NumberAxisFormatter(decimals: 2),
        xTickProvider: any TickProvider = NiceTickProvider(),
        yTickProvider: any TickProvider = NiceTickProvider()
    ) {
        self.gridOpacity = gridOpacity
        self.cornerRadius = cornerRadius
        self.background = AnyShapeStyle(background)
        self.xTickTarget = xTickTarget
        self.yTickTarget = yTickTarget
        self.xFormatter = xFormatter
        self.yFormatter = yFormatter
        self.xTickProvider = xTickProvider
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
