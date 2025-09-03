//
//  LinearGraph.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

public protocol AxisFormatter { func string(for value: Double) -> String }

public struct NumberAxisFormatter: AxisFormatter {
    public init(decimals: Int = 2, useSI: Bool = false) {
        self.decimals = decimals; self.useSI = useSI
    }
    public var decimals: Int
    public var useSI: Bool
    public func string(for value: Double) -> String {
        if useSI {
            let absv = abs(value)
            if absv >= 1_000_000 { return String(format: "%.*fM", decimals, value/1_000_000) }
            if absv >= 1_000 { return String(format: "%.*fk", decimals, value/1_000) }
        }
        return String(format: "%.*f", decimals, value)
    }
}

public struct LinearGraph: View {
    @State private var x: LinearScale
    @State private var y: LinearScale
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1

    private let series: [LinearSeries]
    private let style: LinearGraphStyle
    private let ticks = NiceTickProvider()
    private let controller = ZoomPanController()

    private let panMode: ZoomAxis
    private let zoomMode: ZoomAxis
    private let xFormatter: AxisFormatter
    private let yFormatter: AxisFormatter

    // Auto-range
    private let autoRange: AutoRangeMode
    private let autoRescaleOnSeriesChange: Bool

    // Convenience init: auto-scale from data (no explicit scales required)
    public init(
        series: [LinearSeries],
        style: LinearGraphStyle = .init(),
        panMode: ZoomAxis = .xy,
        zoomMode: ZoomAxis = .xy,
        xFormatter: AxisFormatter = NumberAxisFormatter(decimals: 0, useSI: true),
        yFormatter: AxisFormatter = NumberAxisFormatter(decimals: 2),
        autoRange: AutoRangeMode = .padded(x: 0.05, y: 0.05, nice: true),
        autoRescaleOnSeriesChange: Bool = true
    ) {
        self.series = series
        self.style = style
        self.panMode = panMode
        self.zoomMode = zoomMode
        self.xFormatter = xFormatter
        self.yFormatter = yFormatter
        self.autoRange = autoRange
        self.autoRescaleOnSeriesChange = autoRescaleOnSeriesChange

        // compute scales from data
        let (xmin, xmax) = AutoRanger.dataBoundsX(series: series)
        let (ymin, ymax) = AutoRanger.dataBoundsY(series: series)
        var xr = (xmin, xmax), yr = (ymin, ymax)
        switch autoRange {
        case .none: break
        case .tight:
            break
        case let .padded(x: px, y: py, nice: nice):
            xr = AutoRanger.withPadding(min: xr.0, max: xr.1, frac: px)
            yr = AutoRanger.withPadding(min: yr.0, max: yr.1, frac: py)
            if nice { xr = AutoRanger.nice(min: xr.0, max: xr.1); yr = AutoRanger.nice(min: yr.0, max: yr.1) }
        }
        let xScale = LinearScale(min: xr.0, max: xr.1)
        let yScale = LinearScale(min: yr.0, max: yr.1)
        xScale.setOriginalRange(min: xr.0, max: xr.1); xScale.clampToOriginal = true
        yScale.setOriginalRange(min: yr.0, max: yr.1); yScale.clampToOriginal = true
        self._x = State(initialValue: xScale)
        self._y = State(initialValue: yScale)
    }

