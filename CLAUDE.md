# CLAUDE.md — Linea

## Build & Test

```bash
swift build          # build the library
swift test           # run tests (Tests/LineaTests/)
```

SPM package: iOS 17+, macOS 13+, Swift 6.1. No external dependencies.

## Architecture

**Linea** is a SwiftUI line chart library with pan/zoom, multiple Y axes, and pluggable spline smoothing.

### Core types

- `LinearGraph<SeriesID>` — main SwiftUI view. Generic over `SeriesID: Hashable`. Owns `@State` for `XAxis`, `YAxes`, gesture state. Uses `Canvas` for grid, labels, and line rendering.
- `LinearSeries` — raw `[DataPoint]` + `SeriesStyle` (color, width, smoothing, fill, dash).
- `Axis` (class) → `XAxis`, `YAxis` — axis config: scale, autoRange, tickProvider, formatter, grid toggle.
- `YAxes<SeriesID>` — manages multiple Y axes via `[AxisBinding<SeriesID>]`; each binding maps a `YAxis` to a set of series IDs.
- `AxisScale` (protocol) / `LinearScale` (class) — value ↔ unit `[0,1]` mapping, pan/zoom/reset, optional clamping to original range.
- `TickProvider` (protocol) → `NiceTickProvider`, `FixedCountTickProvider` — generate tick positions for a given scale.
- `AxisFormatter` (protocol) — formats tick values to `(String, Font)`.
- `ZoomPanController` — translates drag/pinch gestures into `AxisScale` pan/zoom calls.
- `PathBuilder` + spline extensions — builds `Path` from mapped `[CGPoint]`. Smoothing modes: `none`, `catmullRom`, `monotoneCubic`, `tcb` (Kochanek-Bartels), `betaSpline`, `bSpline`.

### Data flow

1. User provides `[SeriesID: LinearSeries]`, axis config, and style to `LinearGraph`.
2. On init (and on series change if `autoRescaleOnSeriesChange`), axes auto-resolve ranges via `AutoRanger`.
3. `Canvas` renders: grid lines → data paths (via `PathBuilder`) → tick labels.
4. Drag/pinch gestures → `ZoomPanController` → mutates `LinearScale.min/max` → SwiftUI re-renders.
5. Double-tap resets all scales to original ranges.

### Directory layout

```
Sources/Linea/
├── LinearGraph.swift        # main view
├── LinearGraphStyle.swift   # visual container style
├── Series/                  # LinearSeries, SeriesStyle, spline dispatch
├── Axis/                    # Axis, XAxis, YAxis, YAxes, AxisBinding, AxisAutorange
├── Scales/                  # AxisScale protocol, LinearScale
├── Ticks/                   # TickProvider protocol, NiceTickProvider, FixedCountTickProvider
├── Geometry/                # PathBuilder + Splines/ (CatmullRom, MonotoneCubic, TCB, BetaSpline, BSpline)
├── Interaction/             # ZoomPanController, ZoomAxis enum
├── Utils/                   # DataPoint, Array+Stats, AxisFormatter
└── Demo/                    # Demo views (Demo1–3)
```

## Conventions

- **Swift 6.1 strict concurrency** — `Sendable` where required (e.g. `TickProvider`). `Axis` and `LinearScale` are reference types (`class`) for shared mutation via gestures.
- **Protocol-driven extensibility** — custom axes, tick providers, formatters, and scales plug in via protocols (`AxisScale`, `TickProvider`, `AxisFormatter`).
- **Canvas rendering** — all drawing uses SwiftUI `Canvas` (not `Shape` or `GeometryReader` subviews) for performance.
- **No external dependencies**.
- Language in code comments and docs: **English**.
