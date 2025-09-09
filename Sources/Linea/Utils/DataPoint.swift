//
//  DataPoint.swift
//  Linea
//
//  Created by Igor Gun on 05.09.25.
//  Assistant: ChatGPT (AI)

import Foundation

public struct DataPoint: Sendable, Hashable {
    public var x: Double
    public var y: Double
    public init(x: Double, y: Double) { self.x = x; self.y = y }
}
