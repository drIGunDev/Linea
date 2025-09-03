# Linea

Lightweight SwiftUI line chart with multi-series, grid, and smooth zoom & pan (iOS 16+).

## Installation (SPM)
1. Xcode → File → Add Package Dependencies…
2. Use repo URL

## Usage
```swift
import Linea

import SwiftUI

struct Demo: View {
    
    @State private var series: [LinearSeries] = [
        .init(points: (0..<300).map { i in .init(x: Double(i), y: sin(Double(i)/20)) },
              style: .init(color: .blue, lineWidth: 2)),
        .init(points: (0..<300).map { i in .init(x: Double(i), y: Double.random(in: -0.3...0.3)) },
              style: .init(color: .red, lineWidth: 1, opacity: 0.7, dash: [4,3]))
    ]

    var body: some View {
        LinearGraph(
            series: series,
            panMode: .x,                       // pan along X only
            zoomMode: .xy,                     // pinch zoom both axes
            autoRange: .padded(x: 0.05, y: 0.1, nice: true),
            autoRescaleOnSeriesChange: true    // re-fit when data changes
        )
        .frame(height: 260)
        .padding()
    }
}

struct Demo_Previews: PreviewProvider {
    static var previews: some View {
        Demo()
    }
}
