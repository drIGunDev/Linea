//
//  DemoTinyGraph.swift
//  Linea
//
//  Created by Igor Gun on 04.09.25.
//

import SwiftUI

struct DemoTinyGraph: View {
    enum Ids: Int {
        case one
    }
    @State private var series: [Ids : LinearSeries] = [
        .one : .init(
            points: (0..<200).map { i in .init(x: Double(i), y: (Double.random(in: -8...8) + 70))
            },
            style: .init(
                color: .red,
                lineWidth: 1,
                opacity: 0.7,
                smoothing: .none
            ))
    ]
        
    var body: some View {
        VStack() {
            HStack(alignment: .top) {
                LinearGraph(
                    series: series,
                    xAxis: XAxis(
                        autoRange: .none,//padded(frac: 0.01, nice: true),
                        tickProvider: NiceTickProvider(),
                    ),
                    yAxes: YAxes(
                        bindings: [
                            AxisBinding(
                                axes: YAxis(
                                    autoRange: .fixed(min: 0, max: 150),
                                    tickProvider: NiceTickProvider(),
                                    gridEnabled: true,
                                ),
                                seriesIds:[.one],
                            ),
                        ],
                    ),
                    style: .init(
                        gridOpacity: 0.9,
                        cornerRadius: 0,
                        background: .gray.opacity(0.2),
                        xTickTarget: 3,
                        yTickTarget: 3
                    ),
                    panMode: .none,
                    zoomMode: .none,
                    autoRescaleOnSeriesChange: true
                )
                .frame(width: 200, height: 100)
                Spacer()
            }
            Spacer()
        }
    }
}

struct DemoTinyGraph_Previews: PreviewProvider {
    static var previews: some View {
        DemoTinyGraph()
            .preferredColorScheme(.dark)
    }
}
