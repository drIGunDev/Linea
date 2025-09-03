// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

public struct LinearGraph: View {
    @State private var x: LinearScale
    @State private var y: LinearScale
    
    private let series: [LinearSeries]
    private let style: LinearGraphStyle
    private let ticks = NiceTickProvider()
    private let controller = ZoomPanController()
    
    @State private var lastDrag: CGSize = .zero
    @State private var lastPinch: CGFloat = 1
    
    public init(series: [LinearSeries], xScale: LinearScale, yScale: LinearScale, style: LinearGraphStyle = .init()) {
        self.series = series
        self.x = xScale
        self.y = yScale
        self.style = style
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
                        // X labels (bottom)
                        let text = Text(t.label).font(.caption2)
                        ctx.draw(text, at: CGPoint(x: X + 2, y: size.height - 8), anchor: .bottomLeading)
                    }
                    for t in yt {
                        let u = y.toUnit(t.value)
                        let Y = size.height * (1 - CGFloat(u))
                        grid.move(to: .init(x: 0, y: Y))
                        grid.addLine(to: .init(x: size.width, y: Y))
                        // Y labels (left)
                        let text = Text(t.label).font(.caption2)
                        ctx.draw(text, at: CGPoint(x: 4, y: Y - 2), anchor: .topLeading)
                    }
                    ctx.stroke(grid, with: .color(.secondary.opacity(style.gridOpacity)), lineWidth: 0.5)
                }
                
                // Series lines
                Canvas { ctx, size in
                    @MainActor func map(_ p: DataPoint) -> CGPoint {
                        CGPoint(
                            x: size.width  * CGFloat(x.toUnit(p.x)),
                            y: size.height * CGFloat(1 - y.toUnit(p.y))
                        )
                    }
                    for s in series {
                        guard let first = s.points.first else { continue }
                        var path = Path()
                        
                        path.move(to: map(first))
                        for p in s.points.dropFirst() { path.addLine(to: map(p)) }
                        ctx.stroke(path, with: .color(.primary), lineWidth: style.lineWidth)
                        
                        if style.showFill {
                            var fill = path
                            fill.addLine(to: CGPoint(x: size.width, y: size.height))
                            fill.addLine(to: CGPoint(x: 0, y: size.height))
                            fill.closeSubpath()
                            ctx.fill(fill, with: .color(.primary.opacity(0.12)))
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
                        controller.pan(x: x, y: y, drag: delta, in: geo.size, mode: .xy)
                        lastDrag = value.translation
                    }
                    .onEnded { _ in lastDrag = .zero }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        let factor = scale / max(0.001, lastPinch)
                        let focus = CGPoint(x: geo.size.width/2, y: geo.size.height/2)
                        controller.pinch(x: x, y: y, factor: factor, focus: focus, in: geo.size, mode: .xy)
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
        }
    }
}
