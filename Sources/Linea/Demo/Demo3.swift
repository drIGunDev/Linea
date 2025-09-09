//
//  Demo3.swift
//  Linea
//
//  Created by Igor Gun on 09.09.25.
//

import SwiftUI

struct Demo3: View {
    let points = (0..<20).map { i in DataPoint(x: Double(i), y: Double(i * i)) }

    var body: some View {
        let series = ["quad": LinearSeries(points: points, style: .init(color: .green))]

        // Fixed ranges
        let xAxis = XAxis(autoRange: .fixed(min: 0, max: 20))
        let yAxis = YAxis(autoRange: .fixed(min: 0, max: 400))

        LinearGraph(
            series: series,
            xAxis: xAxis,
            yAxes: YAxes<String>.bind(axis: yAxis, to: ["quad"]),
            // Disable pan/zoom gestures
            panMode: .none,
            zoomMode: .none
        )
        .frame(height: 240)
        .padding()
    }
}

struct Demo3_Previews: PreviewProvider {
    static var previews: some View {
        Demo3()
    }
}

