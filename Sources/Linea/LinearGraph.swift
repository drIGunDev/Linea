//
//  LinearGraph.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI
import SwiftUI

/// A flexible, high-performance SwiftUI line chart that supports:
/// - one shared X axis,
/// - multiple Y axes (groups),
/// - per-series mapping to a specific Y axis,
/// - configurable pan/zoom modes,
/// - pluggable tick providers and formatters (via axes).
///
/// `SeriesId` is generic and must be `Hashable` (e.g. `enum`, `String`, `UUID`).
public struct LinearGraph<SeriesID: Hashable>: View {
    /// Current X axis state (scale, tick provider, formatter, grid flag, etc.).
    @State private var xAxis: XAxis

    /// Collection of Y axes and bindings (which series use which axis).
    /// `YAxes` also knows how to resolve auto-ranges per axis.
    @State private var yAxes: YAxes<SeriesID>

    /// Gesture state: last drag delta for incremental pan.
    @State private var lastDrag: CGSize = .zero
    /// Gesture state: last pinch scale for incremental zoom.
    @State private var lastPinch: CGFloat = 1

    /// The data series set: keyed by `SeriesId` for stable mapping to Y axes.
    private let series: [SeriesID: LinearSeries]

    /// Visual container style (background, corners, grid alpha, tick density defaults).
    private let style: LinearGraphStyle

    /// Gesture controller that applies pan/zoom to scales.
    private let controller = ZoomPanController()

    /// Which axes respond to drag (none/x/y/xy).
    private let panMode: ZoomAxis
    /// Which axes respond to pinch (none/x/y/xy).
    private let zoomMode: ZoomAxis

    /// If `true`, axis ranges are recomputed when `series` changes.
    private let autoRescaleOnSeriesChange: Bool

    /// Creates a chart.
    /// - Parameters:
    ///   - series: Series dictionary keyed by `SeriesId`.
    ///   - xAxis: X axis configuration (autoRange, ticks, formatter, etc.).
    ///   - yAxes: Y axes collection with bindings (each series → some Y axis).
    ///   - style: Container visuals and default axis presentation.
    ///   - panMode: Which axes react to drag gestures.
    ///   - zoomMode: Which axes react to pinch gestures.
    ///   - autoRescaleOnSeriesChange: Recompute axis ranges on data change.
    public init(
        series: [SeriesID: LinearSeries],
        xAxis: XAxis = .init(),
        yAxes: YAxes<SeriesID> = .init(),
        style: LinearGraphStyle = .init(),
        panMode: ZoomAxis = .xy,
        zoomMode: ZoomAxis = .xy,
        autoRescaleOnSeriesChange: Bool = true
    ) {
        self.series = series
        self.yAxes = yAxes
        self.style = style
        self.panMode = panMode
        self.zoomMode = zoomMode
        self.autoRescaleOnSeriesChange = autoRescaleOnSeriesChange

        // Compute initial X range (auto or fixed) and persist it as "original".
        xAxis.resolveRange(series: series, targetTicks: style.xTickTarget, resetOriginalRange: true)
        self._xAxis = State(initialValue: xAxis)

        // Compute initial Y ranges for all axes (auto per axis) and persist originals.
        yAxes.resolveRange(series: series, targetTicks: style.yTickTarget, resetOriginalRange: true)
        self._yAxes = State(initialValue: yAxes)
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Chart background (rounded, material/solid)
                RoundedRectangle(cornerRadius: style.cornerRadius).fill(style.background)

                // Grid lines (X + all enabled Y axes)
                drawGrid()

                // Data series (each mapped to its Y axis group)
                drawLines()

                // Tick labels (X + all enabled Y axes)
                drawAxesLabel()
            }
            .contentShape(Rectangle()) // enable gestures in empty areas

            // DRAG to pan (conditioned by panMode)
            .if(panMode != .none) { view in
                view.gesture(
                    DragGesture()
                        .onChanged { value in
                            let delta = CGSize(
                                width:  value.translation.width - lastDrag.width,
                                height: value.translation.height - lastDrag.height
                            )
                            // Apply pan to X and to each enabled Y axis according to mode.
                            yAxes.foreachAxis { yAxis in
                                controller.pan(x: xAxis.scale, y: yAxis.scale, drag: delta, in: geo.size, mode: panMode)
                            }
                            lastDrag = value.translation
                        }
                        .onEnded { _ in lastDrag = .zero }
                )
            }

            // PINCH to zoom (conditioned by zoomMode)
            .if(panMode != .none) { view in
                view.gesture(
                    MagnificationGesture()
                        .onChanged { scale in
                            let factor = scale / max(0.001, lastPinch)
                            let focus = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                            // Apply zoom to X and to each enabled Y axis according to mode.
                            yAxes.foreachAxis { yAxis in
                                controller.pinch(x: xAxis.scale, y: yAxis.scale, factor: factor, focus: focus, in: geo.size, mode: zoomMode)
                            }
                            lastPinch = scale
                        }
                        .onEnded { _ in lastPinch = 1 }
                )
            }

            // DOUBLE-TAP to reset both X and all Y axes to their original ranges
            .if(panMode != .none) { view in
                view.gesture(
                    TapGesture(count: 2)
                        .onEnded { _ in
                            xAxis.scale.reset()
                            yAxes.foreachAxis { yAxis in
                                yAxis.scale.reset()
                                // Nudge controller once to notify dependents if needed.
                                controller.pan(x: xAxis.scale, y: yAxis.scale, drag: .zero, in: geo.size, mode: .xy)
                            }
                        }
                )
            }