    // Full init: user supplies scales explicitly
    public init(
        series: [LinearSeries],
        xScale: LinearScale,
        yScale: LinearScale,
        style: LinearGraphStyle = .init(),
        panMode: ZoomAxis = .xy,
        zoomMode: ZoomAxis = .xy,
        xFormatter: AxisFormatter = NumberAxisFormatter(decimals: 0, useSI: true),
        yFormatter: AxisFormatter = NumberAxisFormatter(decimals: 2),
        autoRange: AutoRangeMode = .none,
        autoRescaleOnSeriesChange: Bool = false
    ) {
        self.series = series
        self._x = State(initialValue: xScale)
        self._y = State(initialValue: yScale)
        self.style = style
        self.panMode = panMode
        self.zoomMode = zoomMode
        self.xFormatter = xFormatter
        self.yFormatter = yFormatter
        self.autoRange = autoRange
        self.autoRescaleOnSeriesChange = autoRescaleOnSeriesChange
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .fill(style.background)

                // Grid + tick labels
                Canvas { ctx, size in
                    let xt = ticks.ticks(scale: x, target: 6)
                    let yt = ticks.ticks(scale: y, target: 5)
                    var grid = Path()
                    for t in xt {
                        let u = x.toUnit(t.value)
                        let X = size.width * CGFloat(u)
                        grid.move(to: .init(x: X, y: 0))
                        grid.addLine(to: .init(x: X, y: size.height))
                        let text = Text(xFormatter.string(for: t.value)).font(.caption2)
                        ctx.draw(text, at: CGPoint(x: X + 2, y: size.height - 8), anchor: .bottomLeading)
                    }
                    for t in yt {
                        let u = y.toUnit(t.value)
                        let Y = size.height * (1 - CGFloat(u))
                        grid.move(to: .init(x: 0, y: Y))
                        grid.addLine(to: .init(x: size.width, y: Y))
                        let text = Text(yFormatter.string(for: t.value)).font(.caption2)
                        ctx.draw(text, at: CGPoint(x: 4, y: Y - 2), anchor: .topLeading)
                    }
                    ctx.stroke(grid, with: .color(.secondary.opacity(style.gridOpacity)), lineWidth: 0.5)
                }

                // Series lines (per-series styles)
                Canvas { ctx, size in
                    let palette: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .teal, .indigo]
                    for (idx, s) in series.enumerated() {
                        guard let first = s.points.first else { continue }
                        let sStyle = s.style ?? SeriesStyle(color: palette[idx % palette.count])

                        var path = Path()
                        @MainActor func map(_ p: DataPoint) -> CGPoint {
                            CGPoint(
                                x: size.width  * CGFloat(x.toUnit(p.x)),
                                y: size.height * CGFloat(1 - y.toUnit(p.y))
                            )
                        }
                        path.move(to: map(first))
                        for p in s.points.dropFirst() { path.addLine(to: map(p)) }

                        var stroke = StrokeStyle(lineWidth: sStyle.lineWidth, lineCap: .round, lineJoin: .round)
                        if let dash = sStyle.dash { stroke = StrokeStyle(lineWidth: sStyle.lineWidth, lineCap: .round, lineJoin: .round, dash: dash) }
                        ctx.stroke(path, with: .color(sStyle.color.opacity(sStyle.opacity)), style: stroke)

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
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let delta = CGSize(width: value.translation.width - lastDrag.width,
                                           height: value.translation.height - lastDrag.height)
                        controller.pan(x: x, y: y, drag: delta, in: geo.size, mode: panMode)
                        lastDrag = value.translation
                    }
                    .onEnded { _ in lastDrag = .zero }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        let factor = scale / max(0.001, lastPinch)
                        let focus = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                        controller.pinch(x: x, y: y, factor: factor, focus: focus, in: geo.size, mode: zoomMode)
                        lastPinch = scale
                    }
                    .onEnded { _ in lastPinch = 1 }
            )
            .gesture(
                TapGesture(count: 2)
                    .onEnded { _ in
                        x.reset()
                        y.reset()
                        controller.pan(x: x, y: y, drag: .zero, in: geo.size, mode: .xy)
                    }
            )
            .onChange(of: series, initial: true) { _, newValue in
                guard autoRescaleOnSeriesChange, case let .padded(px, py, nice) = autoRange else { return }
                let (xmin, xmax) = AutoRanger.dataBoundsX(series: newValue)
                let (ymin, ymax) = AutoRanger.dataBoundsY(series: newValue)
                var xr = AutoRanger.withPadding(min: xmin, max: xmax, frac: px)
                var yr = AutoRanger.withPadding(min: ymin, max: ymax, frac: py)
                if nice { xr = AutoRanger.nice(min: xr.0, max: xr.1); yr = AutoRanger.nice(min: yr.0, max: yr.1) }
                x.min = xr.0; x.max = xr.1; x.setOriginalRange(min: xr.0, max: xr.1)
                y.min = yr.0; y.max = yr.1; y.setOriginalRange(min: yr.0, max: yr.1)
            }
        }
    }
}
