//
//  NiceTickProvider.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import Foundation

public struct Tick {
    public let value: Double
    public let label: String
}

/// TickProvider returns tick positions for a given scale.
public protocol TickProvider: Sendable {
    func ticks(scale: any AxisScale, target: Int) -> [Tick]
}
