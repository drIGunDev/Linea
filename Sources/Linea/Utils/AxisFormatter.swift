//
//  AxisFormatter.swift
//  Linea
//
//  Created by Igor Gun on 05.09.25.
//  Assistant: ChatGPT (AI)

import SwiftUI

/// AxisFormatter renders tick values to strings (and optional font).
public protocol AxisFormatter: Sendable {
    func string(for value: Double) -> (String, Font)
}

/// NumberAxisFormatter supports fixed decimals and optional SI prefixes.
public struct NumberAxisFormatter: AxisFormatter {
    public init(decimals: Int = 2, useSI: Bool = false) {
        self.decimals = decimals; self.useSI = useSI
    }
    public var decimals: Int
    public var useSI: Bool
    public func string(for value: Double) -> (String, Font) {
        let font = Font.system(size: 8)
        if useSI {
            let absv = abs(value)
            if absv >= 1_000_000 { return (String(format: "%.*fM", decimals, value/1_000_000), font) }
            if absv >= 1_000 { return (String(format: "%.*fk", decimals, value/1_000), font) }
        }
        return (String(format: "%.*f", decimals, value), font)
    }
}
