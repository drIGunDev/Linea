//
//  LinearGraphStyle.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

public struct LinearGraphStyle: Sendable, Hashable {
    public static func == (lhs: LinearGraphStyle, rhs: LinearGraphStyle) -> Bool {
        lhs.lineWidth == rhs.lineWidth
        && lhs.lineColor == rhs.lineColor
        && lhs.showFill == rhs.showFill
        && lhs.gridOpacity == rhs.gridOpacity
        && lhs.cornerRadius == rhs.cornerRadius
    }
    
    public var lineColor: Color
    public var lineWidth: CGFloat
    public var showFill: Bool
    public var gridOpacity: Double
    public var cornerRadius: CGFloat
    public var background: AnyShapeStyle

    public init(
        lineColor: Color = .primary,
        lineWidth: CGFloat = 2,
        showFill: Bool = false,
        gridOpacity: Double = 0.12,
        cornerRadius: CGFloat = 12,
        background: some ShapeStyle = .thinMaterial
    ) {
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.showFill = showFill
        self.gridOpacity = gridOpacity
        self.cornerRadius = cornerRadius
        self.background = AnyShapeStyle(background)
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(lineColor)
        hasher.combine(lineWidth)
        hasher.combine(showFill)
        hasher.combine(gridOpacity)
        hasher.combine(cornerRadius)
    }
}

