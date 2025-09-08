//
//  LinearGraph.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

public struct LinearGraph: View {
    @State private var xAxis: XAxis
//    private let yGroups: [String: YAxisGroup]
        @State private var y: LinearScale
    // Which group’s axis/grid to show as “primary” (e.g., selected series’ group)
//    @State private var primaryYGroupID: String
    
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1
    
    private let series: [LinearSeries]
    private let style: LinearGraphStyle
    private let controller = ZoomPanController()
    
    private let panMode: ZoomAxis
    private let zoomMode: ZoomAxis
    
    private let autoRescaleOnSeriesChange: Bool
    
    // Convenience init: auto-scale from data (no explicit scales required)
    public init(
        series: [LinearSeries],
        xAxis: XAxis = .init(),
//        yGroups: [YAxisGroup],
//        primaryYGroupID: String? = nil,      // optional initial primary
        style: LinearGraphStyle = .init(),
        panMode: ZoomAxis = .xy,
        zoomMode: ZoomAxis = .xy,
//        xAutoRange: AxisAutoRange = .padded(frac: 0.05, nice: true),
//        yAutoRange: AxisAutoRange = .padded(frac: 0.05, nice: true),
        autoRescaleOnSeriesChange: Bool = true
    ) {
        self.series = series
        self.style = style
        self.panMode = panMode
        self.zoomMode = zoomMode
//        self.xAuto = xAuto
//        self.yAuto = yAuto
        self.autoRescaleOnSeriesChange = autoRescaleOnSeriesChange
        
        let (xmin, xmax) = AutoRanger.dataBoundsX(series: series)
        xAxis.setMinMax(xmin, xmax)
        xAxis.setOriginalMinMax(xmin, xmax)
//        let xScale = LinearScale(min: xmin, max: xmax)
//        let xAxis = XAxis(scale: xScale, autoRange: xAutoRange)
        
//        let xr = resolveRange(range: xAxis.autoRange, raw: (xmin, xmax), targetTicks: style.xTickTarget)
//        xAxis.setMinMax(xr.0, xr.1)
//        xAxis.setOriginalMinMax(xr.0, xr.1)
        
        xAxis.resolveRange(maxMin: (xmin, xmax), targetTicks: style.xTickTarget)
        
//        xScale.setOriginalRange(min: xr.0, max: xr.1); xScale.clampToOriginal = true
        
        self._xAxis = State(initialValue: xAxis)
        
        let (ymin, ymax) = AutoRanger.dataBoundsY(series: series)
        var /*xr = (xmin, xmax), */yr = (ymin, ymax)
        switch xAxis.autoRange {
        case .none: break
        case let .fixed(min: min, max: max):
            yr = (min, max)
        case let .padded(frac: frac, nice: nice):
//            xr = AutoRanger.withPadding(min: xr.0, max: xr.1, frac: frac)
            yr = AutoRanger.withPadding(min: yr.0, max: yr.1, frac: frac)
            if nice {
//                xr = AutoRanger.nice(min: xr.0, max: xr.1)
                yr = AutoRanger.nice(min: yr.0, max: yr.1)
            }
        }
        
//        let xScale = LinearScale(min: xr.0, max: xr.1)
//        xScale.setOriginalRange(min: xr.0, max: xr.1); xScale.clampToOriginal = true
//        let xAxis: XAxis = .init(scale: xScale)
//        self._x = State(initialValue: xAxis)
        
        let yScale = LinearScale(min: yr.0, max: yr.1)
        yScale.setOriginalRange(min: yr.0, max: yr.1); yScale.clampToOriginal = true
        self._y = State(initialValue: yScale)

//        // compute scales from data
//        let (xmin, xmax) = AutoRanger.dataBoundsX(series: series)
//        let (ymin, ymax) = AutoRanger.dataBoundsY(series: series)
//        let xr = resolveRange(axis: xAuto, raw: (xmin, xmax), targetTicks: style.xTickTarget)
//        let yr = resolveRange(axis: yAuto, raw: (ymin, ymax), targetTicks: style.yTickTarget)
//        
//        let xs = LinearScale(min: xr.0, max: xr.1)
//        let ys = LinearScale(min: yr.0, max: yr.1)
//        xs.setOriginalRange(min: xr.0, max: xr.1); xs.clampToOriginal = true
//        ys.setOriginalRange(min: yr.0, max: yr.1); ys.clampToOriginal = true
//        self._x = State(initialValue: xs)
//        self._y = State(initialValue: ys)
    }
    
