//
//  Demo2.swift
//  Linea
//
//  Created by Igor Gun on 09.09.25.
//

import SwiftUI

struct Demo2: View {
    let temp = (0..<50).map { i in DataPoint(x: Double(i), y: Double.random(in: 15...30)) }
    let hum  = (0..<50).map { i in DataPoint(x: Double(i), y: Double.random(in: 40...70)) }

    var body: some View {
        let series: [String: LinearSeries] = [
            "temp": LinearSeries(points: temp, style: .init(color: .red, lineWidth: 2)),
            "hum":  LinearSeries(points: hum,  style: .init(color: .blue, lineWidth: 2))
        ]

        // Two Y axes: left for temperature, right for humidity
        let yAxes = YAxes
            .bind(axis: YAxis(side: .left,  labelColor: .red),  to: ["temp"])
            .bind(axis: YAxis(side: .right, labelColor: .blue), to: ["hum"])

        LinearGraph(series: series, yAxes: yAxes)
            .frame(height: 240)
            .padding()
    }
}

struct Demo2_Previews: PreviewProvider {
    static var previews: some View {
        Demo2()
    }
}
