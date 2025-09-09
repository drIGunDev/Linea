//
//  LinearGraphStyle.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

/// LinearGraphStyle controls container visuals and axis defaults:
/// - background, corner radius, grid opacity,
/// - x/y tick targets and default formatters,
/// - grid master enable flag.
public struct LinearGraphStyle: Sendable, Hashable {
    public var gridEnabled: Bool = true
    public var gridOpacity: Double
    public var cornerRadius: CGFloat
    public var background: AnyShapeStyle
    public var xTickTarget: Int
    public var yTickTarget: Int
    
    public init(
        gridEnabled: Bool = true,
        gridOpacity: Double = 0.12,
        cornerRadius: CGFloat = 12,
        background: some ShapeStyle = .thinMaterial,
        xTickTarget: Int = 6,
        yTickTarget: Int = 5
    ) {
        self.gridEnabled = gridEnabled
        self.gridOpacity = gridOpacity
        self.cornerRadius = cornerRadius
        self.background = AnyShapeStyle(background)
        self.xTickTarget = xTickTarget
        self.yTickTarget = yTickTarget
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
