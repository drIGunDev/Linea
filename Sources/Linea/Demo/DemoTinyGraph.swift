//
//  DemoTinyGraph.swift
//  Linea
//
//  Created by Igor Gun on 04.09.25.
//

//import SwiftUI
//
//struct DemoTinyGraph: View {
//    
//    @State private var series: [LinearSeries] = [
//        .init(
//            points: (0..<200).map { i in .init(x: Double(i), y: (Double.random(in: -8...8) + 70))
//            },
//            style: .init(
//                color: .red,
//                lineWidth: 1,
//                opacity: 0.7,
//                smoothing: .none
//            ))
//    ]
//        
//    var body: some View {
//        VStack() {
//            HStack(alignment: .top) {
//                LinearGraph(
//                    series: series,
//                    style: .init(
//                        gridOpacity: 0.9,
//                        cornerRadius: 0,
//                        background: .gray.opacity(0.2),
//                        xTickTarget: 3,
//                        yTickTarget: 3,
//                        xTickProvider: FixedCountTickProvider(),
//                        yTickProvider: FixedCountTickProvider()
//                    ),
//                    panMode: .none,
//                    zoomMode: .none,
//                    xAuto: .none,//.fixed(min: 0, max: 200),
//                    yAuto: .fixed(min: 0, max: 150),
//                    autoRescaleOnSeriesChange: true
//                )
//                .frame(width: 200, height: 100)
//                //            .padding()
//                Spacer()
//            }
//            Spacer()
//        }
//    }
//}
//
//struct DemoTinyGraph_Previews: PreviewProvider {
//    static var previews: some View {
//        DemoTinyGraph()
//            .preferredColorScheme(.dark)
//    }
//}
