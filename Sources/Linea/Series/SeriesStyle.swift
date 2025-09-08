//
//  SeriesStyle.swift
//  Linea
//
//  Created by Igor Gun on 03.09.25.
//

import SwiftUI

public struct SeriesStyle {
    public var color: Color
    public var lineWidth: CGFloat
    public var opacity: Double
    public var dash: [CGFloat]?             // e.g., [4,3]
    public var fill: Color?                 // optional area fill under the line
    public var smoothing: Smoothing

    public init(color: Color = .accentColor,
                lineWidth: CGFloat = 2,
                opacity: Double = 1,
                dash: [CGFloat]? = nil,
                fill: Color? = nil,
                smoothing: Smoothing = .none) {
        self.color = color
        self.lineWidth = lineWidth
        self.opacity = opacity
        self.dash = dash
        self.fill = fill
        self.smoothing = smoothing
    }
}
