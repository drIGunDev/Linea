//
//  YAxisGroup.swift
//  Linea
//
//  Created by Igor Gun on 06.09.25.
//

import SwiftUI

public enum YAxisSide { case left, right }

@Observable public final class YAxisGroup: Identifiable, Hashable {
    public let id: String
    public let side: YAxisSide
    public let scale: LinearScale
    public let tickProvider: any TickProvider
    public let formatter: any AxisFormatter

    public init(id: String,
                side: YAxisSide = .left,
                scale: LinearScale,
                tickProvider: any TickProvider = NiceTickProvider(),
                formatter: any AxisFormatter = NumberAxisFormatter(decimals: 2)
    ) {
        self.id = id; self.side = side; self.scale = scale
        self.tickProvider = tickProvider; self.formatter = formatter
    }
    
    public static func == (lhs: YAxisGroup, rhs: YAxisGroup) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
