//
//  Demo.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

struct Demo: View {
    
    @State private var series: [LinearSeries] = [
        .init(points: (0..<300).map { i in .init(x: Double(i), y: sin(Double(i)/20)) },
              style: .init(color: .blue, lineWidth: 2)),
        .init(points: (0..<300).map { i in .init(x: Double(i), y: Double.random(in: -0.3...0.3)) },
              style: .init(color: .red, lineWidth: 1, opacity: 0.7, dash: [4,3]))
    ]

    var body: some View {
        LinearGraph(
            series: series,
            style: .init(gridOpacity: 0.9, cornerRadius: 10, background: .gray.opacity(0.2)),
            panMode: .x,
            zoomMode: .x,
            autoRange: .padded(x: 0.05, y: 0.1, nice: true),
            autoRescaleOnSeriesChange: true
        )
        .frame(height: 260)
        .padding()
    }
}

struct Demo_Previews: PreviewProvider {
    static var previews: some View {
        Demo()
            .preferredColorScheme(.dark)
    }
}
