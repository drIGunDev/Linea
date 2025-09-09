//
//  ZoomPanController.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//

import SwiftUI

public enum ZoomAxis { case none, x, y, xy }

/// ZoomPanController translates drag/pinch gestures to scale updates.
/// - `pan(x:y:drag:in:mode:)` applies delta in unit space → value space.
/// - `pinch(x:y:factor:focus:in:mode:)` zooms around a focus point.
public final class ZoomPanController {
    public init() {}

    public func pan(x: any AxisScale, y: (any AxisScale)?, drag: CGSize, in size: CGSize, mode: ZoomAxis = .xy) {
        if size.width > 1, mode != .y {
            let dxu = Double(drag.width / size.width)
            let dxv = -(x.max - x.min) * dxu
            x.pan(by: dxv)
        }
        if let y, size.height > 1, mode != .x {
            let dyu = Double(drag.height / size.height)
            let dyv =  (y.max - y.min) * dyu
            y.pan(by: dyv)
        }
    }

    public func pinch(x: any AxisScale, y: (any AxisScale)?, factor: CGFloat, focus: CGPoint, in size: CGSize, mode: ZoomAxis = .xy) {
        let fx = Double(focus.x / max(size.width, 1))
        let fy = Double(1 - focus.y / max(size.height, 1))
        if mode != .y {
            let vx = x.fromUnit(fx)
            x.zoom(by: factor, around: vx)
        }
        if let y, mode != .x {
            let vy = y.fromUnit(fy)
            y.zoom(by: factor, around: vy)
        }
        x.clampSpan(minSpan: 1e-9); y?.clampSpan(minSpan: 1e-9)
    }
}