    // Full init: user supplies scales explicitly
    public init(
        series: [LinearSeries],
        xAxis: XAxis,
        yScale: LinearScale,
        style: LinearGraphStyle = .init(),
        panMode: ZoomAxis = .xy,
        zoomMode: ZoomAxis = .xy,
//        autoRange: AxisAutoRange = .none,
//        yAuto: AxisAutoRange = .none,
        autoRescaleOnSeriesChange: Bool = false
    ) {
        self.series = series
        self._xAxis = State(initialValue: xAxis)
        self._y = State(initialValue: yScale)
        self.style = style
        self.panMode = panMode
        self.zoomMode = zoomMode
//        self.autoRange = autoRange
//        self.xAuto = xAuto
//        self.yAuto = yAuto
        self.autoRescaleOnSeriesChange = autoRescaleOnSeriesChange
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: style.cornerRadius).fill(style.background)
                drawGrid()
                drawLines()
                drawAxesLabel()
            }
            .contentShape(Rectangle())
            .if(panMode != .none) { view in
                view.gesture(
                    DragGesture()
                        .onChanged { value in
                            let delta = CGSize(width: value.translation.width - lastDrag.width,
                                               height: value.translation.height - lastDrag.height)
                            controller.pan(x: xAxis.scale, y: y, drag: delta, in: geo.size, mode: panMode)
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
                            controller.pinch(x: xAxis.scale, y: y, factor: factor, focus: focus, in: geo.size, mode: zoomMode)
                            lastPinch = scale
                        }
                        .onEnded { _ in lastPinch = 1 }
                )
            }
            .if(panMode != .none) { view in
                view.gesture(
                    TapGesture(count: 2)
                        .onEnded { _ in
                            xAxis.scale.reset()
                            y.reset()
                            controller.pan(x: xAxis.scale, y: y, drag: .zero, in: geo.size, mode: .xy)
                        }
                )
            }
            .onChange(of: series, initial: true) { _, newValue in
                guard autoRescaleOnSeriesChange, case let .padded(frac, nice) = xAxis.autoRange else { return }
                let (xmin, xmax) = AutoRanger.dataBoundsX(series: newValue)
                let (ymin, ymax) = AutoRanger.dataBoundsY(series: newValue)
                var xr = AutoRanger.withPadding(min: xmin, max: xmax, frac: frac)
                var yr = AutoRanger.withPadding(min: ymin, max: ymax, frac: frac)
                if nice { xr = AutoRanger.nice(min: xr.0, max: xr.1); yr = AutoRanger.nice(min: yr.0, max: yr.1) }
                xAxis.scale.min = xr.0; xAxis.scale.max = xr.1; xAxis.scale.setOriginalRange(min: xr.0, max: xr.1)
                y.min = yr.0; y.max = yr.1; y.setOriginalRange(min: yr.0, max: yr.1)

//                guard autoRescaleOnSeriesChange else { return }
//                let (xmin, xmax) = AutoRanger.dataBoundsX(series: newValue)
//                let (ymin, ymax) = AutoRanger.dataBoundsY(series: newValue)
//                let xr = resolveRange(axis: xAuto, raw: (xmin, xmax), targetTicks: style.xTickTarget)
//                let yr = resolveRange(axis: yAuto, raw: (ymin, ymax), targetTicks: style.yTickTarget)
//                x.min = xr.0; x.max = xr.1; x.setOriginalRange(min: xr.0, max: xr.1)
//                y.min = yr.0; y.max = yr.1; y.setOriginalRange(min: yr.0, max: yr.1)
            }
        }
    }
}

private extension LinearGraph {
    
    func drawGrid() -> some View {
        // Grid
        Canvas {
            ctx,
            size in
            let xt = xAxis.tickProvider.ticks(scale: xAxis.scale, target: style.xTickTarget)
            let yt = style.yTickProvider.ticks(scale: y, target: style.yTickTarget)
            var grid = Path()
            for t in xt {
                let u = xAxis.scale.toUnit(t.value)
                let X = size.width * CGFloat(u)
                grid.move(to: .init(x: X, y: 0))
                grid.addLine(to: .init(x: X, y: size.height))
            }
            for t in yt {
                let u = y.toUnit(t.value)
                let Y = size.height * (1 - CGFloat(u))
                grid.move(to: .init(x: 0, y: Y))
                grid.addLine(to: .init(x: size.width, y: Y))
            }
            ctx.stroke(grid, with: .color(.secondary.opacity(style.gridOpacity)), lineWidth: 0.5)
        }
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }
    
    func drawAxesLabel() -> some View {
        // Tick labels
        Canvas {
            ctx,
            size in
            let xt = xAxis.tickProvider.ticks(scale: xAxis.scale, target: style.xTickTarget)
            let yt = style.yTickProvider.ticks(scale: y, target: style.yTickTarget)
            
            for (index, t) in xt.enumerated() {
                let u = xAxis.scale.toUnit(t.value)
                let X = size.width * CGFloat(u)
                let (textValue, font) = xAxis.formatter.string(for: t.value)
                let text = Text(textValue).font(font)
                ctx.draw(
                    text,
                    at: CGPoint(x: X + (index == 0 ? 2 : -2), y: size.height - 2),
                    anchor: index == 0 ? .bottomLeading : .bottomTrailing
                )
            }
            for t in yt {
                let u = y.toUnit(t.value)
                let Y = size.height * (1 - CGFloat(u))
                let (textValue, font) = style.yFormatter.string(for: t.value)
                let text = Text(textValue).font(font)
                ctx.draw(text, at: CGPoint(x: 4, y: Y + 2), anchor: .topLeading)
            }
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
                    CGPoint(x: size.width * CGFloat(xAxis.scale.toUnit(p.x)),
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

fileprivate func resolveRange(range: AxisAutoRange,
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

fileprivate extension View {
    @ViewBuilder func `if`<V: View>(_ condition: Bool, _ transform: (Self) -> V) -> some View {
        if condition { transform(self) } else { self }
    }
}
