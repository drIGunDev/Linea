//
//  Demo.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//  Assistant: ChatGPT (AI)

import SwiftUI

struct Demo: View {
    enum Ids: Int {
        case sin, sinRandom, random
    }
    
    @State private var series: [Ids : LinearSeries] = [
        .sin : .init(
            points: (0..<200).map { i in .init(x: Double(i), y: (10*sin(Double(i)/20)))  },
            style: .init(
                color: .green,
                lineWidth: 2
            )
        ),
        .sinRandom : .init(
            points: (0..<200).map { i in .init(x: Double(i), y: 10*(sin(Double(i)/20) + Double.random(in: -0.8...0.8))) },
            style: .init(
                color: .blue,
                lineWidth: 1
            )
        ),
        .random : .init(
            points: (0..<200).map { i in .init(x: Double(i), y: Double.random(in: -0.8...0.8))},
            style: .init(
                color: .red,
                lineWidth: 1,
                opacity: 0.7,
                dash: [4,3],
                smoothing: .none
            )
        )
    ]
    
    @State private var smoothingIndex: Int = 0
    
    var body: some View {
        VStack {
            HStack {
                Picker("Smoothing", selection: $smoothingIndex) {
                    Text("None").tag(0)
                    Text("Monotone").tag(1)
                    Text("Catmull").tag(2)
                    Text("Beta").tag(3)
                    Text("TCB").tag(4)
                    Text("B Spline").tag(5)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }.font(.footnote)
            
            let smooth: Smoothing = {
                switch smoothingIndex {
                case 1: return .monotoneCubic
                case 2: return .catmullRom(0.9)
                case 3: return .betaSpline(bias: 0.0, tension: 10, samplesPerSegment: 200)
                case 4: return .tcb(tension: 0.1, bias: 0.5, continuity: 0)
                case 5: return .bSpline(degree: 10,
                                        knots: nil,
                                        samplesPerSpan: 5,
                                        parameterization: .openUniform)
                default: return .none
                }
            }()
            
            
            LinearGraph(
                series: setSmoothing(series: series, smooth: smooth),
                xAxis: XAxis(
                    autoRange: .padded(frac: 0.01, nice: true),
                    tickProvider: NiceTickProvider()
                ),
                yAxes: YAxes(
                    bindings: [
                        AxisBinding(
                            axis: YAxis(
                                autoRange: .padded(frac: 0.01, nice: true),
                                tickProvider: NiceTickProvider(),
                                gridEnabled: true
                            ),
                            seriesIds:[.sinRandom, .sin]
                        ),
                        AxisBinding(
                            axis: YAxis(
                                gridEnabled: false,
                            ),
                            seriesIds:[.random]
                        )
                    ],
                ),
                style: .init(
                    gridOpacity: 0.9,
                    cornerRadius: 5,
                    background: .gray.opacity(0.2),
                    xTickTarget: 3,
                    yTickTarget: 3
                ),
                panMode: .x,
                zoomMode: .x,
                autoRescaleOnSeriesChange: true
            )
            .frame(height: 260)
            .padding()
        }
    }
    
    private func setSmoothing(series: [Ids : LinearSeries], smooth: Smoothing) -> [Ids : LinearSeries] {
        series
            .map { id, s in
                var s = s
                s.style.smoothing = smooth
                return (id, s)
            }
            .reduce([Ids: LinearSeries]())  { memo, tuple in
                var m = memo
                let (id, series) = tuple
                m.updateValue(series, forKey: id)
                return m
            }
    }
}

struct Demo_Previews: PreviewProvider {
    static var previews: some View {
        Demo()
    }
}
