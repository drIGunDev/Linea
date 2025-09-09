//
//  Array+Stats.swift
//  Linea
//
//  Created by Igor Gun on 02.09.25.
//  Assistant: ChatGPT (AI)

import Foundation

extension Array where Element == Double {
    func minMax() -> (Double, Double) {
        guard let f = self.first else { return (0, 1) }
        var mn = f, mx = f
        for v in self.dropFirst() { mn = Swift.min(mn, v); mx = Swift.max(mx, v) }
        if mn == mx { mx = mn + 1 }
        return (mn, mx)
    }
}
