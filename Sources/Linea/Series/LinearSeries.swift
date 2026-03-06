//
//  LinearSeries.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//  Assistant: ChatGPT (AI)

import Foundation
import os

/// Global atomic counter so every `LinearSeries` instance gets a unique initial version.
private let _nextVersion: OSAllocatedUnfairLock<UInt64> = .init(initialState: 0)
private func nextVersion() -> UInt64 {
    _nextVersion.withLock { val in
        val &+= 1
        return val
    }
}

/// LinearSeries holds raw points and per-series visual style (color, width, smoothing, fill).
/// Use `LinearSeries.path(sStyle:pts:)` to construct the curve for Canvas drawing.
public struct LinearSeries: Equatable {
    public var points: [DataPoint] { didSet { version &+= 1 } }
    public var style: SeriesStyle   { didSet { version &+= 1 } }

    /// Monotonically increasing version tag; compared in O(1) instead of diffing all points.
    private var version: UInt64

    public init(points: [DataPoint],
                style: SeriesStyle) {
        self.points = points
        self.style = style
        self.version = nextVersion()
    }

    public mutating func clean() {
        points.removeAll() // triggers didSet → version increments
    }

    public static func == (lhs: LinearSeries, rhs: LinearSeries) -> Bool {
        lhs.version == rhs.version
    }
}
