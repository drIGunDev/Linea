//
//  Demo1.swift
//  Linea
//
//  Created by Igor Gun on 09.09.25.
//

import SwiftUI

struct Demo1: View {
    // Example data: simple sine wave
    let data = (0..<100).map { i in DataPoint(x: Double(i), y: sin(Double(i)/10)) }
    let _sin = "sin"
    var body: some View {
        LinearGraph(
            // Series are stored in a dictionary: key → LinearSeries
            series: [_sin: LinearSeries(points: data, style: .init(color: .blue))],
            // X axis: auto range
            xAxis: XAxis(),
            // Y axis: one shared axis for all series
            yAxes: YAxes.bind(axis: YAxis(), to: [_sin])
        )
        .frame(height: 240) // chart height
        .padding()
    }
}

struct Demo1_Previews: PreviewProvider {
    static var previews: some View {
        Demo1()
    }
}
