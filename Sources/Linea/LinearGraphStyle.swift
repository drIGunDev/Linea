//
//  LinearGraphStyle.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//  Assistant: ChatGPT (AI)

import SwiftUI

/// LinearGraphStyle controls container visuals and axis defaults:
/// - background, corner radius, grid opacity,
/// - x/y tick targets and default formatters,
/// - grid master enable flag.
public struct LinearGraphStyle {
    public var gridEnabled: Bool
    public var gridColor: Color
    public var gridOpacity: Double
    public var cornerRadius: CGFloat
    public var background: AnyShapeStyle
    public var xTickTarget: Int
    public var yTickTarget: Int
    
    public init(
        gridEnabled: Bool = true,
        gridColor: Color = .gray,
        gridOpacity: Double = 1,
        cornerRadius: CGFloat = 10,
        background: some ShapeStyle = .thinMaterial,
        xTickTarget: Int = 6,
        yTickTarget: Int = 5
    ) {
        self.gridEnabled = gridEnabled
        self.gridColor = gridColor
        self.gridOpacity = gridOpacity
        self.cornerRadius = cornerRadius
        self.background = AnyShapeStyle(background)
        self.xTickTarget = xTickTarget
        self.yTickTarget = yTickTarget
    }
}
