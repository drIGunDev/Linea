# Linea — SwiftUI Line Chart Library

## Overview

Linea is a lightweight, zero-dependency SwiftUI line chart library. It renders via `Canvas` for high performance, supports multiple Y axes, pan/zoom gestures, and pluggable spline smoothing.

**Platforms:** iOS 17+, macOS 14+
**Swift:** 6.1 (strict concurrency)
**Dependencies:** None

## Installation (SPM)

```swift
.package(url: "https://github.com/<owner>/Linea.git", from: "1.0.0")
```

Add `"Linea"` to your target's dependencies.

## Quick Start

```swift
import SwiftUI
import Linea

struct ChartView: View {
    let data = (0..<100).map { i in
        DataPoint(x: Double(i), y: sin(Double(i) / 10))
    }

    var body: some View {
        LinearGraph(
            series: ["sin": LinearSeries(points: data, style: .init(color: .blue))],
            xAxis: XAxis(),
            yAxes: YAxes.bind(axis: YAxis(), to: ["sin"])
        )
        .frame(height: 240)
        .padding()
    }
}
```

This gives you a fully interactive chart with auto-scaled axes, pan, zoom, and double-tap reset out of the box.

## Data Model

### DataPoint

```swift
DataPoint(x: Double, y: Double)
```

### LinearSeries

Holds an array of `DataPoint` and a `SeriesStyle`. Tracks changes via an internal version counter for efficient equality checks.

```swift
var series = LinearSeries(
    points: [DataPoint(x: 0, y: 1), DataPoint(x: 1, y: 3)],
    style: SeriesStyle(color: .red, lineWidth: 2)
)
series.clean() // removes all points
```

### SeriesStyle

| Parameter   | Type        | Default        | Description                      |
|-------------|-------------|----------------|----------------------------------|
| `color`     | `Color`     | `.accentColor` | Line color                       |
| `lineWidth` | `CGFloat`   | `2`            | Stroke width                     |
| `opacity`   | `Double`    | `1`            | Line opacity                     |
| `dash`      | `[CGFloat]?`| `nil`          | Dash pattern, e.g. `[5, 3]`     |
| `fill`      | `Color?`    | `nil`          | Area fill below the line         |
| `smoothing` | `Smoothing` | `.none`        | Spline interpolation mode        |

## Axes

### XAxis / YAxis

Both inherit from `Axis`. Create with sensible defaults or customize:

```swift
let xAxis = XAxis(
    autoRange: .padded(frac: 0.05, nice: true),
    tickProvider: NiceTickProvider(),
    formatter: NumberAxisFormatter(decimals: 1),
    gridEnabled: true,
    labelColor: .gray
)

let yAxis = YAxis(
    side: .left,    // .left or .right
    autoRange: .padded(frac: 0.05, nice: true)
)
```

### AxisAutoRange

Controls how axis bounds are determined:

| Case                          | Behavior                                          |
|-------------------------------|---------------------------------------------------|
| `.none`                       | Use raw data bounds, no transformation             |
| `.fixed(min:max:)`            | Hardcoded bounds, ignores data                     |
| `.padded(frac:nice:)`         | Auto-range from data + fractional padding + optional "nice" rounding |

### Multiple Y Axes

Bind different series to different Y axes using the fluent API:

```swift
let yAxes = YAxes
    .bind(axis: YAxis(side: .left,  labelColor: .red),  to: ["temperature"])
    .bind(axis: YAxis(side: .right, labelColor: .blue), to: ["humidity"])
```

If a binding has an empty `seriesIds` array, all series are used (same as default single-axis behavior).

## Smoothing

Six interpolation modes via the `Smoothing` enum:

