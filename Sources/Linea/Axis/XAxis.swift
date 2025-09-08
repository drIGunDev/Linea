//
//  XAxis.swift
//  Linea
//
//  Created by Igor Gun on 06.09.25.
//

import SwiftUI

public final class XAxis: Axis {
    public convenience init(
        autoRange: AxisAutoRange = .padded(frac: 0.05, nice: true),
        tickProvider: any TickProvider = NiceTickProvider(),
        formatter: any AxisFormatter = NumberAxisFormatter(decimals: 2),
        labelingEnabled: Bool = true,
        labelColor: Color? = nil
    ) {
        self.init(
            scale: .init(min: 0, max: 0),
            autoRange: autoRange,
            tickProvider: tickProvider,
            formatter: formatter
        )
    }
    
    public func setRange<SeriesId: Hashable>(series: [SeriesId: LinearSeries], targetTicks: Int) {
        let (min, max) = AutoRanger.dataBoundsX(series: series)
        resolveRange(maxMin: (min, max), targetTicks: targetTicks)
    }
}