            // When series change, optionally recompute axis ranges (auto)
            .onChange(of: series, initial: true) { _, newValue in
                guard autoRescaleOnSeriesChange else { return }
                xAxis.resolveRange(series: newValue, targetTicks: style.xTickTarget)
                yAxes.resolveRange(series: newValue, targetTicks: style.yTickTarget)
            }
        }
    }
}

private extension LinearGraph {
    /// Builds grid paths for X and all enabled Y axes; clips to rounded rect.
    func drawGrid() -> some View {
        Canvas { ctx, size in
            guard style.gridEnabled else { return }
            var grid = Path()

            // Vertical lines (X)
            if xAxis.gridEnabled {
                let xt = xAxis.tickProvider.ticks(scale: xAxis.scale, target: style.xTickTarget)
                for t in xt {
                    let u = xAxis.scale.toUnit(t.value)
                    let X = size.width * CGFloat(u)
                    grid.move(to: .init(x: X, y: 0))
                    grid.addLine(to: .init(x: X, y: size.height))
                }
            }

            // Horizontal lines (per enabled Y axis)
            yAxes.foreachAxis { yAxis in
                guard yAxis.gridEnabled else { return }
                let yt = yAxis.tickProvider.ticks(scale: yAxis.scale, target: style.yTickTarget)
                for t in yt {
                    let u = yAxis.scale.toUnit(t.value)
                    let Y = size.height * (1 - CGFloat(u))
                    grid.move(to: .init(x: 0, y: Y))
                    grid.addLine(to: .init(x: size.width, y: Y))
                }
            }

            ctx.stroke(grid, with: .color(.secondary.opacity(style.gridOpacity)), lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }

    /// Draws tick labels for X and all enabled Y axes.
    func drawAxesLabel() -> some View {
        Canvas { ctx, size in
            guard style.gridEnabled else { return }

            // X labels
            if xAxis.gridEnabled {
                let xt = xAxis.tickProvider.ticks(scale: xAxis.scale, target: style.xTickTarget)
                for (index, t) in xt.enumerated() {
                    let u = xAxis.scale.toUnit(t.value)
                    let X = size.width * CGFloat(u)
                    let (textValue, font) = xAxis.formatter.string(for: t.value)
                    var text = Text(textValue).font(font)
                    if let color = xAxis.labelColor { text = text.foregroundColor(color) }
                    ctx.draw(
                        text,
                        at: CGPoint(x: X + (index == 0 ? 2 : -2), y: size.height - 2),
                        anchor: index == 0 ? .bottomLeading : .bottomTrailing
                    )
                }
            }

            // Y labels (left side by default; adjust anchor/pos in `YAxis`)
            yAxes.foreachAxis { yAxis in
                guard yAxis.gridEnabled else { return }
                let yt = yAxis.tickProvider.ticks(scale: yAxis.scale, target: style.yTickTarget)
                for t in yt {
                    let u = yAxis.scale.toUnit(t.value)
                    let Y = size.height * (1 - CGFloat(u))
                    let (textValue, font) = yAxis.formatter.string(for: t.value)
                    var text = Text(textValue).font(font)
                    if let color = yAxis.labelColor { text = text.foregroundColor(color) }
                    if (yAxis as? YAxis)?.side == .left {
                        ctx.draw(text, at: CGPoint(x: 4, y: Y + 2), anchor: .topLeading)
                    }
                    else {
                        ctx.draw(text, at: CGPoint(x: size.width - 4, y: Y + 2), anchor: .topTrailing)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }

    /// Draws all series, each mapped to the Y axis it’s bound to in `yAxes`.
    func drawLines() -> some View {
        Canvas { ctx, size in
            yAxes.bindings.forEach { binding in
                let yAxis = binding.axis
                for id in binding.seriesIds {
                    if let s = series[id] {
                        let sStyle = s.style
                        // Map data points to view space
                        let pts: [CGPoint] = s.points.map { p in
                            CGPoint(x: size.width * CGFloat(xAxis.scale.toUnit(p.x)),
                                    y: size.height * CGFloat(1 - yAxis.scale.toUnit(p.y)))
                        }
                        // Build path according to smoothing mode
                        let path = LinearSeries.path(sStyle: sStyle, pts: pts)

                        var stroke = StrokeStyle(lineWidth: sStyle.lineWidth, lineCap: .round, lineJoin: .round)
                        if let dash = sStyle.dash {
                            stroke = StrokeStyle(lineWidth: sStyle.lineWidth, lineCap: .round, lineJoin: .round, dash: dash)
                        }
                        ctx.stroke(path, with: .color(sStyle.color.opacity(sStyle.opacity)), style: stroke)

                        // Optional area fill under the curve
                        if let fillColor = sStyle.fill {
                            var fill = path
                            fill.addLine(to: CGPoint(x: size.width, y: size.height))
                            fill.addLine(to: CGPoint(x: 0, y: size.height))
                            fill.closeSubpath()
                            ctx.fill(fill, with: .color(fillColor.opacity(max(0, sStyle.opacity - 0.3))))
                        }
                    }
                }
            }
        }
    }
}

/// Tiny helper to conditionally apply view modifiers.
/// Keeps body readable when toggling gestures by mode.
fileprivate extension View {
    @ViewBuilder func `if`<V: View>(_ condition: Bool, _ transform: (Self) -> V) -> some View {
        if condition { transform(self) } else { self }
    }
}