| Mode                        | Best for                                    |
|-----------------------------|---------------------------------------------|
| `.none`                     | Raw data, performance-critical charts        |
| `.catmullRom(tension)`      | General smooth curves. Tension 0…1 (default 0.85) |
| `.monotoneCubic`            | Data where Y monotonicity must be preserved  |
| `.tcb(tension:bias:continuity:)` | Fine-grained control over curve shape   |
| `.betaSpline(bias:tension:samplesPerSegment:)` | Approximating spline (doesn't pass through points) |
| `.bSpline(degree:knots:samplesPerSpan:parameterization:)` | B-spline with open-uniform or chord-length knots |

**Recommendation:** Start with `.catmullRom()` for most use cases. Use `.monotoneCubic` for financial/scientific data where overshooting is unacceptable.

## Styling

`LinearGraphStyle` controls the chart container appearance:

```swift
LinearGraph(
    series: series,
    style: LinearGraphStyle(
        gridEnabled: true,
        gridColor: .gray,
        gridOpacity: 0.3,
        cornerRadius: 10,
        background: .ultraThinMaterial,
        xTickTarget: 6,    // target number of X axis ticks
        yTickTarget: 5     // target number of Y axis ticks
    )
)
```

## Interaction

### Pan & Zoom

Controlled via `panMode` and `zoomMode` parameters on `LinearGraph`:

| ZoomAxis | Behavior                |
|----------|-------------------------|
| `.none`  | Gestures disabled        |
| `.x`     | Horizontal only          |
| `.y`     | Vertical only            |
| `.xy`    | Both axes (default)      |

```swift
LinearGraph(
    series: series,
    panMode: .x,      // drag pans X axis only
    zoomMode: .x      // pinch zooms X axis only
)
```

**Double-tap** resets all axes to their original ranges.

### Clamping

`LinearScale.clampToOriginal` (default `true`) prevents panning/zooming beyond the original data range. Set to `false` on the scale for unrestricted navigation.

## Formatters

### NumberAxisFormatter

```swift
NumberAxisFormatter(decimals: 2)              // "3.14"
NumberAxisFormatter(decimals: 1, useSI: true) // "2.5k", "3.5M"
```

### Custom Formatter

Use `AnyAxisFormatter` for fully custom tick labels:

```swift
let dateFormatter = AnyAxisFormatter { value in
    let date = Date(timeIntervalSince1970: value)
    return (date.formatted(.dateTime.hour().minute()), .system(size: 8))
}

let xAxis = XAxis(formatter: dateFormatter)
```

## Common Patterns

### Dashboard with Fixed Ranges (No Gestures)

```swift
LinearGraph(
    series: ["data": LinearSeries(points: points, style: .init(color: .green))],
    xAxis: XAxis(autoRange: .fixed(min: 0, max: 100)),
    yAxes: YAxes.bind(
        axis: YAxis(autoRange: .fixed(min: 0, max: 500)),
        to: ["data"]
    ),
    panMode: .none,
    zoomMode: .none
)
```

### Dynamic / Real-Time Data

Set `autoRescaleOnSeriesChange: true` (default) so axes automatically adjust when data updates:

```swift
@State private var series: [String: LinearSeries] = [:]

LinearGraph(
    series: series,
    autoRescaleOnSeriesChange: true
)
```

Mutating `series["key"]?.points` triggers a version bump and re-render.

### Dashed Line with Area Fill

```swift
SeriesStyle(
    color: .orange,
    lineWidth: 1.5,
    dash: [6, 4],
    fill: .orange.opacity(0.15),
    smoothing: .catmullRom()
)
```

## Best Practices

- **SeriesID type:** Use a `String` enum for type safety. Any `Hashable` type works, but enums prevent typos.
- **Performance:** Linea renders via `Canvas`, so thousands of points are fine. For 10k+ points, consider downsampling.
- **Multiple axes:** Bind each series to exactly one Y axis. An empty `seriesIds` binding acts as a catch-all for unbound series.
- **Tick targets:** These are hints, not exact counts. `NiceTickProvider` picks the closest "nice" step (1, 2, or 5 × 10^n).
- **Clamping:** Keep `clampToOriginal = true` for user-facing charts to prevent disorientation. Disable for exploratory/research tools.
- **Smoothing cost:** `.none` and `.monotoneCubic` are cheapest. `.bSpline` and `.betaSpline` do per-segment sampling — increase `samplesPerSegment` only if curves look jagged.

## Architecture Reference

```
Sources/Linea/
├── LinearGraph.swift        # Main SwiftUI view (Canvas-based)
├── LinearGraphStyle.swift   # Container visual style
├── Series/                  # LinearSeries, SeriesStyle, smoothing dispatch
├── Axis/                    # Axis, XAxis, YAxis, YAxes, AxisBinding, AutoRanger
├── Scales/                  # AxisScale protocol, LinearScale
├── Ticks/                   # TickProvider protocol, NiceTickProvider, FixedCountTickProvider
├── Geometry/                # PathBuilder + Splines/ (6 algorithms)
├── Interaction/             # ZoomPanController, ZoomAxis
└── Utils/                   # DataPoint, Array+Stats, AxisFormatter
```

**Data flow:** Series dict + axis config → AutoRanger resolves bounds → Canvas renders grid + paths + labels → Gestures mutate LinearScale → SwiftUI re-renders.
