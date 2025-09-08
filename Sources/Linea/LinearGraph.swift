//
//  LinearGraph.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

public struct LinearGraph<SeriesId: Hashable>: View {
    @State private var xAxis: XAxis
    @State private var yAxes: YAxes<SeriesId>
    
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1
    
    private let series: [SeriesId: LinearSeries]
    private let style: LinearGraphStyle
    private let controller = ZoomPanController()
    
    private let panMode: ZoomAxis
    private let zoomMode: ZoomAxis
    
    private let autoRescaleOnSeriesChange: Bool
    
    public init(
        series: [SeriesId: LinearSeries],
        xAxis: XAxis = .init(),
        xAxes: YAxes<SeriesId> = .init(),
        style: LinearGraphStyle = .init(),
        panMode: ZoomAxis = .xy,
        zoomMode: ZoomAxis = .xy,
        autoRescaleOnSeriesChange: Bool = true
    ) {
        self.series = series
        self.yAxes = xAxes
        self.style = style
        self.panMode = panMode
        self.zoomMode = zoomMode
        self.autoRescaleOnSeriesChange = autoRescaleOnSeriesChange
        
        xAxis.setRange(series: series, targetTicks: style.xTickTarget)
        self._xAxis = State(initialValue: xAxis)
        
        yAxes.setRanges(series: series, targetTicks: style.yTickTarget)
        self._yAxes = State(initialValue: yAxes)
        
//        let yScale = LinearScale(min: yr.0, max: yr.1)
//        yScale.setOriginalRange(min: yr.0, max: yr.1); yScale.clampToOriginal = true
//        self._yAxes = State(initialValue: yScale)

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
                            yAxes.foreachScale { y in
                                controller.pan(x: xAxis.scale, y: y, drag: delta, in: geo.size, mode: panMode)
                            }
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
                            yAxes.foreachScale { y in
                                controller.pinch(x: xAxis.scale, y: y, factor: factor, focus: focus, in: geo.size, mode: zoomMode)
                            }
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
                            yAxes.foreachScale { y in
                                y.reset()
                                controller.pan(x: xAxis.scale, y: y, drag: .zero, in: geo.size, mode: .xy)
                            }
                        }
                )
            }
            .onChange(of: series, initial: true) { _, newValue in
                guard autoRescaleOnSeriesChange else { return }
                xAxis.setRange(series: newValue, targetTicks: style.xTickTarget)
                yAxes.setRanges(series: newValue, targetTicks: style.yTickTarget)
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
            yAxes.foreachAxis { y in
                let yt = y.tickProvider.ticks(scale: y.scale, target: style.yTickTarget)
                var grid = Path()
                for t in xt {
                    let u = xAxis.scale.toUnit(t.value)
                    let X = size.width * CGFloat(u)
                    grid.move(to: .init(x: X, y: 0))
                    grid.addLine(to: .init(x: X, y: size.height))
                }
                for t in yt {
                    let u = y.scale.toUnit(t.value)
                    let Y = size.height * (1 - CGFloat(u))
                    grid.move(to: .init(x: 0, y: Y))
                    grid.addLine(to: .init(x: size.width, y: Y))
                }
                ctx.stroke(grid, with: .color(.secondary.opacity(style.gridOpacity)), lineWidth: 0.5)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }
    
    func drawAxesLabel() -> some View {
        // Tick labels
        Canvas {
            ctx,
            size in
            
            let xt = xAxis.tickProvider.ticks(scale: xAxis.scale, target: style.xTickTarget)
            yAxes.foreachAxis { y in
                let yt = y.tickProvider.ticks(scale: y.scale, target: style.yTickTarget)
                
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
                    let u = y.scale.toUnit(t.value)
                    let Y = size.height * (1 - CGFloat(u))
                    let (textValue, font) = y.formatter.string(for: t.value)
                    let text = Text(textValue).font(font)
                    ctx.draw(text, at: CGPoint(x: 4, y: Y + 2), anchor: .topLeading)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }
    
    func drawLines() -> some View {
        // Series lines (per-series styles)
        Canvas { ctx, size in
            for s in series.values {
                yAxes.foreachAxis { y in
                    let sStyle = s.style 
                    
                    // inside the Canvas drawing of series in LinearGraph
                    let pts: [CGPoint] = s.points.map { p in
                        CGPoint(x: size.width * CGFloat(xAxis.scale.toUnit(p.x)),
                                y: size.height * CGFloat(1 - y.scale.toUnit(p.y)))
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
}

fileprivate extension View {
    @ViewBuilder func `if`<V: View>(_ condition: Bool, _ transform: (Self) -> V) -> some View {
        if condition { transform(self) } else { self }
    }
}
