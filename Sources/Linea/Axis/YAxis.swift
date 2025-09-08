//
//  YAxis.swift
//  Linea
//
//  Created by Igor Gun on 08.09.25.
//

import SwiftUI

public final class YAxis: Axis {
    public enum YAxisSide { case left, right }
    
    public let side: YAxisSide
    
    public init(
        side: YAxisSide = .left,
        autoRange: AxisAutoRange = .padded(frac: 0.05, nice: true),
        tickProvider: any TickProvider = NiceTickProvider(),
        formatter: any AxisFormatter = NumberAxisFormatter(decimals: 2),
        labelingEnabled: Bool = true,
        labelColor: Color? = nil
    ) {
        self.side = side
        super.init(
            scale: .init(min: 0, max: 0),
            autoRange: autoRange,
            tickProvider: tickProvider,
            formatter: formatter
        )
    }
}
