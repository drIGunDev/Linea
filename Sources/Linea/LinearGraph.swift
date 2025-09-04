//
//  LinearGraph.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

public struct LinearGraph: View {
    @State private var x: LinearScale
    @State private var y: LinearScale
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1
    
    private let series: [LinearSeries]
    private let style: LinearGraphStyle
    private let controller = ZoomPanController()
    
    private let panMode: ZoomAxis
    private let zoomMode: ZoomAxis
    
    // Auto-range
    private let autoRange: AutoRangeMode
    private let autoRescaleOnSeriesChange: Bool
    
    // Convenience init: auto-scale from data (no explicit scales required)
    public init(
        series: [LinearSeries],
        style: LinearGraphStyle = .init(),
        panMode: ZoomAxis = .xy,
        zoomMode: ZoomAxis = .xy,
        autoRange: AutoRangeMode = .padded(x: 0.05, y: 0.05, nice: true),
        autoRescaleOnSeriesChange: Bool = true
    ) {
        self.series = series
        self.style = style
        self.panMode = panMode
        self.zoomMode = zoomMode
        self.autoRange = autoRange
        self.autoRescaleOnSeriesChange = autoRescaleOnSeriesChange
        
        // compute scales from data
        let (xmin, xmax) = AutoRanger.dataBoundsX(series: series)
        let (ymin, ymax) = AutoRanger.dataBoundsY(series: series)
        var xr = (xmin, xmax), yr = (ymin, ymax)
        switch autoRange {
        case .none: break
        case .tight: break
        case let .fixed(yMin: min, yMax: max):
            yr = (min, max)
        case let .padded(x: px, y: py, nice: nice):
            xr = AutoRanger.withPadding(min: xr.0, max: xr.1, frac: px)
            yr = AutoRanger.withPadding(min: yr.0, max: yr.1, frac: py)
            if nice {
                xr = AutoRanger.nice(min: xr.0, max: xr.1)
                yr = AutoRanger.nice(min: yr.0, max: yr.1)
            }
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
        autoRange: AutoRangeMode = .none,
        autoRescaleOnSeriesChange: Bool = false
    ) {
        self.series = series
        self._x = State(initialValue: xScale)
        self._y = State(initialValue: yScale)
        self.style = style
        self.panMode = panMode
        self.zoomMode = zoomMode
        self.autoRange = autoRange
        self.autoRescaleOnSeriesChange = autoRescaleOnSeriesChange
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: style.cornerRadius).fill(style.background)
                drawLines()
                drawGrid()
            }
            .contentShape(Rectangle())
            .if(panMode != .none) { view in
                view.gesture(
                    DragGesture()
                        .onChanged { value in
                            let delta = CGSize(width: value.translation.width - lastDrag.width,
                                               height: value.translation.height - lastDrag.height)
                            controller.pan(x: x, y: y, drag: delta, in: geo.size, mode: panMode)
                            lastDrag = value.translation
                        }
                        .onEnded { _ in lastDrag = .zero }
                )
            }
            .if(panMode != .none) { view in
                view.gesture(
                    MagnificationGesture()
                        .onChanged { scale in
                            let factor = scale / max(0.001, lastPinch)
                            let focus = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                            controller.pinch(x: x, y: y, factor: factor, focus: focus, in: geo.size, mode: zoomMode)
                            lastPinch = scale
                        }
                        .onEnded { _ in lastPinch = 1 }
                )
            }
            .if(panMode != .none) { view in
                view.gesture(
                    TapGesture(count: 2)
                        .onEnded { _ in
                            x.reset()
                            y.reset()
                            controller.pan(x: x, y: y, drag: .zero, in: geo.size, mode: .xy)
                        }
                )
            }
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

private extension LinearGraph {
    
    func drawGrid() -> some View {
        // Grid + tick labels
        Canvas {
            ctx,
            size in
            let xt = style.xTickProvider.ticks(scale: x, target: style.xTickTarget)
            let yt = style.yTickProvider.ticks(scale: y, target: style.yTickTarget)
            var grid = Path()
            for (index, t) in xt.enumerated() {
                let u = x.toUnit(t.value)
                let X = size.width * CGFloat(u)
                grid.move(to: .init(x: X, y: 0))
                grid.addLine(to: .init(x: X, y: size.height))
                let text = Text(style.xFormatter.string(for: t.value)).font(.caption2)
                ctx.draw(
                    text,
                    at: CGPoint(x: X + (index == 0 ? 2 : -2), y: size.height - 2),
                    anchor: index == 0 ? .bottomLeading : .bottomTrailing
                )
            }
            for t in yt {
                let u = y.toUnit(t.value)
                let Y = size.height * (1 - CGFloat(u))
                grid.move(to: .init(x: 0, y: Y))
                grid.addLine(to: .init(x: size.width, y: Y))
                let text = Text(style.yFormatter.string(for: t.value)).font(.caption2)
                ctx.draw(text, at: CGPoint(x: 4, y: Y - 2), anchor: .topLeading)
            }
            ctx.stroke(grid, with: .color(.secondary.opacity(style.gridOpacity)), lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }
    
    func drawLines() -> some View {
        // Series lines (per-series styles)
        Canvas { ctx, size in
            let palette: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .teal, .indigo]
            for (idx, s) in series.enumerated() {
                let sStyle = s.style ?? SeriesStyle(color: palette[idx % palette.count])
                
                // inside the Canvas drawing of series in LinearGraph
                let pts: [CGPoint] = s.points.map { p in
                    CGPoint(x: size.width * CGFloat(x.toUnit(p.x)),
                            y: size.height * CGFloat(1 - y.toUnit(p.y)))
                }
                
                let path: Path
                switch sStyle.smoothing {
                case .none:
                    path = PathBuilder.linePath(points: pts)
                case let .catmullRom(tension):
                    path = PathBuilder.catmullRomUniform(points: pts, tension: tension)
                case .monotoneCubic:
                    // ensure xs are strictly increasing
                    let xs = pts.map { $0.x }, ys = pts.map { $0.y }
                    path = PathBuilder.monotoneCubic(xs: xs, ys: ys)
                case let .tcb(t, b, c):
                    path = PathBuilder.kochanekBartels(points: pts, tension: t, bias: b, continuity: c)
                case let .betaSpline(bias, tension, samples):
                    path = PathBuilder.betaSplineSampled(points: pts, bias: bias, tension: tension, samplesPerSegment: samples)
                case .bSpline(let degree, let knots, let samples, let param):
                    path = PathBuilder.bSplinePath(control: pts,
                                                   degree: max(1, degree),
                                                   knots: knots,
                                                   samplesPerSpan: samples,
                                                   parameterization: param)
                }
                
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
}

private extension View {
    @ViewBuilder func `if`<V: View>(_ condition: Bool, _ transform: (Self) -> V) -> some View {
        if condition { transform(self) } else { self }
    }
}
