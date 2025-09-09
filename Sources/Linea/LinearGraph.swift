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
        yAxes: YAxes<SeriesId> = .init(),
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
        
        xAxis.resolveRange(series: series, targetTicks: style.xTickTarget, resetOriginalRange: true)
        self._xAxis = State(initialValue: xAxis)
        
        yAxes.resolveRange(series: series, targetTicks: style.yTickTarget, resetOriginalRange: true)
        self._yAxes = State(initialValue: yAxes)
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
                            yAxes.foreachAxis { yAxis in
                                controller.pan(x: xAxis.scale, y: yAxis.scale, drag: delta, in: geo.size, mode: panMode)
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
                            yAxes.foreachAxis { yAxis in
                                controller.pinch(x: xAxis.scale, y: yAxis.scale, factor: factor, focus: focus, in: geo.size, mode: zoomMode)
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
                            yAxes.foreachAxis { yAxis in
                                yAxis.scale.reset()
                                controller.pan(x: xAxis.scale, y: yAxis.scale, drag: .zero, in: geo.size, mode: .xy)
                            }
                        }
                )
            }
            .onChange(of: series, initial: true) { _, newValue in
                guard autoRescaleOnSeriesChange else { return }
                xAxis.resolveRange(series: newValue, targetTicks: style.xTickTarget)
                yAxes.resolveRange(series: newValue, targetTicks: style.yTickTarget)
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
            
            guard style.gridEnabled else { return }
            
            var grid = Path()
            
            if xAxis.gridEnabled {
                let xt = xAxis.tickProvider.ticks(scale: xAxis.scale, target: style.xTickTarget)
                for t in xt {
                    let u = xAxis.scale.toUnit(t.value)
                    let X = size.width * CGFloat(u)
                    grid.move(to: .init(x: X, y: 0))
                    grid.addLine(to: .init(x: X, y: size.height))
                }
            }

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
    
    func drawAxesLabel() -> some View {
        // Tick labels
        Canvas {
            ctx,
            size in
            
            guard style.gridEnabled else { return }
            
            if xAxis.gridEnabled {
                let xt = xAxis.tickProvider.ticks(scale: xAxis.scale, target: style.xTickTarget)
                for (index, t) in xt.enumerated() {
                    let u = xAxis.scale.toUnit(t.value)
                    let X = size.width * CGFloat(u)
                    let (textValue, font) = xAxis.formatter.string(for: t.value)
                    var text = Text(textValue).font(font)
                    if let color = xAxis.labelColor {
                        text = text.foregroundColor(color)
                    }
                    ctx.draw(
                        text,
                        at: CGPoint(x: X + (index == 0 ? 2 : -2), y: size.height - 2),
                        anchor: index == 0 ? .bottomLeading : .bottomTrailing
                    )
                }
            }
            
            yAxes.foreachAxis { yAxis in
                guard yAxis.gridEnabled else { return }
                
                let yt = yAxis.tickProvider.ticks(scale: yAxis.scale, target: style.yTickTarget)
                for t in yt {
                    let u = yAxis.scale.toUnit(t.value)
                    let Y = size.height * (1 - CGFloat(u))
                    let (textValue, font) = yAxis.formatter.string(for: t.value)
                    var text = Text(textValue).font(font)
                    if let color = yAxis.labelColor {
                        text = text.foregroundColor(color)
                    }
                    ctx.draw(text, at: CGPoint(x: 4, y: Y + 2), anchor: .topLeading)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: style.cornerRadius))
    }
    
    func drawLines() -> some View {
        // Series lines (per-series styles)
        Canvas { ctx, size in
            yAxes.bindings.forEach { binding in
                let yAxis = binding.axis
                for id in binding.seriesIds {
                    
                    if let s = series[id] {
                        
                        let sStyle = s.style
                        
                        let pts: [CGPoint] = s.points.map { p in
                            CGPoint(x: size.width * CGFloat(xAxis.scale.toUnit(p.x)),
                                    y: size.height * CGFloat(1 - yAxis.scale.toUnit(p.y)))
                        }
                        
                        let path = LinearSeries.path(sStyle: sStyle, pts: pts)
                        
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
}

fileprivate extension View {
    @ViewBuilder func `if`<V: View>(_ condition: Bool, _ transform: (Self) -> V) -> some View {
        if condition { transform(self) } else { self }
    }
}
