# Linea

Lightweight SwiftUI line chart with multi-series, grid, and smooth zoom & pan (iOS 16+).

## Installation (SPM)
1. Xcode → File → Add Package Dependencies…
2. Use repo URL

## Usage
```swift
import Linea

let x = LinearScale(min: 0, max: 300)
let y = LinearScale(min: -2, max: 2)

struct Demo: View {
    @State private var series: [LinearSeries] = [
        .init(points: (0..<300).map { i in .init(x: Double(i), y: sin(Double(i)/20)) }),
        .init(points: (0..<300).map { i in .init(x: Double(i), y: Double.random(in: -0.3...0.3)) })
    ]
    var body: some View {
        LinearGraph(series: series, xScale: x, yScale: y)
            .frame(height: 260)
            .padding()
    }
}
