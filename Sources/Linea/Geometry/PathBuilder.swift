//
//  PatchBuilder.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

@usableFromInline
struct PathBuilder {
    
    // MARK: - Linear
    @usableFromInline
    static func linePath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for p in points.dropFirst() { path.addLine(to: p) }
        return path
    }
}
