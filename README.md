# Linea

**Linea** is a lightweight and fast SwiftUI line chart package.  
It supports multiple Y axes, per-series styling, zoom & pan gestures, and customizable ticks/labels.

---

## ⚙️ Features

- **Multiple Y axes** — bind different series to different vertical scales (left/right).  
- **Flexible ranges** — `tight`, `padded`, or `fixed`.  
- **Custom tick providers** — use built-in `NiceTickProvider` or `FixedCountTickProvider`, or define your own.  
- **Smoothing options** — Catmull-Rom, Monotone cubic, Kochanek–Bartels (TCB), Beta-spline, B-spline.  
- **Gestures** — pan & pinch zoom (can be disabled).  
- **Per-series styling** — color, width, opacity, dashed lines, optional fill.  

## Credits

Author: Igor Gun  
Assistant: ChatGPT (AI)  

This project is an experiment in human–AI co-development.

---

## 🚀 Installation

Add **Linea** to your project using **Swift Package Manager (SPM):**

1. In Xcode go to:  
   **File → Add Packages…**
2. Paste the repository URL: https://github.com/drIGunDev/Linea

3. Select the latest version and press **Add Package**.

Now you can `import Linea` in your Swift code.

---

## 🔥 Quick Start

### Example 1. Minimal chart (auto-scaling)
```swift
import SwiftUI
import Linea

struct Demo1: View {
    // Example data: simple sine wave
    let data = (0..<100).map { i in DataPoint(x: Double(i), y: sin(Double(i)/10)) }
    let _sin = "sin"
    var body: some View {
        LinearGraph(
            // Series are stored in a dictionary: key → LinearSeries
            series: [_sin: LinearSeries(points: data, style: .init(color: .blue))],
            // X axis: auto range
            xAxis: XAxis(),
            // Y axis: one shared axis for all series
            yAxes: YAxes.bind(axis: YAxis(), to: [_sin])
        )
        .frame(height: 240) // chart height
        .padding()
    }
}

struct Demo1_Previews: PreviewProvider {
    static var previews: some View {
        Demo1()
    }
}
```
👉 A simple blue sine wave chart with automatic scaling.

Example 2. Two series with separate Y axes
```swift
import SwiftUI
import Linea

struct Demo2: View {
    let temp = (0..<50).map { i in DataPoint(x: Double(i), y: Double.random(in: 15...30)) }
    let hum  = (0..<50).map { i in DataPoint(x: Double(i), y: Double.random(in: 40...70)) }

    var body: some View {
        let series: [String: LinearSeries] = [
            "temp": LinearSeries(points: temp, style: .init(color: .red, lineWidth: 2)),
            "hum":  LinearSeries(points: hum,  style: .init(color: .blue, lineWidth: 2))
        ]

        // Two Y axes: left for temperature, right for humidity
        let yAxes = YAxes
            .bind(axis: YAxis(side: .left,  labelColor: .red),  to: ["temp"])
            .bind(axis: YAxis(side: .right, labelColor: .blue), to: ["hum"])

        LinearGraph(series: series, yAxes: yAxes)
            .frame(height: 240)
            .padding()
    }
}

struct Demo2_Previews: PreviewProvider {
    static var previews: some View {
        Demo2()
    }
}
```
👉 Temperature (red, left axis) and humidity (blue, right axis).

Example 3. Fixed ranges and no gestures
```swift
import SwiftUI
import Linea

struct Demo3: View {
    let points = (0..<20).map { i in DataPoint(x: Double(i), y: Double(i * i)) }

    var body: some View {
        let series = ["quad": LinearSeries(points: points, style: .init(color: .green))]

        // Fixed ranges
        let xAxis = XAxis(autoRange: .fixed(min: 0, max: 20))
        let yAxis = YAxis(autoRange: .fixed(min: 0, max: 400))

        LinearGraph(
            series: series,
            xAxis: xAxis,
            yAxes: YAxes<String>.bind(axis: yAxis, to: ["quad"]),
            // Disable pan/zoom gestures
            panMode: .none,
            zoomMode: .none
        )
        .frame(height: 240)
        .padding()
    }
}

struct Demo3_Previews: PreviewProvider {
    static var previews: some View {
        Demo3()
    }
}
```
👉 A green quadratic curve with fixed bounds and no interaction.
