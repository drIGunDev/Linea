//
//  Demo.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

struct Demo: View {
    
    @State private var series: [LinearSeries] = [
        .init(
            points: (0..<200).map { i in .init(x: Double(i), y: (Double(sin(Double(i)/20))) + Double.random(in: -0.8...0.8))
            },
            style: .init(
                color: .blue,
                lineWidth: 2
            )),
        .init(
            points: (0..<200).map { i in .init(x: Double(i), y: Double.random(in: -0.8...0.8))
            },
            style: .init(
                color: .red,
                lineWidth: 1,
                opacity: 0.7,
                dash: [4,3],
                smoothing: .none
            ))
    ]
    
    @State private var smoothingIndex: Int = 0
    
    var body: some View {
        VStack {
            HStack {
                Picker("Smoothing", selection: $smoothingIndex) {
                    Text("None").tag(0)
                    Text("Monotone").tag(1)
                    Text("Catmull-Rom").tag(2)
                    Text("Beta spline").tag(3)
                    Text("TCB").tag(4)
                    Text("B Spline").tag(5)
                }
                .pickerStyle(.segmented)
            }.font(.footnote)
            
            let smooth: Smoothing = {
                switch smoothingIndex {
                case 1: return .monotoneCubic
                case 2: return .catmullRom(0.9)
                case 3: return .betaSpline(bias: 0.0, tension: 10, samplesPerSegment: 200)
                case 4: return .tcb()
                case 5: return .bSpline(degree: 100,
                                        knots: nil,
                                        samplesPerSpan: 5,
                                        parameterization: .openUniform)
                default: return .none
                }
            }()
            
            LinearGraph(
                series: series.map { s in
                    var s = s; s.style = (s.style ?? SeriesStyle()); s.style?.smoothing = smooth; return s
                },
                style: .init(gridOpacity: 0.9, cornerRadius: 10, background: .gray.opacity(0.2)),
                panMode: .x,
                zoomMode: .x,
                autoRange: .padded(x: 0.05, y: 0.3, nice: true),
                autoRescaleOnSeriesChange: true
            )
            .frame(height: 260)
            .padding()
        }
    }
}

struct Demo_Previews: PreviewProvider {
    static var previews: some View {
        Demo()
            .preferredColorScheme(.dark)
    }
}
