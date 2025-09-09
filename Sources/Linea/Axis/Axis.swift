//
//  Axis.swift
//  Linea
//
//  Created by Igor Gun on 08.09.25.
//  Assistant: ChatGPT (AI)

import SwiftUI

public class Axis {
    public let scale: LinearScale
    public let autoRange: AxisAutoRange
    public let tickProvider: any TickProvider
    public let formatter: any AxisFormatter
    public let gridEnabled: Bool
    public let labelColor: Color?

    public init(
        scale: LinearScale,
        autoRange: AxisAutoRange = .padded(frac: 0.05, nice: true),
        tickProvider: any TickProvider = NiceTickProvider(),
        formatter: any AxisFormatter = NumberAxisFormatter(decimals: 2),
        gridEnabled: Bool = true,
        labelColor: Color? = nil
    ) {
        self.scale = scale
        self.autoRange = autoRange
        self.tickProvider = tickProvider
        self.formatter = formatter
        self.gridEnabled = gridEnabled
        self.labelColor = labelColor
    }
    
    func resolveRange(
        maxMin: (Double, Double),
        targetTicks: Int,
        resetOriginalRange: Bool = false
    ) {
        let minMax = Self.resolveRange(range: autoRange, raw: maxMin, targetTicks: targetTicks)
        scale.min = minMax.0
        scale.max = minMax.1
        if resetOriginalRange {
            scale.setOriginalRange(min: minMax.0, max: minMax.1)
        }
    }
    
    private class func resolveRange(range: AxisAutoRange,
                                    raw: (Double, Double),
                                    targetTicks: Int) -> (Double, Double) {
        var (a,b) = raw
        switch range {
        case .none:
            return (a,b)
        case let .fixed(min, max):
            return (min, max)
        case let .padded(frac, nice):
            (a,b) = AutoRanger.withPadding(min: a, max: b, frac: frac)
            if nice {
                (a,b) = AutoRanger.nice(min: a, max: b, targetTicks: targetTicks)
            }
            return (a,b)
        }
    }
}

