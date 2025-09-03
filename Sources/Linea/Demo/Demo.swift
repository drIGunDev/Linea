//
//  Demo.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

nonisolated(unsafe) let x = LinearScale(min: 0, max: 300)
nonisolated(unsafe) let y = LinearScale(min: -2, max: 2)

struct Demo: View {
    @State private var series: [LinearSeries] = [
        .init(points: (0..<300).map { i in .init(x: Double(i), y: sin(Double(i)/20)) }),
        .init(points: (0..<300).map { i in .init(x: Double(i), y: Double.random(in: -0.3...0.3)) })
    ]
    var body: some View {
        LinearGraph(series: series, xScale: x, yScale: y, style: .init(lineColor: .blue))
            .frame(height: 260)
            .padding()
    }
}

struct Demo_Previews: PreviewProvider {
    static var previews: some View {
        Demo()
    }
}
